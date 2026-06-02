import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Toast Data Model ─────────────────────────────────────────────────────────

enum ToastType { info, success, warning, achievement }

class ToastMessage {
  final String title;
  final String body;
  final ToastType type;
  final Duration duration;

  const ToastMessage({
    required this.title,
    required this.body,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 4),
  });
}

// ─── Global Toast Controller ──────────────────────────────────────────────────

class ToastController {
  static final ToastController _instance = ToastController._internal();
  factory ToastController() => _instance;
  ToastController._internal();

  final StreamController<ToastMessage> _controller =
      StreamController<ToastMessage>.broadcast();

  Stream<ToastMessage> get stream => _controller.stream;

  void show(ToastMessage message) {
    _controller.add(message);
  }

  /// Shorthand helpers
  void showSuccess(String title, String body) =>
      show(ToastMessage(title: title, body: body, type: ToastType.success));

  void showWarning(String title, String body) =>
      show(ToastMessage(title: title, body: body, type: ToastType.warning));

  void showAchievement(String title, String body) =>
      show(ToastMessage(
          title: title,
          body: body,
          type: ToastType.achievement,
          duration: const Duration(seconds: 5)));

  void showInfo(String title, String body) =>
      show(ToastMessage(title: title, body: body, type: ToastType.info));

  void dispose() => _controller.close();
}

// ─── Notification Overlay ─────────────────────────────────────────────────────

/// Wrap your root widget with this to enable in-app toasts across the whole app.
class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({super.key, required this.child});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  final List<_ToastEntry> _toasts = [];
  StreamSubscription<ToastMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ToastController().stream.listen(_onToast);
  }

  void _onToast(ToastMessage msg) {
    final entry = _ToastEntry(message: msg, key: UniqueKey());
    setState(() => _toasts.add(entry));

    // Auto-remove after duration
    Timer(msg.duration + const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _toasts.remove(entry));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Toast stack — top of screen, safe area aware
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Column(
            children: _toasts
                .map((e) => _AnimatedToast(key: e.key, message: e.message))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ToastEntry {
  final ToastMessage message;
  final Key key;
  _ToastEntry({required this.message, required this.key});
}

// ─── Animated Toast Widget ────────────────────────────────────────────────────

class _AnimatedToast extends StatefulWidget {
  final ToastMessage message;

  const _AnimatedToast({super.key, required this.message});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );

    _ctrl.forward();

    // Start fade-out before removal
    Timer(widget.message.duration - const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.message.type) {
      case ToastType.success:
        return AppTheme.secondary.withValues(alpha: 0.15);
      case ToastType.warning:
        return AppTheme.accent.withValues(alpha: 0.15);
      case ToastType.achievement:
        return const Color(0xFFFFD700).withValues(alpha: 0.15);
      case ToastType.info:
        return AppTheme.primary.withValues(alpha: 0.15);
    }
  }

  Color get _borderColor {
    switch (widget.message.type) {
      case ToastType.success:
        return AppTheme.secondary.withValues(alpha: 0.5);
      case ToastType.warning:
        return AppTheme.accent.withValues(alpha: 0.5);
      case ToastType.achievement:
        return const Color(0xFFFFD700).withValues(alpha: 0.5);
      case ToastType.info:
        return AppTheme.primary.withValues(alpha: 0.5);
    }
  }

  IconData get _icon {
    switch (widget.message.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.achievement:
        return Icons.emoji_events_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  Color get _iconColor {
    switch (widget.message.type) {
      case ToastType.success:
        return AppTheme.secondary;
      case ToastType.warning:
        return AppTheme.accent;
      case ToastType.achievement:
        return const Color(0xFFFFD700);
      case ToastType.info:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.dark.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: _iconColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgColor,
                  ),
                  child: Icon(_icon, color: _iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.message.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.message.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grayLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
