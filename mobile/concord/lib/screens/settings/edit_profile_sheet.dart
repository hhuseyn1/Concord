import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const _avatarExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
const _avatarExtensionToContentType = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
};

/// Mirrors `usersService.updateMe`'s documented server-side rule (see the web
/// `AccountSettingsForm`'s `USERNAME_PATTERN`).
final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{1,32}$');

Future<void> showEditProfileSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(authControllerProvider).profile;
  if (profile == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _usernameController;

  Uint8List? _avatarBytes;
  String? _avatarFilename;

  String? _nameError;
  String? _surnameError;
  String? _usernameError;
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _surnameController = TextEditingController(text: profile?.surname ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _avatarExtensions);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _avatarFilename = file.name;
      _avatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final username = _usernameController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Name is required.' : null;
      _surnameError = surname.isEmpty ? 'Surname is required.' : null;
      _usernameError = username.isEmpty
          ? 'Username is required.'
          : (!_usernamePattern.hasMatch(username)
                ? 'Only letters, numbers, and underscores — up to 32 characters.'
                : null);
      _formError = null;
    });
    if (_nameError != null || _surnameError != null || _usernameError != null) return;

    setState(() => _saving = true);
    try {
      final currentProfile = ref.read(authControllerProvider).profile;
      var avatarUrl = currentProfile?.avatarUrl;
      final avatarFilename = _avatarFilename;
      final avatarBytes = _avatarBytes;
      if (avatarFilename != null && avatarBytes != null) {
        final extension = avatarFilename.contains('.') ? avatarFilename.split('.').last.toLowerCase() : '';
        try {
          final uploaded = await ref.read(filesServiceProvider).uploadAvatar(
                bytes: avatarBytes,
                filename: avatarFilename,
                contentType: _avatarExtensionToContentType[extension],
              );
          avatarUrl = uploaded.url;
        } on ApiException catch (e) {
          if (!mounted) return;
          setState(() => _formError = 'Could not upload avatar: ${e.message}');
          return;
        }
      }

      final updated = await ref
          .read(usersServiceProvider)
          .updateMe(name: name, surname: surname, username: username, avatarUrl: avatarUrl);
      ref.read(authControllerProvider.notifier).setProfile(updated);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (e.isConflict) {
        setState(() => _usernameError = e.message.isNotEmpty ? e.message : 'That username is already taken.');
      } else if (e.isValidationError) {
        setState(() => _formError = e.message.isNotEmpty ? e.message : 'Please check the fields and try again.');
      } else {
        setState(() => _formError = e.message.isNotEmpty ? e.message : 'Could not update profile.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final profile = ref.watch(authControllerProvider).profile;
    final currentName = [profile?.name, profile?.surname].where((p) => p != null && p.isNotEmpty).join(' ');

    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ConcordSpacing.lg),
            Row(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _avatarBytes != null
                          ? ClipOval(
                              child: Image.memory(_avatarBytes!, width: 64, height: 64, fit: BoxFit.cover),
                            )
                          : ConcordAvatar(
                              imageUrl: profile?.avatarUrl,
                              name: currentName.isNotEmpty ? currentName : profile?.username,
                              size: ConcordAvatarSize.xl,
                            ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surfaceSidebar,
                            border: Border.all(color: colors.borderDefault),
                          ),
                          child: Icon(Icons.add_photo_alternate_outlined, size: 14, color: colors.fgMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ConcordSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avatar', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        'PNG, JPEG, WEBP or GIF, up to 5 MB.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ConcordSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ConcordTextField(
                    controller: _nameController,
                    label: 'Name',
                    required: true,
                    errorText: _nameError,
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: ConcordSpacing.sm),
                Expanded(
                  child: ConcordTextField(
                    controller: _surnameController,
                    label: 'Surname',
                    required: true,
                    errorText: _surnameError,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ConcordSpacing.md),
            ConcordTextField(
              controller: _usernameController,
              label: 'Username',
              required: true,
              errorText: _usernameError,
              enabled: !_saving,
              hint: 'Letters, numbers, and underscores only.',
            ),
            if (profile?.email != null) ...[
              const SizedBox(height: ConcordSpacing.md),
              Text('Email', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(
                profile!.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.fgMuted),
              ),
              const SizedBox(height: 2),
              Text(
                "Email can't be changed yet.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.fgMuted),
              ),
            ],
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
                child: Text(_formError!, style: TextStyle(color: colors.danger, fontSize: 13)),
              ),
            ],
            const SizedBox(height: ConcordSpacing.lg),
            Row(
              children: [
                const Spacer(),
                ConcordButton(
                  label: 'Cancel',
                  variant: ConcordButtonVariant.secondary,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: ConcordSpacing.sm),
                ConcordButton(label: 'Save', loading: _saving, onPressed: _saving ? null : _submit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
