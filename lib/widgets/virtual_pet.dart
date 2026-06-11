import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

// ─── Evolution Stage Definition ──────────────────────────────────────────────

enum PetStage { seed, sprout, sapling, plant, tree }

class PetEvolution {
  final PetStage stage;
  final String name;
  final String description;
  final int minLevel;

  const PetEvolution({
    required this.stage,
    required this.name,
    required this.description,
    required this.minLevel,
  });
}

const List<PetEvolution> kEvolutions = [
  PetEvolution(
    stage: PetStage.seed,
    name: 'Seed',
    description: 'A tiny seed of potential. Complete tasks to help it grow!',
    minLevel: 1,
  ),
  PetEvolution(
    stage: PetStage.sprout,
    name: 'Sprouty',
    description: 'Sprouty has emerged! It needs consistent focus to thrive.',
    minLevel: 5,
  ),
  PetEvolution(
    stage: PetStage.sapling,
    name: 'Sapling',
    description: 'Growing stronger every day with your productivity.',
    minLevel: 10,
  ),
  PetEvolution(
    stage: PetStage.plant,
    name: 'Flora',
    description: 'A beautiful plant that reflects your hard work.',
    minLevel: 15,
  ),
  PetEvolution(
    stage: PetStage.tree,
    name: 'Grand Oak',
    description: 'A mighty tree! You are a productivity legend.',
    minLevel: 20,
  ),
];

// ─── Mood Definition ─────────────────────────────────────────────────────────

enum PetMood { thriving, happy, neutral, sad, stressed, wilting }

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

