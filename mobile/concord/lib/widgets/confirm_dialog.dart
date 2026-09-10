import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// Shared confirm dialog for actions that need an explicit "are you sure"
/// step (leave server, delete channel/message, unblock user, cancel a
/// friend request, revoke a session, etc.). Mirrors the pattern already used
/// by `ChannelListScreen._confirmLeaveServer`, extracted here so every call
/// site gets the same destructive styling and haptic feedback for free.
///
/// Returns `true` if the user confirmed, `false`/`null` if they backed out.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
}) {
  final resolvedCancelLabel = cancelLabel ?? AppLocalizations.of(context).cancelButton;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).extension<ConcordColors>()!;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(resolvedCancelLabel),
          ),
          TextButton(
            style: isDestructive ? ConcordTheme.destructiveTextButtonStyle(colors) : null,
            onPressed: () {
              if (isDestructive) unawaited(HapticFeedback.mediumImpact());
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
