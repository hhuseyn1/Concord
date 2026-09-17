import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'auth_layout.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _passwordError;
  String? _confirmError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    final password = _passwordController.text;
    final confirm = _confirmController.text;
    setState(() {
      _passwordError = password.length < 8 ? l10n.validationPasswordTooShortPeriod : null;
      _confirmError = confirm != password ? l10n.validationPasswordsDontMatch : null;
      _formError = null;
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).confirmPasswordReset(token: token, newPassword: password);
      if (!mounted) return;
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.isNotFound || e.isValidationError
            ? l10n.resetLinkExpiredError
            : (e.isConnectivityError
                ? l10n.errorCouldNotReachServer
                : (e.message.isNotEmpty
                    ? e.message
                    : (e.isServerError ? l10n.errorServerTrouble : l10n.errorSomethingWentWrong)));
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return ConcordAuthLayout(
        title: l10n.resetInvalidLinkTitle,
        subtitle: l10n.resetInvalidLinkSubtitle,
        children: [
          ConcordButton(
            label: l10n.backToLoginButton,
            expand: true,
            onPressed: () => context.go('/login'),
          ),
        ],
      );
    }

    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);

    return ConcordAuthLayout(
      title: l10n.resetPasswordTitle,
      subtitle: l10n.resetPasswordSubtitle,
      children: [
        ConcordTextField(
          controller: _passwordController,
          label: l10n.fieldNewPasswordLabel,
          hint: l10n.passwordMinCharactersHint,
          obscureText: true,
          required: true,
          errorText: _passwordError,
          enabled: !_submitting,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _confirmController,
          label: l10n.fieldConfirmNewPasswordLabel,
          obscureText: true,
          required: true,
          errorText: _confirmError,
          enabled: !_submitting,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
        ),
        if (_formError != null) ...[
          const SizedBox(height: ConcordSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
            decoration: BoxDecoration(
              color: colors.dangerBg,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
            ),
            child: Text(_formError!, style: TextStyle(color: colors.danger, fontSize: type.size(13))),
          ),
        ],
        const SizedBox(height: ConcordSpacing.xl - 4),
        ConcordButton(
          label: _submitting ? l10n.resetPasswordButtonLoading : l10n.resetPasswordButton,
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
