import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/gamification_service.dart';
import '../../services/activity_service.dart';
import '../../theme/app_theme.dart';

class PomodoroTab extends StatefulWidget {
  final TaskModel? focusedTask;
  final VoidCallback? onClearFocus;

  const PomodoroTab({super.key, this.focusedTask, this.onClearFocus});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<PomodoroTab> with WidgetsBindingObserver {
  Timer? _timer;
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  bool _isWorkTime = true;
  int _sessionCount = 0;
  int _totalWorkSecondsThisSession = 0; // Track work seconds for the focused task
  DateTime? _lastPausedTime;

  final _workDurationController = TextEditingController(text: "25");
  final _breakDurationController = TextEditingController(text: "5");
  final _longBreakDurationController = TextEditingController(text: "15");
  final _sessionsBeforeLongBreakController = TextEditingController(text: "4");

  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  final GamificationService _gamService = GamificationService();
  final ActivityService _activityService = ActivityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushFocusedTime(); // Save any remaining tracked time before disposing
    _timer?.cancel();
    _workDurationController.dispose();
    _breakDurationController.dispose();
    _longBreakDurationController.dispose();
    _sessionsBeforeLongBreakController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isRunning) {
        _lastPausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isRunning && _lastPausedTime != null) {
        final now = DateTime.now();
        final diffInSeconds = now.difference(_lastPausedTime!).inSeconds;
        setState(() {
          _timeLeft -= diffInSeconds;
          if (_isWorkTime) {
            _totalWorkSecondsThisSession += diffInSeconds;
          }
          if (_timeLeft < 0) _timeLeft = 0;
        });
        _lastPausedTime = null;
        
        // If the timer theoretically finished while in the background
        if (_timeLeft == 0) {
           // We will let the normal Timer tick handle the completion 
           // on the next immediate tick.
        }
      }
    }
  }

  /// Saves accumulated work seconds to the focused task in Firestore
  Future<void> _flushFocusedTime() async {
    if (widget.focusedTask != null && _totalWorkSecondsThisSession > 0) {
      final userId = context.read<AuthService>().user?.uid;
      if (userId != null) {
        final minutesToAdd = _totalWorkSecondsThisSession ~/ 60;
        if (minutesToAdd > 0) {
          final currentMinutes = widget.focusedTask!.pomodoroMinutes;
          await _taskService.updateTask(userId, widget.focusedTask!.id, {
            'pomodoroMinutes': currentMinutes + minutesToAdd,
          });
          _totalWorkSecondsThisSession = _totalWorkSecondsThisSession % 60; // Keep remainder
        }
      }
    }
  }

  void _updateSettings() {
    if (!_isRunning) {
      setState(() {
        if (_isWorkTime) {
          _timeLeft = (int.tryParse(_workDurationController.text) ?? 25) * 60;
        } else {
          final isLongBreak = _sessionCount > 0 &&
              _sessionCount % (int.tryParse(_sessionsBeforeLongBreakController.text) ?? 4) == 0;
          _timeLeft = isLongBreak
              ? (int.tryParse(_longBreakDurationController.text) ?? 15) * 60
              : (int.tryParse(_breakDurationController.text) ?? 5) * 60;
        }
      });
    }
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          // Track work seconds for the focused task
          if (_isWorkTime && widget.focusedTask != null) {
            _totalWorkSecondsThisSession++;
            // Flush every 60 seconds to avoid data loss
            if (_totalWorkSecondsThisSession > 0 && _totalWorkSecondsThisSession % 60 == 0) {
              _flushFocusedTime();
            }
          }
        } else {
          _timer?.cancel();
          _isRunning = false;

          // Flush tracked time at the end of each work session
          if (_isWorkTime) {
            _flushFocusedTime();
          }

          final userId = context.read<AuthService>().user?.uid;

          if (_isWorkTime) {
            _sessionCount++;
            final isLongBreak = _sessionCount % (int.tryParse(_sessionsBeforeLongBreakController.text) ?? 4) == 0;
            
            if (isLongBreak) {
              _timeLeft = (int.tryParse(_longBreakDurationController.text) ?? 15) * 60;
            } else {
              _timeLeft = (int.tryParse(_breakDurationController.text) ?? 5) * 60;
            }
            _isWorkTime = false;

            // Notify break start
            _notificationService.showPomodoroNotification(
              title: isLongBreak ? 'Long Break Started' : 'Short Break Started',
              body: 'Great job! Take a well-deserved break.',
            );

            // Grant XP and log activity for the completed work session
            if (userId != null) {
              final minutesWorked = int.tryParse(_workDurationController.text) ?? 25;
              _activityService.logActivity(userId, pomodoroMinutes: minutesWorked);
              _gamService.addXp(userId, minutesWorked);
              
              // Check badges asynchronously without blocking UI
              _taskService.getTasks(userId).first.then((allTasks) {
                final totalCompleted = allTasks.where((t) => t.completed).length;
                final totalPomodoro = allTasks.fold<int>(0, (sum, t) => sum + t.pomodoroMinutes);
                _gamService.checkAndAwardBadges(
                  userId,
                  totalCompleted: totalCompleted,
                  totalPomodoroMinutes: totalPomodoro,
                  actionTime: DateTime.now(),
                  consecutivePomodoros: _sessionCount,
                ).then((earned) {
                  if (earned.isNotEmpty && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🏆 You earned ${earned.length} new badge${earned.length > 1 ? 's' : ''}!'),
                        backgroundColor: AppTheme.secondary,
                      ),
                    );
                  }
                });
              });
            }
          } else {
            _timeLeft = (int.tryParse(_workDurationController.text) ?? 25) * 60;
            _isWorkTime = true;

            // Notify work start
            _notificationService.showPomodoroNotification(
              title: 'Break Over',
              body: 'Ready to dive back in? Start the timer!',
            );
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _flushFocusedTime(); // Save progress on pause
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _flushFocusedTime(); // Save any tracked time before resetting
    setState(() {
      _isRunning = false;
      _isWorkTime = true;
      _sessionCount = 0;
      _timeLeft = (int.tryParse(_workDurationController.text) ?? 25) * 60;
    });
  }

  String get _timerDisplay {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _modeText {
    if (_isWorkTime) return 'WORK';
    final isLongBreak = _sessionCount > 0 &&
        _sessionCount % (int.tryParse(_sessionsBeforeLongBreakController.text) ?? 4) == 0;
    return isLongBreak ? 'LONG BREAK' : 'BREAK';
  }

  Color get _modeColor {
    if (_isWorkTime) return AppTheme.primaryLight;
    final isLongBreak = _sessionCount > 0 &&
        _sessionCount % (int.tryParse(_sessionsBeforeLongBreakController.text) ?? 4) == 0;
    return isLongBreak ? AppTheme.accentLight : AppTheme.secondaryLight;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Focused Task Banner
              if (widget.focusedTask != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.25), AppTheme.secondary.withOpacity(0.15)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppTheme.accentLight, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FOCUSING ON', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.grayLight)),
                            const SizedBox(height: 2),
                            Text(
                              widget.focusedTask!.text,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (widget.onClearFocus != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.grayLight, size: 18),
                          onPressed: widget.onClearFocus,
                          tooltip: 'Stop focusing',
                        ),
                    ],
                  ),
                ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.timer, color: AppTheme.secondaryLight, size: 28),
                          SizedBox(width: 12),
                          Text('Pomodoro Timer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      Text(
                        _modeText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: _modeColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        _timerDisplay,
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Courier',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isRunning ? null : _startTimer,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isRunning ? _pauseTimer : null,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: (_isRunning || _timeLeft != (int.tryParse(_workDurationController.text) ?? 25) * 60)
                                ? _resetTimer
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSettingItem('Work (min)', _workDurationController),
                          _buildSettingItem('Break (min)', _breakDurationController),
                          _buildSettingItem('Long Break', _longBreakDurationController),
                          _buildSettingItem('Sessions', _sessionsBeforeLongBreakController),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, TextEditingController controller) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.grayLight, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => _updateSettings(),
          ),
        ],
      ),
    );
  }
}
