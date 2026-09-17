import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'concord.themeMode';

/// Persists the user's Dark/Light/System theme choice across restarts via
/// [SharedPreferences] - same shape as `LocaleController`.
///
/// The default is [ThemeMode.system] rather than a hardcoded dark: until
/// someone makes an explicit choice, following the OS is both the least
/// surprising behaviour and the one that matches the web app's
/// `prefers-color-scheme` fallback. Once a choice is made it's stored verbatim
/// (`'light'`/`'dark'`/`'system'`) and wins from then on - including "System"
/// itself, which is a real, re-selectable choice and not just the absence of one.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final mode = _fromStorage(saved);
    if (mode != null) state = mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toStorage(mode));
  }

  static ThemeMode? _fromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };

  static String _toStorage(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

final themeModeControllerProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
