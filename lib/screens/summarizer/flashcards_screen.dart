import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<Map<String, String>> flashcards;

  const FlashcardsScreen({super.key, required this.flashcards});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No flashcards found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Flashcards', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.flashcards.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                  child: _FlipCard(
                    index: index + 1,
                    total: widget.flashcards.length,
                    question: widget.flashcards[index]['question'] ?? '',
                    answer: widget.flashcards[index]['answer'] ?? '',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryLight),
                iconSize: 28,
              ),
              const SizedBox(width: 32),
              const Text(
                'Tap to flip',
                style: TextStyle(color: AppTheme.grayLight, fontSize: 16),
              ),
              const SizedBox(width: 32),
              IconButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryLight),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  final int index;
  final int total;
  final String question;
  final String answer;

  const _FlipCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFront
                      ? [AppTheme.primary.withValues(alpha: 0.3), AppTheme.primaryDark.withValues(alpha: 0.2)]
                      : [AppTheme.secondary.withValues(alpha: 0.3), AppTheme.secondaryDark.withValues(alpha: 0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isFront
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.secondary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFront ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.secondary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isFront ? 0 : pi),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFront ? 'Q ${widget.index}/${widget.total}' : 'Answer',
                      style: TextStyle(
                        color: isFront ? AppTheme.primaryLight : AppTheme.secondaryLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Center(
                        child: Text(
                          isFront ? widget.question : widget.answer,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
                        ),
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
