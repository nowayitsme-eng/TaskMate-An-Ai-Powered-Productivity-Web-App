import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import 'summary_screen.dart';
import 'flashcards_screen.dart';
import 'quiz_screen.dart';

// ─── Mode enum ───────────────────────────────────────────────────────────────

enum StudyMode { summarize, flashcards, quiz }

// ─── Main tab widget ─────────────────────────────────────────────────────────

class SummarizerTab extends StatefulWidget {
  const SummarizerTab({super.key});

  @override
  State<SummarizerTab> createState() => _SummarizerTabState();
}

class _SummarizerTabState extends State<SummarizerTab> {
  final AiService _aiService = AiService();
  final TextEditingController _notesController = TextEditingController();

  StudyMode _mode = StudyMode.summarize;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _notesController.text.trim();
    if (text.length < 30) {
      _showSnack('Please enter at least 30 characters.');
      return;
    }

    // Fix 7: Hard cap to prevent OOM and runaway AI costs
    if (text.length > 12000) {
      _showSnack(
        'Text is too long (max 12,000 characters). Please trim your notes.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      switch (_mode) {
        case StudyMode.summarize:
          final result = await _aiService.summarizeText(text);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SummaryScreen(summary: result)),
            );
          }
          break;
        case StudyMode.flashcards:
          final cards = await _aiService.generateFlashcards(text);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardsScreen(flashcards: cards),
              ),
            );
          }
          break;
        case StudyMode.quiz:
          final questions = await _aiService.generateQuiz(text);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(questions: questions),
              ),
            );
          }
          break;
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _buttonLabel {
    if (_isLoading) {
      switch (_mode) {
        case StudyMode.summarize:
          return 'Summarizing...';
        case StudyMode.flashcards:
          return 'Creating Flashcards...';
        case StudyMode.quiz:
          return 'Building Quiz...';
      }
    }
    switch (_mode) {
      case StudyMode.summarize:
        return 'Summarize';
      case StudyMode.flashcards:
        return 'Generate Flashcards';
      case StudyMode.quiz:
        return 'Generate Quiz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: const [
                  Icon(Icons.school, color: AppTheme.accentLight),
                  SizedBox(width: 8),
                  Text(
                    'Study Hub',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode selector
              _buildModeSelector(),

              const SizedBox(height: 24),

              // Main content area (Input only)
              Expanded(child: _buildInputArea()),

              const SizedBox(height: 24),

              // Generate button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _buttonLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildModeTab(StudyMode.summarize, Icons.summarize, 'Summarize'),
          _buildModeTab(StudyMode.flashcards, Icons.style, 'Flashcards'),
          _buildModeTab(StudyMode.quiz, Icons.quiz, 'Quiz'),
        ],
      ),
    );
  }

  Widget _buildModeTab(StudyMode mode, IconData icon, String label) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppTheme.primaryLight : AppTheme.gray,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive ? AppTheme.primaryLight : AppTheme.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _notesController,
        maxLines: null,
        expands: true,
        maxLength: 5000,
        decoration: const InputDecoration(
          hintText:
              'Paste your lecture notes, article, or any long text here...\n\nWhen you hit Generate, a dedicated full-screen view will open with your results!',
          hintStyle: TextStyle(color: AppTheme.grayLight, height: 1.5),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        style: const TextStyle(height: 1.5, fontSize: 16),
      ),
    );
  }
}
