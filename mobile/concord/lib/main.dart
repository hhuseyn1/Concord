import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  runApp(const ProviderScope(child: ConcordApp()));
}

class ConcordApp extends ConsumerWidget {
  const ConcordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Concord',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ConcordTheme.light(),
      darkTheme: ConcordTheme.dark(),
      routerConfig: router,
      builder: (context, child) =>
          AppSessionOverlay(child: VoiceCallOverlay(child: child ?? const SizedBox.shrink())),
    );
  }
}
