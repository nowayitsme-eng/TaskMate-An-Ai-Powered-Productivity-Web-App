import 'package:flutter/material.dart';
import 'settings_service.dart';

/// Global settings provider. Wrap MaterialApp with this to enable
/// live theme switching and accessible settings from any widget.
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  int _pomodoroWork = 25;
  int _pomodoroBreak = 5;
  int _pomodoroLongBreak = 15;
  bool _soundEnabled = true;

  int get pomodoroWork => _pomodoroWork;
  int get pomodoroBreak => _pomodoroBreak;
  int get pomodoroLongBreak => _pomodoroLongBreak;
  bool get soundEnabled => _soundEnabled;

  /// Call once at app startup to restore saved preferences.
  Future<void> load() async {
    _pomodoroWork = await _service.getPomodoroWork();
    _pomodoroBreak = await _service.getPomodoroBreak();
    _pomodoroLongBreak = await _service.getPomodoroLongBreak();
    _soundEnabled = await _service.getSoundEnabled();
    notifyListeners();
  }

  // ─── Setters ───────────────────────────────────────────────────────────────

  Future<void> setPomodoroWork(int minutes) async {
    _pomodoroWork = minutes;
    await _service.setPomodoroWork(minutes);
    notifyListeners();
  }

  Future<void> setPomodoroBreak(int minutes) async {
    _pomodoroBreak = minutes;
    await _service.setPomodoroBreak(minutes);
    notifyListeners();
  }

  Future<void> setPomodoroLongBreak(int minutes) async {
    _pomodoroLongBreak = minutes;
    await _service.setPomodoroLongBreak(minutes);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _service.setSoundEnabled(value);
    notifyListeners();
  }
}
