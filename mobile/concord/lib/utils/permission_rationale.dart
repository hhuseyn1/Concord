import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/theme.dart';

/// Requests [permission], showing a short "why we need this" explanation
/// first if it hasn't already been granted - the OS prompt alone never says
/// what the permission is for, and Android's permanently-denied state means
/// re-requesting silently would just get ignored forever.
///
/// Returns true once [permission] is granted (immediately, if it already
/// was), false if the user declines the rationale or the OS request.
Future<bool> requestPermissionWithRationale(
  BuildContext context, {
  required Permission permission,
  required String title,
  required String rationale,
}) async {
  var status = await permission.status;
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text('$rationale\n\nYou previously denied this, so it needs to be turned on from system settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Open settings')),
        ],
      ),
    );
    if (openSettings == true) await openAppSettings();
    return false;
  }

  if (!context.mounted) return false;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).extension<ConcordColors>()!;
      return AlertDialog(
        title: Text(title),
        content: Text(rationale),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Not now')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.brand),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
  if (proceed != true) return false;

  status = await permission.request();
  return status.isGranted;
}
