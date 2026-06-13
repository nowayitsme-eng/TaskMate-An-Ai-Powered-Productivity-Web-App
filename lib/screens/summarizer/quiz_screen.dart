import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/activity_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int _selectedOption = -1;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == widget.questions[_currentIndex]['correctIndex']) {
        _score++;
      }
    });
  }

  void _next() async {
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedOption = -1;
    });

    if (_currentIndex >= widget.questions.length) {
      final userId = context.read<AuthService>().user?.uid;
      if (userId != null) {
        // Treat completing a quiz as 1 task activity and grant 50 XP
        await ActivityService().logActivity(userId, tasksCompleted: 1);
        await GamificationService().addXp(userId, 50);
      }
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedOption = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Interactive Quiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: _currentIndex >= widget.questions.length
            ? _buildScoreScreen()
            : _buildQuestionScreen(),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    final q = widget.questions[_currentIndex];
    final options = (q['options'] as List<dynamic>).cast<String>();
    final correctIndex = q['correctIndex'] as int;
    final total = widget.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of $total',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            Text(
              'Score: $_score',
              style: const TextStyle(
                color: AppTheme.accentLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Question card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            q['question'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Options
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(options.length, (i) {
                Color? borderColor;
                Color? bgColor;
                if (_answered) {
                  if (i == correctIndex) {
                    borderColor = AppTheme.secondary;
                    bgColor = AppTheme.secondary.withValues(alpha: 0.15);
                  } else if (i == _selectedOption && i != correctIndex) {
                    borderColor = AppTheme.danger;
                    bgColor = AppTheme.danger.withValues(alpha: 0.12);
                  } else {
                    borderColor = AppTheme.border;
                    bgColor = AppTheme.surface;
                  }
                } else {
                  borderColor = AppTheme.border;
                  bgColor = AppTheme.surface;
                }

                return GestureDetector(
                  onTap: () => _selectOption(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor!, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _answered && i == correctIndex
                                ? AppTheme.secondary.withValues(alpha: 0.3)
                                : _answered && i == _selectedOption
                                ? AppTheme.danger.withValues(alpha: 0.3)
                                : AppTheme.primarySurface,
                          ),
                          child: Center(
                            child: Text(
                              ['A', 'B', 'C', 'D'][i],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[i],
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_answered && i == correctIndex)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.secondary,
                            size: 24,
                          ),
                        if (_answered &&
                            i == _selectedOption &&
                            i != correctIndex)
                          const Icon(
                            Icons.cancel,
                            color: AppTheme.danger,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _currentIndex + 1 >= widget.questions.length
                  ? 'See Results'
                  : 'Next Question',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreScreen() {
    final total = widget.questions.length;
    final pct = (_score / total * 100).round();
    final color = pct >= 80
        ? AppTheme.secondary
        : pct >= 50
        ? AppTheme.accent
        : AppTheme.danger;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    '$_score / $total',
                    style: TextStyle(
                      fontSize: 16,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            pct >= 80
                ? '🎉 Excellent Work!'
                : pct >= 50
                ? '👍 Good Job!'
                : '📚 Keep Studying!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'You got $_score out of $total questions correct.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
