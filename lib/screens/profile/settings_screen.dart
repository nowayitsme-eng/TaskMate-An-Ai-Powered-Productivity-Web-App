import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Appearance ─────────────────────────────────────────────────
          _SectionHeader(title: '🎨 Appearance'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ThemeButton(
                      label: 'System',
                      icon: Icons.brightness_auto,
                      isSelected: settings.themeMode == ThemeMode.system,
                      onTap: () => settings.setThemeMode(ThemeMode.system),
                    ),
                    const SizedBox(width: 12),
                    _ThemeButton(
                      label: 'Light',
                      icon: Icons.wb_sunny_rounded,
                      isSelected: settings.themeMode == ThemeMode.light,
                      onTap: () => settings.setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 12),
                    _ThemeButton(
                      label: 'Dark',
                      icon: Icons.nightlight_round,
                      isSelected: settings.themeMode == ThemeMode.dark,
                      onTap: () => settings.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Pomodoro ───────────────────────────────────────────────────
          _SectionHeader(title: '🍅 Pomodoro Defaults'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _DurationRow(
                  label: 'Focus Duration',
                  subtitle: 'How long each work session lasts',
                  value: settings.pomodoroWork,
                  min: 5,
                  max: 90,
                  onChanged: (v) => settings.setPomodoroWork(v),
                ),
                const Divider(height: 28),
                _DurationRow(
                  label: 'Short Break',
                  subtitle: 'Break after each focus session',
                  value: settings.pomodoroBreak,
                  min: 1,
                  max: 30,
                  onChanged: (v) => settings.setPomodoroBreak(v),
                ),
                const Divider(height: 28),
                _DurationRow(
                  label: 'Long Break',
                  subtitle: 'Break after 4 sessions',
                  value: settings.pomodoroLongBreak,
                  min: 5,
                  max: 60,
                  onChanged: (v) => settings.setPomodoroLongBreak(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notifications ──────────────────────────────────────────────
          _SectionHeader(title: '🔔 Notifications'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound Effects',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('Play a sound when Pomodoro sessions end'),
              value: settings.soundEnabled,
              activeThumbColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
              onChanged: (v) => settings.setSoundEnabled(v),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5));
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primaryLight : Colors.grey,
                  size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryLight : Colors.grey,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _DurationRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.primary,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text('$value',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primary,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
            const SizedBox(width: 4),
            const Text('min', style: TextStyle(color: AppTheme.gray, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
