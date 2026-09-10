import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'active_sessions_section.dart';
import 'change_password_section.dart';
import 'custom_status_sheet.dart';
import 'delete_account_section.dart';
import 'edit_profile_sheet.dart';
import 'link_device_screen.dart';
import 'preferences_section.dart';
import 'privacy_tab.dart';
import 'two_factor_section.dart';
import 'voice_settings_tab.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(authControllerProvider).profile;

    final displayName = profile == null
        ? null
        : (profile.username?.isNotEmpty == true
              ? profile.username!
              : [profile.name, profile.surname].where((part) => part != null && part.isNotEmpty).join(' '));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsScreenTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.myAccountTab),
              Tab(text: l10n.privacyTabLabel),
              Tab(text: l10n.voiceTabLabel),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(ConcordSpacing.lg),
              children: [
                Row(
                  children: [
                    ConcordAvatar(imageUrl: profile?.avatarUrl, name: displayName, size: ConcordAvatarSize.lg),
                    const SizedBox(width: ConcordSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName?.isNotEmpty == true ? displayName! : l10n.loadingEllipsis,
                            style: textTheme.titleMedium,
                          ),
                          if (profile?.email != null)
                            Text(profile!.email!, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
                          if (profile?.customStatusText?.isNotEmpty == true)
                            Text(
                              '${profile?.customStatusEmoji ?? ''} ${profile?.customStatusText}'.trim(),
                              style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConcordButton(
                          label: l10n.editProfileButton,
                          variant: ConcordButtonVariant.secondary,
                          size: ConcordButtonSize.sm,
                          onPressed: profile == null ? null : () => showEditProfileSheet(context, ref),
                        ),
                        const SizedBox(height: ConcordSpacing.sm),
                        ConcordButton(
                          label: l10n.statusButton,
                          variant: ConcordButtonVariant.secondary,
                          size: ConcordButtonSize.sm,
                          onPressed: profile == null ? null : () => showCustomStatusSheet(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: ConcordSpacing.lg),
                ConcordButton(
                  label: l10n.scanQrCodeButton,
                  leading: const Icon(Icons.qr_code_scanner, size: 18),
                  expand: true,
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (context) => const LinkDeviceScreen()),
                  ),
                ),
                const SizedBox(height: ConcordSpacing.xxl),
                const ChangePasswordSection(),
                const SizedBox(height: ConcordSpacing.xxl),
                const Divider(),
                const SizedBox(height: ConcordSpacing.lg),
                const TwoFactorSection(),
                const SizedBox(height: ConcordSpacing.xxl),
                const Divider(),
                const SizedBox(height: ConcordSpacing.lg),
                const PreferencesSection(),
                const SizedBox(height: ConcordSpacing.xxl),
                const Divider(),
                const SizedBox(height: ConcordSpacing.lg),
                const ActiveSessionsSection(),
                const SizedBox(height: ConcordSpacing.xxl),
                ConcordButton(
                  label: l10n.logOutButton,
                  variant: ConcordButtonVariant.danger,
                  expand: true,
                  onPressed: () => _confirmLogOut(context, ref, l10n),
                ),
                const SizedBox(height: ConcordSpacing.xxl),
                const DeleteAccountSection(),
              ],
            ),
            const PrivacyTab(),
            const VoiceSettingsTab(),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmLogOut(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.logOutConfirmTitle,
    message: l10n.logOutConfirmMessage,
    confirmLabel: l10n.logOutButton,
  );
  if (confirmed == true) await ref.read(authControllerProvider.notifier).logout();
}
