import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale codes the app ships translations for. Keep in sync with
/// `AppLocalizations.supportedLocales` (generated from `lib/l10n/*.arb`).
const supportedLocaleCodes = ['en', 'az'];

const _prefsKey = 'concord.locale';

/// Persists the user's chosen app locale (English/Azerbaijani) across
/// restarts via [SharedPreferences], defaulting to the device locale when
/// it's one we support and falling back to English otherwise.
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
