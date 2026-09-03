import 'package:flutter/material.dart';

import '../../api/models/enums.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class IncomingCallModal extends StatelessWidget {
  const IncomingCallModal({
    super.key,
    required this.callerName,
    required this.callerAvatarUrl,
    required this.type,
    required this.onAccept,
    required this.onDecline,
  });

  final String? callerName;
  final String? callerAvatarUrl;
  final CallType type;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isVideo = type == CallType.video;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(ConcordSpacing.xl),
          padding: const EdgeInsets.all(ConcordSpacing.xl),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: colors.surfaceBase,
            borderRadius: BorderRadius.circular(ConcordRadii.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVideo ? 'Incoming video call' : 'Incoming voice call',
                style: textTheme.titleMedium?.copyWith(color: colors.fgHeading),
              ),
              const SizedBox(height: ConcordSpacing.lg),
              ConcordAvatar(imageUrl: callerAvatarUrl, name: callerName, size: ConcordAvatarSize.xl),
              const SizedBox(height: ConcordSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isVideo ? Icons.videocam_outlined : Icons.call_outlined, size: 16, color: colors.fgMuted),
                  const SizedBox(width: ConcordSpacing.xs),
                  Text(
                    callerName?.isNotEmpty == true ? callerName! : 'Someone',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colors.fgDefault),
                  ),
                ],
              ),
              const SizedBox(height: ConcordSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: ConcordButton(
                      label: 'Decline',
                      variant: ConcordButtonVariant.danger,
                      leading: const Icon(Icons.call_end, size: 16),
                      expand: true,
                      onPressed: onDecline,
                    ),
                  ),
                  const SizedBox(width: ConcordSpacing.md),
                  Expanded(
                    child: ConcordButton(
                      label: 'Accept',
                      leading: const Icon(Icons.call, size: 16),
                      expand: true,
                      onPressed: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
