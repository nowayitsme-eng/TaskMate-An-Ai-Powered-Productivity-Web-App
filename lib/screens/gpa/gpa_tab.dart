import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subject.dart';
import '../../services/gpa_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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

  void _addSubject() {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    final name = _nameController.text.trim();
    final creditsStr = _creditsController.text.trim();
    final gradeValue = _selectedGrade;

    if (name.isEmpty || creditsStr.isEmpty || gradeValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    final credits = double.tryParse(creditsStr);
    if (credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credits must be a valid positive number!')),
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

    _gpaService.addSubject(userId, subject);

    _nameController.clear();
    _creditsController.clear();
    setState(() {
      _selectedGrade = null;
    });
  }

  Widget _buildGpaForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.calculate, color: AppTheme.secondaryLight),
                SizedBox(width: 8),
                Text('GPA Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Subject Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedGrade,
                    decoration: const InputDecoration(hintText: 'Grade'),
                    dropdownColor: AppTheme.dark,
                    items: _gradeMap.keys.map((key) {
                      return DropdownMenuItem(
                        value: key,
                        child: Text('${_gradeLabels[key]} ($key)'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedGrade = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _creditsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Credits'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addSubject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  child: const Icon(Icons.add),
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
    Color gpaColor = AppTheme.dangerLight;
    if (gpa >= 3.5) {
      gpaColor = AppTheme.secondaryLight;
    } else if (gpa >= 2.0) {
      gpaColor = AppTheme.accentLight;
    }

    return Column(
      children: [
        if (subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No subjects added yet', style: TextStyle(color: AppTheme.gray)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final userId = context.read<AuthService>().user!.uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppTheme.glass,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text(sub.grade, textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text('${sub.credits} credits', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grayLight))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.dangerLight),
                        onPressed: () => _gpaService.deleteSubject(userId, sub.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Text('Your Cumulative GPA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                gpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: gpaColor,
                  shadows: [Shadow(color: gpaColor.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 8),
              Text('Based on $totalCredits credit hours', style: const TextStyle(color: AppTheme.grayLight)),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGpaForm(),
          const SizedBox(height: 24),
          if (userId != null)
            StreamBuilder<List<SubjectModel>>(
              stream: _gpaService.getSubjects(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildSubjectListAndResult(snapshot.data!);
              },
            ),
        ],
      ),
    );
  }
}
