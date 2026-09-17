import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/font_scale_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'router/app_router.dart';
import 'screens/app_session_overlay.dart';
import 'screens/voice/voice_call_overlay.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // No background message handler is registered: the backend only ever sends a plain
  // `notification` payload (no `data`), which FCM's Android SDK renders as a system-tray
  // notification itself once the OS delivers it - that happens without invoking any Dart code, so
  // there's nothing for a background handler to do here (it's only needed to run custom logic on a
  // data-only or mixed payload).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ConcordApp()));
}

class ConcordApp extends ConsumerWidget {
  const ConcordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    // Both of these are persisted user preferences (Settings > My Account >
    // Appearance). Watching them here is what makes a change repaint the whole
    // app immediately, no restart and no per-screen plumbing.
    final themeMode = ref.watch(themeModeControllerProvider);
    final fontScale = ref.watch(fontScaleControllerProvider);

    return MaterialApp.router(
      title: 'Concord',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ConcordTheme.light(fontScale: fontScale),
      darkTheme: ConcordTheme.dark(fontScale: fontScale),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) =>
          AppSessionOverlay(child: VoiceCallOverlay(child: child ?? const SizedBox.shrink())),
    );
  }
}
