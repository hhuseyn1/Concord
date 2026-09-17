import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';

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
