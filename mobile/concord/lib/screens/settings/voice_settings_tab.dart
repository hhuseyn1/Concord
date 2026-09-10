import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

class VoiceSettingsTab extends StatelessWidget {
  const VoiceSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        Text(l10n.voiceVideoTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.md),
        Container(
          padding: const EdgeInsets.all(ConcordSpacing.md),
          decoration: BoxDecoration(
            color: colors.infoBg,
            borderRadius: BorderRadius.circular(ConcordRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colors.info, size: 18),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: Text(
                  l10n.voiceInfoText,
                  style: textTheme.bodyMedium?.copyWith(color: colors.fgDefault),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConcordSpacing.lg),
        Text(
          l10n.voiceNoAudioHint,
          style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
        ),
      ],
    );
  }
}
