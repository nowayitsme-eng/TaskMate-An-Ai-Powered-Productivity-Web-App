import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
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
    {
      "role": "system",
      "content":
          "You are TaskMate, a helpful AI assistant. Always reply in English only.",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final messages = await _aiService.getChatHistory(userId).first;
      if (messages.isNotEmpty) {
        setState(() {
          for (var msg in messages) {
            final role = msg['role'] as String?;
            final content = msg['content'] as String?;
            if (role != null && content != null) {
              _history.add({"role": role, "content": content});
            }
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
          color: isUser ? AppTheme.primarySurface : AppTheme.surface,
          border: Border.all(
            color: isUser ? AppTheme.primaryLight : AppTheme.border,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: MarkdownBody(
          data: msg['content'] ?? '',
          selectable: true,
          // Fix 8: Sanitize links — only allow safe http/https URLs
          onTapLink: (text, href, title) async {
            if (href == null) return;
            final uri = Uri.tryParse(href);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? AppTheme.primaryDark : AppTheme.textPrimary,
              fontSize: 16,
            ),
            codeblockDecoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            code: TextStyle(
              backgroundColor: Colors.transparent,
              color: AppTheme.accent,
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
        elevation: 0,
        color: Colors.transparent,
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
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _clearChat,
                    icon: const Icon(Icons.delete, color: AppTheme.dangerLight),
                    label: const Text(
                      'Clear Chat',
                      style: TextStyle(color: AppTheme.dangerLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: userId == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _aiService.getChatHistory(userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final messages = snapshot.data!;

                            // Initialize with welcome if empty
                            if (messages.isEmpty) {
                              return ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _buildMessageBubble({
                                    'role': 'assistant',
                                    'content':
                                        "Hello! I'm your AI productivity assistant. Ask me anything about time management, study techniques, or productivity hacks!",
                                  }),
                                ],
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _scrollToBottom(),
                            );

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
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        counterText: "",
                      ),
                      onSubmitted: (_) => _sendMessage(),
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
                        onTap: _isLoading ? null : _sendMessage,
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.textPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: AppTheme.textPrimary,
                                  size: 20,
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
      ),
    );
  }
}
