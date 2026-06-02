import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Evolution Stage Definition ──────────────────────────────────────────────

enum PetStage { egg, baby, teen, adult, legend }

class PetEvolution {
  final PetStage stage;
  final String name;
  final String emoji;
  final String description;
  final int minLevel;
  final Color primaryColor;

  const PetEvolution({
    required this.stage,
    required this.name,
    required this.emoji,
    required this.description,
    required this.minLevel,
    required this.primaryColor,
  });
}

const List<PetEvolution> kEvolutions = [
  PetEvolution(
    stage: PetStage.egg,
    name: '???',
    emoji: '🥚',
    description: 'A mysterious egg... complete tasks to hatch it!',
    minLevel: 1,
    primaryColor: Color(0xFF9B59B6),
  ),
  PetEvolution(
    stage: PetStage.baby,
    name: 'Byte',
    emoji: '🐣',
    description: 'Byte has hatched! This little one loves to see you work.',
    minLevel: 5,
    primaryColor: Color(0xFFF39C12),
  ),
  PetEvolution(
    stage: PetStage.teen,
    name: 'Zap',
    emoji: '🐱',
    description: 'Zap is a quick learner and thrives on consistency.',
    minLevel: 10,
    primaryColor: Color(0xFF00BCD4),
  ),
  PetEvolution(
    stage: PetStage.adult,
    name: 'Flux',
    emoji: '😸',
    description: 'Flux is wise and energetic. Nothing stops Flux!',
    minLevel: 15,
    primaryColor: Color(0xFF2ECC71),
  ),
  PetEvolution(
    stage: PetStage.legend,
    name: 'Nova',
    emoji: '🦁',
    description: 'Nova is a legend. Rulers of productivity bow to Nova.',
    minLevel: 20,
    primaryColor: Color(0xFFFFD700),
  ),
];

// ─── Mood Definition ─────────────────────────────────────────────────────────

enum PetMood { thriving, happy, neutral, sad, stressed, starving }

// ─── Virtual Pet Widget ───────────────────────────────────────────────────────

class VirtualPet extends StatefulWidget {
  final int overdueTasks;
  final int completedToday;
  final int level;
  final bool hasSevenDayStreak;
  final DateTime? lastActiveDate;

  const VirtualPet({
    super.key,
    required this.overdueTasks,
    required this.completedToday,
    required this.level,
    this.hasSevenDayStreak = false,
    this.lastActiveDate,
  });

  @override
  State<VirtualPet> createState() => _VirtualPetState();
}

