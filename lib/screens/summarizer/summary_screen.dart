import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class SummaryScreen extends StatelessWidget {
  final String summary;

  const SummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: summary,
              selectable: true,
              // Fix 8: Only allow safe http/https links
              onTapLink: (text, href, title) async {
                if (href == null) return;
                final uri = Uri.tryParse(href);
                if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.8),
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                listBullet: const TextStyle(color: AppTheme.primaryLight, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
