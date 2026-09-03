import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'auth_errors.dart';
import 'auth_layout.dart';
import 'two_factor_challenge.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isSubmitting = false;

  String? _twoFactorToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;
      _formError = null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(email: email, password: password);
    } on ApiException catch (error) {
      if (error.isTwoFactorRequired) {
        setState(() => _twoFactorToken = error.twoFactorToken);
      } else {
        setState(() => _formError = mapLoginError(error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final twoFactorToken = _twoFactorToken;
    if (twoFactorToken != null) {
      return TwoFactorChallenge(
        twoFactorToken: twoFactorToken,
        onCancel: () => setState(() => _twoFactorToken = null),
      );
    }

    final colors = Theme.of(context).extension<ConcordColors>()!;

    return ConcordAuthLayout(
      title: 'Welcome back',
      subtitle: "We're excited to see you again.",
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text('Need an account? '),
          GestureDetector(
            onTap: () => context.go('/register'),
            child: Text(
              'Register',
              style: TextStyle(color: colors.brand, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      children: [
        ConcordTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          required: true,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          required: true,
          errorText: _passwordError,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
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
          label: _isSubmitting ? 'Logging in…' : 'Log In',
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