class _VirtualPetState extends State<VirtualPet>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _maybeShake();
  }

  void _maybeShake() {
    if (_mood == PetMood.stressed) {
      _shakeController.repeat(reverse: true);
    } else {
      _shakeController.stop();
    }
  }

  @override
  void didUpdateWidget(VirtualPet old) {
    super.didUpdateWidget(old);
    _maybeShake();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Computed Properties ───────────────────────────────────────────────────

  PetEvolution get _evolution {
    // Walk backwards to find the highest unlocked evolution
    for (final evo in kEvolutions.reversed) {
      if (widget.level >= evo.minLevel) return evo;
    }
    return kEvolutions.first;
  }

  PetEvolution? get _nextEvolution {
    final idx = kEvolutions.indexOf(_evolution);
    if (idx < kEvolutions.length - 1) return kEvolutions[idx + 1];
    return null;
  }

  PetMood get _mood {
    // Starving — hasn't opened app in 2+ days
    if (widget.lastActiveDate != null) {
      final daysSinceActive =
          DateTime.now().difference(widget.lastActiveDate!).inDays;
      if (daysSinceActive >= 2) return PetMood.starving;
    }
    // Stressed — 5+ overdue tasks
    if (widget.overdueTasks >= 5) return PetMood.stressed;
    // Thriving — 7-day streak
    if (widget.hasSevenDayStreak) return PetMood.thriving;
    // Sad — any overdue
    if (widget.overdueTasks > 0) return PetMood.sad;
    // Happy — completed tasks today
    if (widget.completedToday > 0) return PetMood.happy;
    return PetMood.neutral;
  }

  Color get _moodColor {
    switch (_mood) {
      case PetMood.thriving:
        return const Color(0xFFFFD700);
      case PetMood.happy:
        return AppTheme.secondary;
      case PetMood.neutral:
        return _evolution.primaryColor;
      case PetMood.sad:
        return AppTheme.accent;
      case PetMood.stressed:
        return AppTheme.danger;
      case PetMood.starving:
        return AppTheme.gray;
    }
  }

  String get _moodEmoji {
    switch (_mood) {
      case PetMood.thriving:
        return '${_evolution.emoji}✨';
      case PetMood.happy:
        return _evolution.emoji;
      case PetMood.neutral:
        return _evolution.emoji;
      case PetMood.sad:
        return _evolution.stage == PetStage.egg ? '🥚' : '🥺';
      case PetMood.stressed:
        return '😰';
      case PetMood.starving:
        return _evolution.stage == PetStage.egg ? '🥚' : '😴';
    }
  }

  String get _moodLabel {
    switch (_mood) {
      case PetMood.thriving:
        return '${_evolution.name} is THRIVING! 🔥';
      case PetMood.happy:
        return '${_evolution.name} is happy! Keep going!';
      case PetMood.neutral:
        return 'Complete a task to cheer ${_evolution.name} up!';
      case PetMood.sad:
        return '${widget.overdueTasks} overdue — ${_evolution.name} is worried!';
      case PetMood.stressed:
        return '${_evolution.name} is STRESSED! Clear those tasks!';
      case PetMood.starving:
        return "${_evolution.name} misses you! You've been away!";
    }
  }

  bool get _shouldBounce =>
      _mood == PetMood.happy ||
      _mood == PetMood.thriving;

  bool get _shouldPulse => _evolution.stage == PetStage.egg;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPetProfile(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _moodColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _moodColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            _buildAnimatedPet(),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusText()),
            _buildEvolutionBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPet() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_bounceController, _glowController, _shakeController, _pulseController]),
      builder: (context, child) {
        double dy = 0;
        double dx = 0;
        double scale = 1.0;

        if (_shouldBounce) dy = _bounceAnimation.value;
        if (_mood == PetMood.stressed) dx = _shakeAnimation.value;
        if (_shouldPulse) scale = _pulseAnimation.value;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _moodColor.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: _moodColor
                        .withValues(alpha: _glowAnimation.value * 0.45),
                    blurRadius:
                        _mood == PetMood.thriving ? 28 : 16,
                    spreadRadius:
                        _mood == PetMood.thriving ? 4 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _moodEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Companion • Tap to view',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppTheme.grayLight.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _moodLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _moodColor,
          ),
        ),
        if (_mood == PetMood.happy || _mood == PetMood.thriving) ...[
          const SizedBox(height: 3),
          Text(
            '${widget.completedToday} task${widget.completedToday > 1 ? 's' : ''} done today',
            style: TextStyle(
              fontSize: 11,
              color: _moodColor.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvolutionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _evolution.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _evolution.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Lv ${widget.level}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _evolution.primaryColor,
        ),
      ),
    );
  }

  // ─── Pet Profile Dialog ───────────────────────────────────────────────────

  void _showPetProfile(BuildContext context) {
    final next = _nextEvolution;
    final levelsToNext = next != null ? next.minLevel - widget.level : 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.dark,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: _evolution.primaryColor.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: _evolution.primaryColor.withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big pet display
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _evolution.primaryColor.withValues(alpha: 0.15),
                  border: Border.all(
                      color: _evolution.primaryColor.withValues(alpha: 0.5),
                      width: 2),
                ),
                child: Center(
                  child: Text(_moodEmoji,
                      style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),
              // Name & stage
              Text(
                _evolution.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _evolution.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _evolution.stage.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: AppTheme.grayLight,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                _evolution.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.grayLight),
              ),
              const SizedBox(height: 20),
              // Current mood chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _moodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _moodLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _moodColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Evolution progress
              if (next != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Next: ${next.name} (${next.emoji})',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.grayLight)),
                    Text('$levelsToNext levels away',
                        style: TextStyle(
                            fontSize: 12,
                            color: next.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (widget.level - _evolution.minLevel) /
                        (next.minLevel - _evolution.minLevel),
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(next.primaryColor),
                    minHeight: 6,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '👑 Maximum evolution reached! You are a legend!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFFFD700)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close',
                    style: TextStyle(color: AppTheme.grayLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
