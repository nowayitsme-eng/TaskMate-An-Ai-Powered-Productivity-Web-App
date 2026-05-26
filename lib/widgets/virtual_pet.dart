import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PetMood { happy, neutral, sad }

/// An animated virtual pet mascot that reflects the user's task health.
/// [overdueTasks] - number of overdue incomplete tasks
/// [completedToday] - number of tasks completed today
class VirtualPet extends StatefulWidget {
  final int overdueTasks;
  final int completedToday;

  const VirtualPet({
    super.key,
    required this.overdueTasks,
    required this.completedToday,
  });

  @override
  State<VirtualPet> createState() => _VirtualPetState();
}

class _VirtualPetState extends State<VirtualPet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PetMood get _mood {
    if (widget.overdueTasks > 0) return PetMood.sad;
    if (widget.completedToday > 0) return PetMood.happy;
    return PetMood.neutral;
  }

  String get _petEmoji {
    switch (_mood) {
      case PetMood.happy:
        return '😸';
      case PetMood.neutral:
        return '🐱';
      case PetMood.sad:
        return '😿';
    }
  }

  Color get _glowColor {
    switch (_mood) {
      case PetMood.happy:
        return AppTheme.secondary;
      case PetMood.neutral:
        return AppTheme.primary;
      case PetMood.sad:
        return AppTheme.danger;
    }
  }

  String get _moodLabel {
    switch (_mood) {
      case PetMood.happy:
        return 'Your pet is happy! 🎉';
      case PetMood.neutral:
        return 'Start a task to cheer them up!';
      case PetMood.sad:
        return '${widget.overdueTasks} overdue — pet is worried!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _glowColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glowColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Animated pet
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(0, _mood == PetMood.happy ? _bounceAnimation.value : 0),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _glowColor.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withValues(alpha: _glowAnimation.value * 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _petEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Companion',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppTheme.grayLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _moodLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _glowColor.withValues(alpha: 0.9),
                  ),
                ),
                if (_mood == PetMood.happy) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.completedToday} task${widget.completedToday > 1 ? 's' : ''} done today',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
