import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subject.dart';
import '../../models/semester.dart';
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

  final Map<String, double> _gradeMap = {
    '4.0': 4.0, // A
    '3.7': 3.7, // A-
    '3.3': 3.3, // B+
    '3.0': 3.0, // B
    '2.7': 2.7, // B-
    '2.3': 2.3, // C+
    '2.0': 2.0, // C
    '1.7': 1.7, // C-
    '1.3': 1.3, // D+
    '1.0': 1.0, // D
    '0.0': 0.0, // F
  };

  final Map<String, String> _gradeLabels = {
    '4.0': 'A',
    '3.7': 'A-',
    '3.3': 'B+',
    '3.0': 'B',
    '2.7': 'B-',
    '2.3': 'C+',
    '2.0': 'C',
    '1.7': 'C-',
    '1.3': 'D+',
    '1.0': 'D',
    '0.0': 'F',
  };

  void _showAddSemesterDialog(String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add Semester', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Fall 2024',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _gpaService.addSemester(userId, name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCourseDialog(String userId, String semesterId) {
    final nameController = TextEditingController();
    final creditsController = TextEditingController();
    String? selectedGrade;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text('Add Course', style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Course Name (e.g. Calculus I)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: creditsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'Credits (e.g. 3)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGrade,
                          decoration: const InputDecoration(hintText: 'Grade'),
                          dropdownColor: AppTheme.surface,
                          items: _gradeMap.keys.map((key) {
                            return DropdownMenuItem(
                              value: key,
                              child: Text(_gradeLabels[key]!),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedGrade = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final creditsStr = creditsController.text.trim();
                    if (name.isEmpty || creditsStr.isEmpty || selectedGrade == null) return;
                    
                    final credits = double.tryParse(creditsStr);
                    if (credits == null || credits <= 0) return;

                    final subject = SubjectModel(
                      id: '',
                      name: name,
                      grade: _gradeLabels[selectedGrade!]!,
                      gradeValue: _gradeMap[selectedGrade!]!,
                      credits: credits,
                      semesterId: semesterId,
                    );
                    _gpaService.addSubject(userId, subject);
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildCumulativeGpaCard(List<SubjectModel> subjects) {
    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var sub in subjects) {
      totalGradePoints += sub.gradeValue * sub.credits;
      totalCredits += sub.credits;
    }

    final double gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
    
    String status = "Academic Standing";
    IconData statusIcon = Icons.auto_graph;
    if (gpa >= 3.5) {
      status = "Dean's List";
      statusIcon = Icons.emoji_events;
    } else if (gpa >= 3.0) {
      status = "Honor Roll";
      statusIcon = Icons.star;
    } else if (gpa < 2.0 && totalCredits > 0) {
      status = "Academic Probation";
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // primary purple
            Color(0xFF6D28D9), // darker purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.school, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Cumulative GPA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            gpa.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(statusIcon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: gpa / 4.0,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('2.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('3.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('4.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(String userId, SemesterModel semester, List<SubjectModel> subjects) {
    double totalGradePoints = 0;
    double totalCredits = 0;

    for (var sub in subjects) {
      totalGradePoints += sub.gradeValue * sub.credits;
      totalCredits += sub.credits;
    }

    final double semesterGpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
    final Color gpaColor = semesterGpa >= 3.5 ? AppTheme.secondary : (semesterGpa >= 2.0 ? AppTheme.primary : AppTheme.danger);
    final Color gpaBg = gpaColor.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Text(
                semester.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gpaBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  semesterGpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: gpaColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${subjects.length} courses',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                onPressed: () {
                  _gpaService.deleteSemester(userId, semester);
                },
              ),
              const Icon(Icons.expand_more, color: AppTheme.textMuted),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 12),
                  ...subjects.map((sub) => _buildCourseRow(userId, sub)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAddCourseDialog(userId, semester.id),
                      icon: const Icon(Icons.add, color: AppTheme.primary, size: 18),
                      label: const Text(
                        'Add Course',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseRow(String userId, SubjectModel subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              subject.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              subject.credits.toStringAsFixed(0),
              style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _gradeMap.entries.firstWhere((e) => e.value == subject.gradeValue, orElse: () => _gradeMap.entries.first).key,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, size: 16, color: AppTheme.primary),
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14),
                items: _gradeMap.keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(_gradeLabels[key]!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    subject.grade = _gradeLabels[val]!;
                    subject.gradeValue = _gradeMap[val]!;
                    _gpaService.updateSubject(userId, subject);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.border, size: 18),
            onPressed: () => _gpaService.deleteSubject(userId, subject.id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;

    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<GpaData>(
      stream: _gpaService.getGpaData(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: const [
                SkeletonLoader(height: 200, borderRadius: 24),
                SizedBox(height: 32),
                SkeletonLoader(height: 150, borderRadius: 20),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GPA Calculator',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track your academic performance',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildCumulativeGpaCard(data.subjects),
              const SizedBox(height: 32),

              if (data.semesters.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: AppTheme.border),
                        SizedBox(height: 12),
                        Text(
                          'No semesters added yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add your first semester below to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...data.semesters.map((sem) {
                  final semSubjects = data.subjects.where((s) => s.semesterId == sem.id).toList();
                  return _buildSemesterCard(userId, sem, semSubjects);
                }),
              
              const SizedBox(height: 12),

              // Add Semester Button
              InkWell(
                onTap: () => _showAddSemesterDialog(userId),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.3),
                      style: BorderStyle.solid, 
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'Add Semester',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
