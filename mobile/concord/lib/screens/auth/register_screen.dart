import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../utils/username_policy.dart';
import '../../widgets/widgets.dart';
import 'auth_errors.dart';
import 'auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _surnameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isSubmitting = false;

  bool _registered = false;
  String? _registeredEmail;
  bool _isResending = false;
  String? _resendMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _nameError = name.isEmpty ? l10n.validationNameRequired : null;
      _surnameError = surname.isEmpty ? l10n.validationSurnameRequired : null;
      _usernameError = username.isEmpty
          ? l10n.usernameRequiredPeriod
          : (!usernamePattern.hasMatch(username) ? l10n.usernameInvalidFormat : null);
      _emailError = email.isEmpty
          ? l10n.validationEmailRequired
          : (!email.contains('@') ? l10n.validationEmailInvalid : null);
      _passwordError = password.isEmpty
          ? l10n.validationPasswordRequired
          : (password.length < 8 ? l10n.validationPasswordMinLength : null);
      _formError = null;
    });
    if (_nameError != null ||
        _surnameError != null ||
        _usernameError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
        name: name,
        surname: surname,
        username: username,
        email: email,
        password: password,
      );
      setState(() {
        _registered = true;
        _registeredEmail = email;
      });
    } on ApiException catch (error) {
      setState(() => _formError = mapRegisterError(l10n, error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final email = _registeredEmail;
    if (email == null || _isResending) return;
    setState(() {
      _isResending = true;
      _resendMessage = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail(email: email);
      if (mounted) setState(() => _resendMessage = l10n.registerResendMessageSent);
    } on ApiException {
      if (mounted) setState(() => _resendMessage = l10n.registerResendMessageFailed);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);

    if (_registered) {
      return ConcordAuthLayout(
        title: l10n.registerCheckEmailTitle,
        subtitle: l10n.registerCheckEmailSubtitle(_registeredEmail ?? l10n.registerCheckEmailFallbackEmail),
        footer: Wrap(
          alignment: WrapAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                l10n.backToLoginButton,
                style: TextStyle(color: colors.brand, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        children: [
          if (_resendMessage != null) ...[
            Text(_resendMessage!, style: TextStyle(color: colors.fgMuted, fontSize: type.size(13))),
            const SizedBox(height: ConcordSpacing.md),
          ],
          ConcordButton(
            label: _isResending ? l10n.registerResendButtonLoading : l10n.registerResendButton,
            size: ConcordButtonSize.lg,
            expand: true,
            loading: _isResending,
            onPressed: _isResending ? null : _resend,
          ),
        ],
      );
    }

    return ConcordAuthLayout(
      title: l10n.registerCreateAccountTitle,
      subtitle: l10n.registerCreateAccountSubtitle,
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(l10n.registerAlreadyHaveAccount),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              l10n.loginLink,
              style: TextStyle(color: colors.brand, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ConcordTextField(
                controller: _nameController,
                label: l10n.fieldNameLabel,
                hint: l10n.fieldNameHint,
                required: true,
                errorText: _nameError,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
              ),
            ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: ConcordTextField(
                controller: _surnameController,
                label: l10n.fieldSurnameLabel,
                hint: l10n.fieldSurnameHint,
                required: true,
                errorText: _surnameError,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
              ),
            ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _usernameController,
          label: l10n.usernameLabel,
          hint: l10n.usernameHint,
          required: true,
          errorText: _usernameError,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _emailController,
          label: l10n.fieldEmailLabel,
          hint: l10n.fieldEmailHint,
          required: true,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _passwordController,
          label: l10n.fieldPasswordLabel,
          hint: '••••••••',
          required: true,
          errorText: _passwordError,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
        ),
        if (_passwordError == null) ...[
          const SizedBox(height: 4),
          Text(l10n.passwordMinCharactersHint, style: TextStyle(fontSize: type.size(12), color: colors.fgMuted)),
        ],
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
          label: _isSubmitting ? l10n.registerSubmitButtonLoading : l10n.registerSubmitButton,
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
