import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _surnameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _surnameError = surname.isEmpty ? 'Surname is required' : null;
      _emailError = email.isEmpty
          ? 'Email is required'
          : (!email.contains('@') ? 'Enter a valid email address' : null);
      _passwordError = password.isEmpty
          ? 'Password is required'
          : (password.length < 8 ? 'Password must be at least 8 characters' : null);
      _formError = null;
    });
    if (_nameError != null || _surnameError != null || _emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(name: name, surname: surname, email: email, password: password);
    } on ApiException catch (error) {
      setState(() => _formError = mapRegisterError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return ConcordAuthLayout(
      title: 'Create an account',
      subtitle: 'Join Concord and start chatting.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text('Already have an account? '),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Log In',
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
                label: 'Name',
                hint: 'Jane',
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
                label: 'Surname',
                hint: 'Doe',
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
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
        ),
        if (_passwordError == null) ...[
          const SizedBox(height: 4),
          Text('At least 8 characters.', style: TextStyle(fontSize: 12, color: colors.fgMuted)),
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
            child: Text(_formError!, style: TextStyle(color: colors.danger, fontSize: 13)),
          ),
        ],
        const SizedBox(height: ConcordSpacing.xl - 4),
        ConcordButton(
          label: _isSubmitting ? 'Creating account…' : 'Create Account',
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
