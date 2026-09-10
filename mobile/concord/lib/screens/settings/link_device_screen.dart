import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
import '../../utils/permission_rationale.dart';
import '../../widgets/widgets.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  final _codeController = TextEditingController();
  MobileScannerController? _scannerController;

  bool _showManualEntry = false;
  bool _scanPaused = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  QrLoginRequestInfoResponse? _request;

  /// Null until the camera-permission rationale flow has run once.
  bool? _cameraGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCameraAccess());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraAccess() async {
    final l10n = AppLocalizations.of(context);
    final granted = await requestPermissionWithRationale(
      context,
      permission: Permission.camera,
      title: l10n.cameraAccessTitle,
      rationale: l10n.cameraAccessRationale,
    );
    if (mounted) setState(() => _cameraGranted = granted);
  }

  QrLoginService get _qrLoginService => ref.read(qrLoginServiceProvider);

  String _extractUserCode(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    final fromQuery = uri?.queryParameters['code'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return rawValue;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanPaused || _loading) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _scanPaused = true);
    await _lookup(_extractUserCode(rawValue));
  }

  Future<void> _lookup(String rawCode) async {
    final l10n = AppLocalizations.of(context);
    final code = rawCode.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final request = await _qrLoginService.getRequestInfo(code);
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isNotFound
            ? l10n.codeInvalidOrExpired
            : (e.message.isNotEmpty ? e.message : l10n.couldNotLookUpCode);
        _loading = false;
        _scanPaused = false;
      });
    }
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    final request = _request;
    if (request == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _qrLoginService.approve(request.userCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deviceApprovedSnackbar)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isNotEmpty ? e.message : l10n.errorApproveDeviceFailed;
        _submitting = false;
      });
    }
  }

  Future<void> _deny() async {
    final l10n = AppLocalizations.of(context);
    final request = _request;
    if (request == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _qrLoginService.deny(request.userCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.signInRequestDeniedSnackbar)));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isNotEmpty ? e.message : l10n.errorDenyDeviceFailed;
        _submitting = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _request = null;
      _error = null;
      _scanPaused = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkDeviceTitle)),
      body: Padding(
        padding: const EdgeInsets.all(ConcordSpacing.lg),
        child: _request != null
            ? _buildRequestReview(colors, textTheme, l10n)
            : _buildScanOrEnter(colors, textTheme, l10n),
      ),
    );
  }

  Widget _buildScanOrEnter(ConcordColors colors, TextTheme textTheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.linkDeviceInstructions,
          style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
        ),
        const SizedBox(height: ConcordSpacing.lg),
        if (!_showManualEntry) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              child: _cameraGranted != true
                  ? ColoredBox(
                      color: colors.surfaceSidebar,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(ConcordSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _cameraGranted == null
                                    ? l10n.requestingCameraAccess
                                    : l10n.cameraAccessNeeded,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.fgMuted),
                              ),
                              if (_cameraGranted == false) ...[
                                const SizedBox(height: ConcordSpacing.md),
                                ConcordButton(
                                  label: l10n.tryAgainButton,
                                  variant: ConcordButtonVariant.secondary,
                                  onPressed: _requestCameraAccess,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController ??= MobileScannerController(),
                          onDetect: _onDetect,
                          errorBuilder: (context, error) => ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(ConcordSpacing.lg),
                                child: Text(
                                  l10n.errorCameraAccessFailed(error.errorDetails?.message ?? error.errorCode.name),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_loading)
                          const ColoredBox(
                            color: Colors.black45,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordButton(
            label: l10n.enterCodeManuallyButton,
            variant: ConcordButtonVariant.secondary,
            expand: true,
            onPressed: () => setState(() => _showManualEntry = true),
          ),
        ] else ...[
          ConcordTextField(
            controller: _codeController,
            label: l10n.deviceCodeLabel,
            hint: l10n.deviceCodeHint,
            required: true,
            enabled: !_loading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _lookup(_codeController.text),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordButton(
            label: l10n.continueButton,
            expand: true,
            loading: _loading,
            onPressed: _loading ? null : () => _lookup(_codeController.text),
          ),
          const SizedBox(height: ConcordSpacing.sm),
          ConcordButton(
            label: l10n.scanQrInsteadButton,
            variant: ConcordButtonVariant.ghost,
            expand: true,
            onPressed: () => setState(() => _showManualEntry = false),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: ConcordSpacing.md),
          Text(_error!, style: TextStyle(color: colors.danger)),
        ],
      ],
    );
  }

  Widget _buildRequestReview(ConcordColors colors, TextTheme textTheme, AppLocalizations l10n) {
    final request = _request!;
    final deviceLabel = request.deviceLabel?.isNotEmpty == true ? request.deviceLabel! : l10n.unknownDeviceLabel;
    final browserOs = [request.browser, request.os].where((p) => p != null && p.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(ConcordSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceSidebar,
            borderRadius: BorderRadius.circular(ConcordRadii.md),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.devices_other, color: colors.fgMuted),
              const SizedBox(width: ConcordSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceLabel, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    if (browserOs.isNotEmpty)
                      Text(browserOs, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
                    if (request.ipAddress != null)
                      Text(request.ipAddress!, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConcordSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
          decoration: BoxDecoration(
            color: colors.warningBg,
            borderRadius: BorderRadius.circular(ConcordRadii.md),
            border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
          ),
          child: Text(
            l10n.approveDeviceWarning,
            style: TextStyle(color: colors.warning, fontSize: 13),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: ConcordSpacing.md),
          Text(_error!, style: TextStyle(color: colors.danger)),
        ],
        const SizedBox(height: ConcordSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ConcordButton(
                label: l10n.approveButton,
                loading: _submitting,
                onPressed: _submitting ? null : _approve,
              ),
            ),
            const SizedBox(width: ConcordSpacing.sm),
            Expanded(
              child: ConcordButton(
                label: l10n.denyButton,
                variant: ConcordButtonVariant.danger,
                onPressed: _submitting ? null : _deny,
              ),
            ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.sm),
        ConcordButton(
          label: l10n.cancelButton,
          variant: ConcordButtonVariant.ghost,
          expand: true,
          onPressed: _submitting ? null : _reset,
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
