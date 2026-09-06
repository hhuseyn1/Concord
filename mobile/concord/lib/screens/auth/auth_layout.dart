import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

class ConcordAuthLayout extends StatelessWidget {
  const ConcordAuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surfaceRail,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ConcordSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Container(
                padding: const EdgeInsets.all(ConcordSpacing.xl),
                decoration: BoxDecoration(
                  color: colors.surfaceSidebar,
                  borderRadius: BorderRadius.circular(ConcordRadii.md),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 25, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.brand,
                            borderRadius: BorderRadius.circular(ConcordRadii.lg),
                          ),
                          child: SvgPicture.asset('assets/logo.svg', width: 28, height: 28),
                        ),
                        const SizedBox(height: ConcordSpacing.md),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: ConcordSpacing.xl),
                    ...children,
                    if (footer != null) ...[
                      const SizedBox(height: ConcordSpacing.xl),
                      DefaultTextStyle.merge(
                        style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
                        textAlign: TextAlign.center,
                        child: footer!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
