import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocaleCodes = ['en', 'az'];

const _prefsKey = 'concord.locale';

class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      state = Locale(saved);
      return;
    }

    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    state = Locale(supportedLocaleCodes.contains(deviceCode) ? deviceCode : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocaleCodes.contains(locale.languageCode)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController();
});
