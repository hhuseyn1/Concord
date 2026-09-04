import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../theme/theme.dart';
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

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
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
            ? 'That code is invalid or has expired.'
            : (e.message.isNotEmpty ? e.message : "Couldn't look up that code.");
        _loading = false;
        _scanPaused = false;
      });
    }
  }

  Future<void> _approve() async {
    final request = _request;
    if (request == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _qrLoginService.approve(request.userCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device approved.')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isNotEmpty ? e.message : 'Could not approve that device.';
        _submitting = false;
      });
    }
  }

  Future<void> _deny() async {
    final request = _request;
    if (request == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _qrLoginService.deny(request.userCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in request denied.')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isNotEmpty ? e.message : 'Could not deny that device.';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Link a Device')),
      body: Padding(
        padding: const EdgeInsets.all(ConcordSpacing.lg),
        child: _request != null
            ? _buildRequestReview(colors, textTheme)
            : _buildScanOrEnter(colors, textTheme),
      ),
    );
  }

  Widget _buildScanOrEnter(ConcordColors colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan the QR code shown on the device you want to sign in, or enter its code below.',
          style: textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
        ),
        const SizedBox(height: ConcordSpacing.lg),
        if (!_showManualEntry) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ConcordRadii.md),
              child: Stack(
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
                            'Could not access the camera: ${error.errorDetails?.message ?? error.errorCode.name}',
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
            label: 'Enter code manually',
            variant: ConcordButtonVariant.secondary,
            expand: true,
            onPressed: () => setState(() => _showManualEntry = true),
          ),
        ] else ...[
          ConcordTextField(
            controller: _codeController,
            label: 'Device code',
            hint: 'ABCD1234',
            required: true,
            enabled: !_loading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _lookup(_codeController.text),
          ),
          const SizedBox(height: ConcordSpacing.md),
          ConcordButton(
            label: 'Continue',
            expand: true,
            loading: _loading,
            onPressed: _loading ? null : () => _lookup(_codeController.text),
          ),
          const SizedBox(height: ConcordSpacing.sm),
          ConcordButton(
            label: 'Scan a QR code instead',
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

  Widget _buildRequestReview(ConcordColors colors, TextTheme textTheme) {
    final request = _request!;
    final deviceLabel = request.deviceLabel?.isNotEmpty == true ? request.deviceLabel! : 'Unknown device';
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
            'Only approve this if you just started signing in on the device shown above.',
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
                label: 'Approve',
                loading: _submitting,
                onPressed: _submitting ? null : _approve,
              ),
            ),
            const SizedBox(width: ConcordSpacing.sm),
            Expanded(
              child: ConcordButton(
                label: 'Deny',
                variant: ConcordButtonVariant.danger,
                onPressed: _submitting ? null : _deny,
              ),
            ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.sm),
        ConcordButton(
          label: 'Cancel',
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
