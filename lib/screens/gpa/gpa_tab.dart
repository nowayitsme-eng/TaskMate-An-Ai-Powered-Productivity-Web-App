import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subject.dart';
import '../../services/gpa_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeleton_loader.dart';

class GpaTab extends StatefulWidget {
  const GpaTab({super.key});

  @override
  State<GpaTab> createState() => _GpaTabState();
}

class _GpaTabState extends State<GpaTab> {
  final GpaService _gpaService = GpaService();
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController();
  String? _selectedGrade;

  final Map<String, double> _gradeMap = {
    '4.0': 4.0, // A
    '3.5': 3.5, // B+
    '3.0': 3.0, // B
    '2.5': 2.5, // C+
    '2.0': 2.0, // C
    '1.5': 1.5, // D+
    '1.0': 1.0, // D
    '0.0': 0.0, // F
  };

  final Map<String, String> _gradeLabels = {
    '4.0': 'A',
    '3.5': 'B+',
    '3.0': 'B',
    '2.5': 'C+',
    '2.0': 'C',
    '1.5': 'D+',
    '1.0': 'D',
    '0.0': 'F',
  };

  Future<void> _addSubject() async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    final name = _nameController.text.trim();
    final creditsStr = _creditsController.text.trim();
    final gradeValue = _selectedGrade;

    if (name.isEmpty || creditsStr.isEmpty || gradeValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required!')));
      return;
    }

    final credits = double.tryParse(creditsStr);
    if (credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credits must be a valid positive number!'),
        ),
      );
      return;
    }

    final subject = SubjectModel(
      id: '',
      name: name,
      grade: _gradeLabels[gradeValue]!,
      gradeValue: _gradeMap[gradeValue]!,
      credits: credits,
    );

    try {
      await _gpaService.addSubject(userId, subject);

      if (mounted) {
        _nameController.clear();
        _creditsController.clear();
        setState(() {
          _selectedGrade = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save subject: $e')));
      }
    }
  }

  Widget _buildGpaForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calculate, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'GPA Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Subject Name'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGrade,
                      decoration: const InputDecoration(hintText: 'Grade'),
                      dropdownColor: AppTheme.surface,
                      items: _gradeMap.keys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text('${_gradeLabels[key]} ($key)'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGrade = value),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _creditsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: 'Credits'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.8),
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _addSubject,
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: AppTheme.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectListAndResult(List<SubjectModel> subjects) {
    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var sub in subjects) {
      totalGradePoints += sub.gradeValue * sub.credits;
      totalCredits += sub.credits;
    }

    final double gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
    Color gpaColor = AppTheme.danger;
    Color gpaBgColor = AppTheme.dangerSurface;
    if (gpa >= 3.5) {
      gpaColor = AppTheme.secondary;
      gpaBgColor = AppTheme.secondarySurface;
    } else if (gpa >= 2.0) {
      gpaColor = AppTheme.accent;
      gpaBgColor = AppTheme.accentSurface;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: gpaBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gpaColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Your Cumulative GPA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: gpaColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                gpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: gpaColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Based on $totalCredits credit hours',
                  style: TextStyle(
                    color: gpaColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Text(
          'Course List',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        if (subjects.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No subjects added yet',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final userId = context.read<AuthService>().user!.uid;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          sub.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub.grade,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${sub.credits} cr',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.dangerLight,
                        ),
                        onPressed: () =>
                            _gpaService.deleteSubject(userId, sub.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGpaForm(),
          const SizedBox(height: 28),
          if (userId != null)
            StreamBuilder<List<SubjectModel>>(
              stream: _gpaService.getSubjects(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader(height: 180, borderRadius: 24),
                      const SizedBox(height: 32),
                      const SkeletonLoader(width: 120, height: 24),
                      const SizedBox(height: 16),
                      const SkeletonLoader(height: 80, borderRadius: 16),
                      const SizedBox(height: 12),
                      const SkeletonLoader(height: 80, borderRadius: 16),
                    ],
                  );
                }
                return _buildSubjectListAndResult(snapshot.data!);
              },
            ),
        ],
      ),
    );
  }
}
