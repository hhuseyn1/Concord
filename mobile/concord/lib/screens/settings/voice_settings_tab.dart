import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class VoiceSettingsTab extends StatelessWidget {
  const VoiceSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        Text('Voice & Video', style: textTheme.titleMedium),
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
                  "Concord will ask for microphone access the first time you join a call, and camera "
                  "access the first time you turn your camera on. There's no separate device picker on "
                  'mobile - audio output (earpiece/speaker/Bluetooth) is controlled by your device, not '
                  'this app.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.fgDefault),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConcordSpacing.lg),
        Text(
          'If a call connects with no audio, check your device Settings app for Concord\'s microphone '
          'permission.',
          style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
        ),
      ],
    );
  }
}
