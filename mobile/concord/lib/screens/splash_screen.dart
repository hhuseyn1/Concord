import 'package:flutter/material.dart';

import '../theme/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    return Scaffold(
      backgroundColor: colors.surfaceRail,
      body: Center(
        child: CircularProgressIndicator(color: colors.brand),
      ),
    );
  }
}
