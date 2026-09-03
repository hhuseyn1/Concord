import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'auth_errors.dart';
import 'auth_layout.dart';

class TwoFactorChallenge extends ConsumerStatefulWidget {
  const TwoFactorChallenge({super.key, required this.twoFactorToken, required this.onCancel});

  final String twoFactorToken;

  final VoidCallback onCancel;

  @override
  ConsumerState<TwoFactorChallenge> createState() => _TwoFactorChallengeState();
}

class _TwoFactorChallengeState extends ConsumerState<TwoFactorChallenge> {
  final _codeController = TextEditingController();

  String? _codeError;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();

    setState(() {
      _codeError = code.isEmpty ? 'Enter your authentication code' : null;
      _formError = null;
    });
    if (_codeError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeTwoFactorLogin(twoFactorToken: widget.twoFactorToken, code: code);
    } on ApiException catch (error) {
      setState(() => _formError = mapTwoFactorLoginError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return ConcordAuthLayout(
      title: 'Two-factor authentication',
      subtitle: 'Enter the code from your authenticator app, or one of your recovery codes.',
      footer: GestureDetector(
        onTap: widget.onCancel,
        child: Text(
          'Back to sign in',
          style: TextStyle(color: colors.brand, fontWeight: FontWeight.w500),
        ),
      ),
      children: [
        ConcordTextField(
          controller: _codeController,
          label: 'Authentication code',
          hint: '123456 or ABCD-EFGH',
          required: true,
          errorText: _codeError,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
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
            child: Text(_formError!, style: TextStyle(color: colors.danger, fontSize: 13)),
          ),
        ],
        const SizedBox(height: ConcordSpacing.xl - 4),
        ConcordButton(
          label: _isSubmitting ? 'Verifying…' : 'Verify',
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
