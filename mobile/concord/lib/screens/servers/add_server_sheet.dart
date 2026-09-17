import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

enum AddServerMode { create, join }

const _iconExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
const _iconExtensionToContentType = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
};

Future<void> showAddServerSheet(
  BuildContext context, {
  AddServerMode initialMode = AddServerMode.create,
  String? initialInviteCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddServerSheet(initialMode: initialMode, initialInviteCode: initialInviteCode),
  );
}

class _AddServerSheet extends StatefulWidget {
  const _AddServerSheet({this.initialMode = AddServerMode.create, this.initialInviteCode});

  final AddServerMode initialMode;
  final String? initialInviteCode;

  @override
  State<_AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<_AddServerSheet> {
  late AddServerMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addServerTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.addServerSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ConcordButton(
                  label: l10n.createTab,
                  expand: true,
                  variant: _mode == AddServerMode.create
                      ? ConcordButtonVariant.primary
                      : ConcordButtonVariant.secondary,
                  onPressed: () => setState(() => _mode = AddServerMode.create),
                ),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: ConcordButton(
                  label: l10n.joinTab,
                  expand: true,
                  variant: _mode == AddServerMode.join
                      ? ConcordButtonVariant.primary
                      : ConcordButtonVariant.secondary,
                  onPressed: () => setState(() => _mode = AddServerMode.join),
                ),
              ),
            ],
          ),
          const SizedBox(height: ConcordSpacing.lg),
          if (_mode == AddServerMode.create)
            const _CreateForm()
          else
            _JoinForm(initialCode: widget.initialInviteCode),
        ],
      ),
    );
  }
}

class _CreateForm extends ConsumerStatefulWidget {
  const _CreateForm();

  @override
  ConsumerState<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends ConsumerState<_CreateForm> {
  final _nameController = TextEditingController();
  String? _iconFilename;
  Uint8List? _iconBytes;
  String? _nameError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _iconExtensions);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _iconFilename = file.name;
      _iconBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.serverNameRequired : null;
      _formError = null;
    });
    if (_nameError != null) return;

    setState(() => _submitting = true);
    try {
      String? iconUrl;
      final iconFilename = _iconFilename;
      final iconBytes = _iconBytes;
      if (iconFilename != null && iconBytes != null) {
        final extension = iconFilename.contains('.') ? iconFilename.split('.').last.toLowerCase() : '';
        try {
          final uploaded = await ref.read(filesServiceProvider).uploadServerIcon(
                bytes: iconBytes,
                filename: iconFilename,
                contentType: _iconExtensionToContentType[extension],
              );
          iconUrl = uploaded.url;
        } on ApiException catch (e) {
          if (!mounted) return;
          setState(() => _formError = l10n.errorUploadIconFailed(e.message));
          return;
        }
      }

      final server = await ref.read(serversServiceProvider).createServer(name: name, iconUrl: iconUrl);
      ref.invalidate(myServersProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/servers/${server.id}');
    } on ApiException catch (e) {
      if (e.isValidationError) {
        setState(() => _nameError = e.message.isNotEmpty ? e.message : l10n.serverNameInvalid);
      } else {
        setState(() => _formError = e.message.isNotEmpty ? e.message : l10n.errorCreateServerFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _submitting ? null : _pickIcon,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceSidebar,
                  border: Border.all(color: colors.borderDefault, style: BorderStyle.solid),
                ),
                child: _iconBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _iconBytes!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.add_photo_alternate_outlined, color: colors.fgMuted),
              ),
            ),
            const SizedBox(width: ConcordSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.serverIconLabel, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    l10n.serverIconHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordTextField(
          controller: _nameController,
          label: l10n.serverNameLabel,
          hint: l10n.serverNameHint,
          required: true,
          errorText: _nameError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (_formError != null) ...[
          const SizedBox(height: ConcordSpacing.md),
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
        const SizedBox(height: ConcordSpacing.lg),
        ConcordButton(
          label: _submitting ? l10n.creatingServerLoading : l10n.createServerButton,
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

class _JoinForm extends ConsumerStatefulWidget {
  const _JoinForm({this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends ConsumerState<_JoinForm> {
  late final _codeController = TextEditingController(text: widget.initialCode ?? '');
  String? _codeError;
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeController.text.trim();
    setState(() => _codeError = code.isEmpty ? l10n.enterInviteCodeMessage : null);
    if (_codeError != null) return;

    setState(() => _submitting = true);
    try {
      final server = await ref.read(serversServiceProvider).joinServer(code);
      ref.invalidate(myServersProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/servers/${server.id}');
    } on ApiException catch (e) {
      setState(() {
        _codeError = e.isNotFound
            ? l10n.inviteCodeInvalidMessage
            : (e.message.isNotEmpty ? e.message : l10n.errorJoinServerFailed);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConcordTextField(
          controller: _codeController,
          label: l10n.inviteCodeLabel,
          hint: l10n.inviteCodeHint,
          required: true,
          errorText: _codeError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: ConcordSpacing.lg),
        ConcordButton(
          label: _submitting ? l10n.joiningServerLoading : l10n.joinServerButton,
          size: ConcordButtonSize.lg,
          expand: true,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
