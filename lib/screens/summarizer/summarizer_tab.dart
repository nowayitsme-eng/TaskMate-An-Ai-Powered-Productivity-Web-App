import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

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

  // Summarize state
  String _summary = "Your concise summary will appear here...";

  // Flashcard state
  List<Map<String, String>> _flashcards = [];

  // Quiz state
  List<Map<String, dynamic>> _quizQuestions = [];

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

    setState(() => _isLoading = true);

    try {
      switch (_mode) {
        case StudyMode.summarize:
          final result = await _aiService.summarizeText(text);
          setState(() => _summary = result);
          break;
        case StudyMode.flashcards:
          final cards = await _aiService.generateFlashcards(text);
          setState(() => _flashcards = cards);
          break;
        case StudyMode.quiz:
          final questions = await _aiService.generateQuiz(text);
          setState(() => _quizQuestions = questions);
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
                  Text('Study Hub',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // Mode selector
              _buildModeSelector(),

              const SizedBox(height: 20),

              // Main content area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    if (_mode == StudyMode.summarize) {
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildInputArea()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildSummaryOutput()),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildInputArea()),
                            const SizedBox(height: 24),
                            Expanded(child: _buildSummaryOutput()),
                          ],
                        );
                      }
                    } else {
                      // Flashcards and Quiz show input on top, output below
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 150,
                            child: _buildInputArea(),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildOutputForMode()),
                        ],
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Generate button
              Center(
                child: SizedBox(
                  width: 260,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_buttonLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
            color: isActive ? AppTheme.primary.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.primary.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive ? AppTheme.primaryLight : AppTheme.gray),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _notesController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'Paste your lecture notes, article, or any long text here...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        style: const TextStyle(height: 1.5),
      ),
    );
  }

  Widget _buildSummaryOutput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: _summary,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 16, height: 1.6),
            listBullet: const TextStyle(color: AppTheme.primaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputForMode() {
    switch (_mode) {
      case StudyMode.summarize:
        return _buildSummaryOutput();
      case StudyMode.flashcards:
        return _buildFlashcardsOutput();
      case StudyMode.quiz:
        return _buildQuizOutput();
    }
  }

  // ─── Flashcards ───────────────────────────────────────────────────────────

  Widget _buildFlashcardsOutput() {
    if (_flashcards.isEmpty) {
      return _buildEmptyState(
        icon: Icons.style,
        message: 'Your flashcards will appear here.\nPaste your notes and tap "Generate Flashcards".',
      );
    }

    return ListView.builder(
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        return _FlipCard(
          index: index + 1,
          question: _flashcards[index]['question'] ?? '',
          answer: _flashcards[index]['answer'] ?? '',
        );
      },
    );
  }

  // ─── Quiz ─────────────────────────────────────────────────────────────────

  Widget _buildQuizOutput() {
    if (_quizQuestions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz,
        message: 'Your quiz will appear here.\nPaste your notes and tap "Generate Quiz".',
      );
    }

    return _QuizWidget(questions: _quizQuestions);
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gray, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── Flip Card Widget ─────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final int index;
  final String question;
  final String answer;

  const _FlipCard({
    required this.index,
    required this.question,
    required this.answer,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showAnswer) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFront = angle <= pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFront
                      ? [AppTheme.primary.withOpacity(0.2), AppTheme.primaryDark.withOpacity(0.15)]
                      : [AppTheme.secondary.withOpacity(0.2), AppTheme.secondaryDark.withOpacity(0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFront
                      ? AppTheme.primary.withOpacity(0.35)
                      : AppTheme.secondary.withOpacity(0.35),
                ),
              ),
              child: Transform(
                // Counter-rotate text so it stays readable
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isFront ? 0 : pi),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFront
                                ? AppTheme.primary.withOpacity(0.25)
                                : AppTheme.secondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFront ? 'Q${widget.index}' : 'Answer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFront ? AppTheme.primaryLight : AppTheme.secondaryLight,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFront ? widget.question : widget.answer,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isFront ? Colors.white : AppTheme.secondaryLight,
                        fontWeight: isFront ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Quiz Widget ─────────────────────────────────────────────────────────────

class _QuizWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  const _QuizWidget({required this.questions});

  @override
  State<_QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<_QuizWidget> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _finished = false;

  void _selectOption(int optionIndex) {
    if (_answered) return;
    final correct = widget.questions[_currentIndex]['correctIndex'] as int;
    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      if (optionIndex == correct) _score++;
    });
  }

  void _next() {
    if (_currentIndex + 1 >= widget.questions.length) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _score = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildScoreScreen();

    final q = widget.questions[_currentIndex];
    final options = (q['options'] as List<dynamic>).cast<String>();
    final correctIndex = q['correctIndex'] as int;
    final total = widget.questions.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: const TextStyle(color: AppTheme.gray, fontSize: 12),
              ),
              Text(
                'Score: $_score',
                style: const TextStyle(color: AppTheme.accentLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Text(
              q['question'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          // Options
          ...List.generate(options.length, (i) {
            Color? borderColor;
            Color? bgColor;
            if (_answered) {
              if (i == correctIndex) {
                borderColor = AppTheme.secondary;
                bgColor = AppTheme.secondary.withOpacity(0.15);
              } else if (i == _selectedOption && i != correctIndex) {
                borderColor = AppTheme.danger;
                bgColor = AppTheme.danger.withOpacity(0.12);
              } else {
                borderColor = Colors.white.withOpacity(0.06);
                bgColor = Colors.white.withOpacity(0.03);
              }
            } else {
              borderColor = Colors.white.withOpacity(0.1);
              bgColor = Colors.white.withOpacity(0.04);
            }

            return GestureDetector(
              onTap: () => _selectOption(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _answered && i == correctIndex
                            ? AppTheme.secondary.withOpacity(0.3)
                            : _answered && i == _selectedOption
                                ? AppTheme.danger.withOpacity(0.3)
                                : Colors.white.withOpacity(0.08),
                      ),
                      child: Center(
                        child: Text(
                          ['A', 'B', 'C', 'D'][i],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(options[i], style: const TextStyle(fontSize: 14))),
                    if (_answered && i == correctIndex)
                      const Icon(Icons.check_circle, color: AppTheme.secondary, size: 20),
                    if (_answered && i == _selectedOption && i != correctIndex)
                      const Icon(Icons.cancel, color: AppTheme.danger, size: 20),
                  ],
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentIndex + 1 >= widget.questions.length ? 'See Results' : 'Next Question',
              ),
            ),
          ],
        ],
      ),
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4), width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900, color: color),
                  ),
                  Text(
                    '$_score / $total',
                    style: TextStyle(fontSize: 13, color: color.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            pct >= 80
                ? '🎉 Excellent Work!'
                : pct >= 50
                    ? '👍 Good Job!'
                    : '📚 Keep Studying!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You got $_score out of $total questions correct.',
            style: const TextStyle(color: AppTheme.grayLight),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
