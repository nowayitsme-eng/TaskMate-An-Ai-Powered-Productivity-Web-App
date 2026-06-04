import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences to local storage using SharedPreferences.
class SettingsService {
  static const _keyPomodoroWork = 'pref_pomodoro_work';
  static const _keyPomodoroBreak = 'pref_pomodoro_break';
  static const _keyPomodoroLongBreak = 'pref_pomodoro_long_break';
  static const _keySoundEnabled = 'pref_sound_enabled';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ─── Theme removed ───

  // ─── Pomodoro ──────────────────────────────────────────────────────────────

  Future<int> getPomodoroWork() async =>
      (await _prefs).getInt(_keyPomodoroWork) ?? 25;
  Future<void> setPomodoroWork(int minutes) async =>
      (await _prefs).setInt(_keyPomodoroWork, minutes);

  Future<int> getPomodoroBreak() async =>
      (await _prefs).getInt(_keyPomodoroBreak) ?? 5;
  Future<void> setPomodoroBreak(int minutes) async =>
      (await _prefs).setInt(_keyPomodoroBreak, minutes);

  Future<int> getPomodoroLongBreak() async =>
      (await _prefs).getInt(_keyPomodoroLongBreak) ?? 15;
  Future<void> setPomodoroLongBreak(int minutes) async =>
      (await _prefs).setInt(_keyPomodoroLongBreak, minutes);

  // ─── Sound ─────────────────────────────────────────────────────────────────

  Future<bool> getSoundEnabled() async =>
      (await _prefs).getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async =>
      (await _prefs).setBool(_keySoundEnabled, value);
}
