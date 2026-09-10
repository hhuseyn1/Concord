import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class TwoFactorSection extends ConsumerStatefulWidget {
  const TwoFactorSection({super.key});

  @override
  ConsumerState<TwoFactorSection> createState() => _TwoFactorSectionState();
}

class _TwoFactorSectionState extends ConsumerState<TwoFactorSection> {
  final _confirmCodeController = TextEditingController();

  bool _loadingStatus = true;
  TwoFactorStatusResponse? _status;
  String? _loadError;

  TwoFactorSetupResponse? _setup;
  bool _startingSetup = false;
  bool _confirming = false;
  String? _setupError;

  List<String>? _recoveryCodes;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _confirmCodeController.dispose();
    super.dispose();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _loadError = null;
    });
    try {
      final status = await _authService.getTwoFactorStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loadingStatus = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadingStatus = false;
      });
    }
  }

  Future<void> _startSetup() async {
    setState(() {
      _startingSetup = true;
      _setupError = null;
    });
    try {
      final setup = await _authService.startTwoFactorSetup();
      if (!mounted) return;
      setState(() => _setup = setup);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _setupError = e.message.isNotEmpty ? e.message : AppLocalizations.of(context).errorStartTwoFactorFailed);
    } finally {
      if (mounted) setState(() => _startingSetup = false);
    }
  }

  void _cancelSetup() {
    setState(() {
      _setup = null;
      _setupError = null;
      _confirmCodeController.clear();
    });
  }

  Future<void> _confirmSetup() async {
    final l10n = AppLocalizations.of(context);
    final code = _confirmCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _setupError = l10n.enterAuthCodeMessage);
      return;
    }
    setState(() {
      _confirming = true;
      _setupError = null;
    });
    try {
      final result = await _authService.enableTwoFactor(code: code);
      if (!mounted) return;
      setState(() {
        _setup = null;
        _confirmCodeController.clear();
        _recoveryCodes = result.codes;
      });
      await _loadStatus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _setupError = e.message.isNotEmpty ? e.message : l10n.twoFactorConfirmCodeFailed);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _openDisableDialog() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_PasswordAndCode>(
      context: context,
      builder: (context) => const _DisableTwoFactorDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await _authService.disableTwoFactor(password: result.password, code: result.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.twoFactorDisabledSnackbar)),
      );
      await _loadStatus();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : l10n.errorDisableTwoFactorFailed)),
      );
    }
  }

  Future<void> _openRegenerateDialog() async {
    final l10n = AppLocalizations.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (context) => _PasswordOnlyDialog(
        title: l10n.regenerateRecoveryCodesTitle,
        description: l10n.regenerateRecoveryCodesDescription,
        confirmLabel: l10n.regenerateButton,
      ),
    );
    if (password == null || !mounted) return;
    try {
      final result = await _authService.regenerateRecoveryCodes(password: password);
      if (!mounted) return;
      setState(() => _recoveryCodes = result.codes);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : l10n.errorRegenerateCodesFailed)),
      );
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
        Text(l10n.twoFactorSectionTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.md),
        if (_loadingStatus)
          const Center(child: CircularProgressIndicator())
        else if (_loadError != null)
          ConcordEmptyState(
            icon: Icons.error_outline,
            title: l10n.couldNotLoadTwoFactorStatus,
            subtitle: _loadError,
            compact: true,
            action: ConcordButton(
              label: l10n.tryAgainButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: _loadStatus,
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _status!.enabled ? Icons.verified_user : Icons.gpp_maybe_outlined,
                color: _status!.enabled ? colors.success : colors.fgMuted,
              ),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: Text(
                  _status!.enabled ? l10n.twoFactorOnDescription : l10n.twoFactorOffDescription,
                  style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                ),
              ),
            ],
          ),
          if (_status!.enabled) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(
              l10n.recoveryCodesRemaining(_status!.remainingRecoveryCodes),
              style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
            ),
          ],
          const SizedBox(height: ConcordSpacing.md),
          if (!_status!.enabled && _setup == null)
            ConcordButton(
              label: l10n.enableTwoFactorButton,
              size: ConcordButtonSize.sm,
              loading: _startingSetup,
              onPressed: _startingSetup ? null : _startSetup,
            ),
          if (_setup != null) _buildSetupPanel(colors, textTheme, l10n),
          if (_status!.enabled)
            Row(
              children: [
                ConcordButton(
                  label: l10n.regenerateRecoveryCodesTitle,
                  variant: ConcordButtonVariant.secondary,
                  size: ConcordButtonSize.sm,
                  onPressed: _openRegenerateDialog,
                ),
                const SizedBox(width: ConcordSpacing.sm),
                ConcordButton(
                  label: l10n.disableButton,
                  variant: ConcordButtonVariant.danger,
                  size: ConcordButtonSize.sm,
                  onPressed: _openDisableDialog,
                ),
              ],
            ),
        ],
        if (_recoveryCodes != null) ...[
          const SizedBox(height: ConcordSpacing.md),
          _RecoveryCodesPanel(
            codes: _recoveryCodes!,
            onDone: () => setState(() => _recoveryCodes = null),
          ),
        ],
      ],
    );
  }

  Widget _buildSetupPanel(ConcordColors colors, TextTheme textTheme, AppLocalizations l10n) {
    Uint8List? svgBytes;
    final qrCodeSvg = _setup!.qrCodeSvg;
    if (qrCodeSvg != null) {
      final commaIndex = qrCodeSvg.indexOf(',');
      if (commaIndex != -1) {
        try {
          svgBytes = base64Decode(qrCodeSvg.substring(commaIndex + 1));
        } catch (_) {
          svgBytes = null;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: ConcordSpacing.md),
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.scanQrWithAuthenticator, style: textTheme.bodyMedium),
          const SizedBox(height: ConcordSpacing.md),
          if (svgBytes != null)
            Container(
              padding: const EdgeInsets.all(ConcordSpacing.sm),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(ConcordRadii.md)),
              child: SvgPicture.memory(svgBytes, width: 176, height: 176),
            )
          else
            Text(l10n.couldNotRenderQr, style: textTheme.bodySmall?.copyWith(color: colors.danger)),
          const SizedBox(height: ConcordSpacing.md),
          Text(l10n.enterKeyManually, style: textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(
            _setup!.secretKey ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordTextField(
            controller: _confirmCodeController,
            label: l10n.confirmationCodeLabel,
            hint: l10n.confirmationCodeHint,
            required: true,
            errorText: _setupError,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => _confirmSetup(),
          ),
          const SizedBox(height: ConcordSpacing.md),
          Row(
            children: [
              ConcordButton(
                label: l10n.confirmButton,
                size: ConcordButtonSize.sm,
                loading: _confirming,
                onPressed: _confirming ? null : _confirmSetup,
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: l10n.cancelButton,
                variant: ConcordButtonVariant.ghost,
                size: ConcordButtonSize.sm,
                onPressed: _confirming ? null : _cancelSetup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecoveryCodesPanel extends StatefulWidget {
  const _RecoveryCodesPanel({required this.codes, required this.onDone});

  final List<String> codes;
  final VoidCallback onDone;

  @override
  State<_RecoveryCodesPanel> createState() => _RecoveryCodesPanelState();
}

class _RecoveryCodesPanelState extends State<_RecoveryCodesPanel> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.codes.join('\n')));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(ConcordSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(ConcordRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.saveRecoveryCodesTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: ConcordSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
            decoration: BoxDecoration(
              color: colors.warningBg,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
            ),
            child: Text(
              l10n.recoveryCodesWarning,
              style: TextStyle(color: colors.warning, fontSize: 13),
            ),
          ),
          const SizedBox(height: ConcordSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ConcordSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceSidebar,
              borderRadius: BorderRadius.circular(ConcordRadii.md),
            ),
            child: Wrap(
              spacing: ConcordSpacing.md,
              runSpacing: 4,
              children: [
                for (final code in widget.codes)
                  SizedBox(
                    width: 130,
                    child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ConcordSpacing.md),
          Row(
            children: [
              ConcordButton(
                label: _copied ? l10n.copiedLabel : l10n.copyCodesButton,
                variant: ConcordButtonVariant.secondary,
                size: ConcordButtonSize.sm,
                leading: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                onPressed: _copy,
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: l10n.savedCodesButton,
                size: ConcordButtonSize.sm,
                onPressed: widget.onDone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordAndCode {
  const _PasswordAndCode(this.password, this.code);

  final String password;
  final String code;
}

class _DisableTwoFactorDialog extends StatefulWidget {
  const _DisableTwoFactorDialog();

  @override
  State<_DisableTwoFactorDialog> createState() => _DisableTwoFactorDialogState();
}

class _DisableTwoFactorDialogState extends State<_DisableTwoFactorDialog> {
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      setState(() => _error = l10n.enterPasswordMessage);
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = l10n.enterCurrentOrRecoveryCodeMessage);
      return;
    }
    Navigator.of(context).pop(_PasswordAndCode(_passwordController.text, _codeController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.disableTwoFactorDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.disableTwoFactorDialogMessage),
          const SizedBox(height: ConcordSpacing.md),
          ConcordTextField(
            controller: _passwordController,
            label: l10n.passwordLabel,
            obscureText: true,
            required: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordTextField(
            controller: _codeController,
            label: l10n.authOrRecoveryCodeLabel,
            required: true,
            autofillHints: const [AutofillHints.oneTimeCode],
          ),
          if (_error != null) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(_error!, style: TextStyle(color: colors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _submit, child: Text(l10n.disableButton)),
      ],
    );
  }
}

class _PasswordOnlyDialog extends StatefulWidget {
  const _PasswordOnlyDialog({required this.title, required this.description, required this.confirmLabel});

  final String title;
  final String description;
  final String confirmLabel;

  @override
  State<_PasswordOnlyDialog> createState() => _PasswordOnlyDialogState();
}

class _PasswordOnlyDialogState extends State<_PasswordOnlyDialog> {
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterPasswordMessage);
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: ConcordSpacing.md),
          ConcordTextField(
            controller: _passwordController,
            label: l10n.passwordLabel,
            obscureText: true,
            required: true,
            autofillHints: const [AutofillHints.password],
          ),
          if (_error != null) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(_error!, style: TextStyle(color: colors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