class _VirtualPetState extends State<VirtualPet> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _shakeController;

  late Animation<double> _breatheAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );

    _shakeAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
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
    _breatheController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ─── Computed Properties ───────────────────────────────────────────────────

  PetEvolution get _evolution {
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
    if (widget.lastActiveDate != null) {
      final daysSinceActive = DateTime.now().difference(widget.lastActiveDate!).inDays;
      if (daysSinceActive >= 2) return PetMood.wilting;
    }
    if (widget.overdueTasks >= 5) return PetMood.stressed;
    if (widget.hasSevenDayStreak) return PetMood.thriving;
    if (widget.overdueTasks > 0) return PetMood.sad;
    if (widget.completedToday > 0) return PetMood.happy;
    return PetMood.neutral;
  }

  String get _moodLabel {
    switch (_mood) {
      case PetMood.thriving:
        return '${_evolution.name} is THRIVING! ✨';
      case PetMood.happy:
        return '${_evolution.name} is happy! Keep going!';
      case PetMood.neutral:
        return 'Complete a task to water ${_evolution.name}!';
      case PetMood.sad:
        return '${widget.overdueTasks} overdue — ${_evolution.name} is worried!';
      case PetMood.stressed:
        return '${_evolution.name} is STRESSED! Clear tasks!';
      case PetMood.wilting:
        return "${_evolution.name} misses you! You've been away!";
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPetProfile(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondarySurface, AppTheme.skySurface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            _buildAnimatedPlant(),
            const SizedBox(width: 20),
            Expanded(child: _buildStatusText()),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPlant() {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheController, _shakeController]),
      builder: (context, child) {
        double dx = 0;
        double scale = 1.0;

        if (_mood == PetMood.stressed) dx = _shakeAnimation.value;
        if (_mood == PetMood.happy || _mood == PetMood.thriving || _mood == PetMood.neutral) {
          scale = _breatheAnimation.value;
        }

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A10B981), // emerald shadow
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: PlantPainter(stage: _evolution.stage, mood: _mood),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    final next = _nextEvolution;
    final progress = next != null 
        ? (widget.level - _evolution.minLevel) / (next.minLevel - _evolution.minLevel) 
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _evolution.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv ${widget.level}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _moodLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // Custom XP Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Pet Profile Dialog ───────────────────────────────────────────────────

  void _showPetProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.secondarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryLight, width: 2),
                ),
                child: CustomPaint(
                  painter: PlantPainter(stage: _evolution.stage, mood: _mood),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _evolution.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _evolution.stage.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _evolution.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plant Painter ────────────────────────────────────────────────────────────

class PlantPainter extends CustomPainter {
  final PetStage stage;
  final PetMood mood;

  PlantPainter({required this.stage, required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    
    // Pot
    final potPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // slate-200
      ..style = PaintingStyle.fill;
    
    final potPath = Path()
      ..moveTo(center.dx - 16, center.dy + 8)
      ..lineTo(center.dx + 16, center.dy + 8)
      ..lineTo(center.dx + 12, center.dy + 24)
      ..lineTo(center.dx - 12, center.dy + 24)
      ..close();
      
    // Pot Rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 36, height: 6),
      const Radius.circular(2),
    );
    
    canvas.drawPath(potPath, potPaint);
    canvas.drawRRect(rimRect, potPaint);

    // Stem and leaves based on stage
    final stemPaint = Paint()
      ..color = _getMoodColor()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final leafPaint = Paint()
      ..color = _getMoodColor()
      ..style = PaintingStyle.fill;

    double droop = (mood == PetMood.wilting || mood == PetMood.sad) ? 10.0 : 0.0;

    if (stage == PetStage.seed) {
      // Just a tiny green dot sticking out
      canvas.drawCircle(Offset(center.dx, center.dy + 4), 4, leafPaint);
    } else {
      // Stem
      double height = 20.0;
      if (stage == PetStage.sapling) height = 25.0;
      if (stage == PetStage.plant) height = 30.0;
      if (stage == PetStage.tree) height = 35.0;
      
      final stemPath = Path()
        ..moveTo(center.dx, center.dy + 5)
        ..quadraticBezierTo(center.dx + (droop/2), center.dy - height/2, center.dx + droop, center.dy - height);
      
      canvas.drawPath(stemPath, stemPaint);

      // Leaves
      _drawLeaf(canvas, Offset(center.dx - 2, center.dy - height/2), -math.pi/4 + (droop*0.05), leafPaint);
      _drawLeaf(canvas, Offset(center.dx + 2, center.dy - height*0.8), math.pi/4 + (droop*0.05), leafPaint);
      
      if (stage == PetStage.plant || stage == PetStage.tree) {
        _drawLeaf(canvas, Offset(center.dx - 2, center.dy - height*0.2), -math.pi/6, leafPaint);
      }
      
      if (stage == PetStage.tree) {
        _drawLeaf(canvas, Offset(center.dx + droop, center.dy - height), -math.pi/2, leafPaint); // Top leaf
      }
    }
    
    // Face (eyes) if happy or thriving
    if (mood == PetMood.happy || mood == PetMood.thriving) {
      final eyePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(center.dx - 4 + droop, center.dy - 12), 1.5, eyePaint);
      canvas.drawCircle(Offset(center.dx + 4 + droop, center.dy - 12), 1.5, eyePaint);
    }
  }

  void _drawLeaf(Canvas canvas, Offset pos, double angle, Paint paint) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-8, -4, -10, -10)
      ..quadraticBezierTo(-4, -8, 0, 0)
      ..close();
      
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  Color _getMoodColor() {
    switch (mood) {
      case PetMood.thriving: return const Color(0xFF059669); // emerald-600
      case PetMood.happy: return const Color(0xFF10B981); // emerald-500
      case PetMood.neutral: return const Color(0xFF34D399); // emerald-400
      case PetMood.sad: return const Color(0xFF94A3B8); // slate-400
      case PetMood.stressed: return const Color(0xFFF43F5E); // rose-500
      case PetMood.wilting: return const Color(0xFFCBD5E1); // slate-300
    }
  }

  @override
  bool shouldRepaint(PlantPainter oldDelegate) => 
      oldDelegate.stage != stage || oldDelegate.mood != mood;
}
