import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final AiService _aiService = AiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, String>> _history = [
    {"role": "system", "content": "You are TaskMate, a helpful AI assistant. Always reply in English only."}
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    _inputController.clear();

    // Optimistically save to local state and Firestore
    _history.add({"role": "user", "content": text});
    await _aiService.saveMessage(userId, 'user', text);

    try {
      final response = await _aiService.getAiResponse(_history);
      
      _history.add({"role": "assistant", "content": response});
      await _aiService.saveMessage(userId, 'assistant', response);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _clearChat() async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    await _aiService.clearChat(userId);
    _history.removeWhere((msg) => msg['role'] != 'system');
    setState(() {});
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.secondary.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: isUser ? AppTheme.secondary.withValues(alpha: 0.3) : AppTheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: MarkdownBody(
          data: msg['content'] ?? '',
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: isUser ? const Color(0xFFA7F3D0) : const Color(0xFFE9D5FF), fontSize: 16),
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            code: TextStyle(
              backgroundColor: Colors.transparent,
              color: AppTheme.accentLight,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.smart_toy, color: AppTheme.primaryLight),
                      SizedBox(width: 8),
                      Text('AI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _clearChat,
                    icon: const Icon(Icons.delete, color: AppTheme.dangerLight),
                    label: const Text('Clear Chat', style: TextStyle(color: AppTheme.dangerLight)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: userId == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _aiService.getChatHistory(userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final messages = snapshot.data!;
                            
                            // Initialize with welcome if empty
                            if (messages.isEmpty) {
                              return ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _buildMessageBubble({
                                    'role': 'assistant',
                                    'content': "Hello! I'm your AI productivity assistant. Ask me anything about time management, study techniques, or productivity hacks!"
                                  }),
                                ],
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageBubble(messages[index]);
                              },
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
