import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ChangePasswordSection extends ConsumerStatefulWidget {
  const ChangePasswordSection({super.key});

  @override
  ConsumerState<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends ConsumerState<ChangePasswordSection> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _success = false;
    });

    if (_currentController.text.isEmpty) {
      setState(() => _error = l10n.currentPasswordRequired);
      return;
    }
    if (_newController.text.length < 8) {
      setState(() => _error = l10n.newPasswordTooShort);
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = l10n.validationPasswordsDontMatch);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(currentPassword: _currentController.text, newPassword: _newController.text);
      if (!mounted) return;
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      setState(() => _success = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.changePasswordTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.md),
        ConcordTextField(
          controller: _currentController,
          label: l10n.currentPasswordLabel,
          obscureText: true,
          required: true,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: ConcordSpacing.md),
        ConcordTextField(
          controller: _newController,
          label: l10n.fieldNewPasswordLabel,
          hint: l10n.passwordMinCharactersHint,
          obscureText: true,
          required: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: ConcordSpacing.md),
        ConcordTextField(
          controller: _confirmController,
          label: l10n.fieldConfirmNewPasswordLabel,
          obscureText: true,
          required: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        if (_error != null) ...[
          const SizedBox(height: ConcordSpacing.sm),
          Text(_error!, style: TextStyle(color: colors.danger)),
        ],
        if (_success) ...[
          const SizedBox(height: ConcordSpacing.sm),
          Text(
            l10n.passwordChangedNotice,
            style: TextStyle(color: colors.success),
          ),
        ],
        const SizedBox(height: ConcordSpacing.md),
        ConcordButton(label: l10n.changePasswordTitle, loading: _saving, onPressed: _saving ? null : _submit),
      ],
    );
  }
}
