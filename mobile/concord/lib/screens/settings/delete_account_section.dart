import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// "Danger Zone" section at the bottom of Settings: soft-deletes the current
/// account via `UsersService.deleteMe` (30-day grace period - logging back
/// in before then cancels the deletion; see `_DeleteAccountDialog`).
/// Styled distinctly from the rest of Settings using the danger color
/// tokens so it reads as irreversible/high-consequence, mirroring the web
/// app's `DeleteAccountSection`.
class DeleteAccountSection extends StatelessWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        color: colors.dangerBg,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dangerZoneTitle, style: textTheme.titleMedium?.copyWith(color: colors.danger)),
          const SizedBox(height: 4),
          Text(
            l10n.deleteAccountSectionDescription,
            style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordButton(
            label: l10n.deleteAccountButton,
            variant: ConcordButtonVariant.danger,
            size: ConcordButtonSize.sm,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => const _DeleteAccountDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      setState(() => _error = l10n.currentPasswordRequired);
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(usersServiceProvider).deleteMe(password: _passwordController.text);
      if (!mounted) return;

      // The account is already deactivated/logged-out server-side at this
      // point; capture what we need before popping (this dialog's context
      // becomes unusable once its route starts closing).
      final messenger = ScaffoldMessenger.of(context);
      final authNotifier = ref.read(authControllerProvider.notifier);

      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountSuccessSnackbar)));
      // Reuses the existing logout mechanism to clear local tokens/state -
      // the router's auth-state-driven redirect then takes over and sends
      // the user to /login. `revokeCurrentSession` (called internally by
      // `logout`) is expected to no-op/fail harmlessly since the server
      // already revoked every session as part of deleting the account.
      await authNotifier.logout();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isUnauthorized
            ? l10n.deleteAccountIncorrectPasswordError
            : (e.message.isNotEmpty ? e.message : l10n.deleteAccountFailedError);
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountConsequencesMessage),
            const SizedBox(height: ConcordSpacing.md),
            ConcordTextField(
              controller: _passwordController,
              label: l10n.deleteAccountPasswordLabel,
              obscureText: true,
              required: true,
              enabled: !_submitting,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submitting ? null : _confirm(),
            ),
            if (_error != null) ...[
              const SizedBox(height: ConcordSpacing.sm),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          ConcordButton(
            label: l10n.deleteAccountConfirmButton,
            variant: ConcordButtonVariant.danger,
            size: ConcordButtonSize.sm,
            loading: _submitting,
            onPressed: _submitting ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
