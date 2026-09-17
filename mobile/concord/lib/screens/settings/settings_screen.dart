import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'active_sessions_section.dart';
import 'appearance_section.dart';
import 'billing_section.dart';
import 'change_password_section.dart';
import 'custom_status_sheet.dart';
import 'delete_account_section.dart';
import 'edit_profile_sheet.dart';
import 'link_device_screen.dart';
import 'preferences_section.dart';
import 'privacy_tab.dart';
import 'stars_section.dart';
import 'two_factor_section.dart';
import 'voice_settings_tab.dart';

/// Index of the Stars tab inside the [TabBar] below - referenced by the
/// balance chip in the account header, which jumps here when tapped.
const _starsTabIndex = 4;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsScreenTitle),
          bottom: TabBar(
            // Already scrollable, so the fifth tab (and longer labels at a
            // larger text size) extends the strip instead of squeezing it.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.myAccountTab),
              Tab(text: l10n.privacyTabLabel),
              Tab(text: l10n.voiceTabLabel),
              Tab(text: l10n.billingTabLabel),
              Tab(text: l10n.starsTabLabel),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyAccountTab(),
            PrivacyTab(),
            VoiceSettingsTab(),
            BillingSection(),
            StarsSection(),
          ],
        ),
      ),
    );
  }
}

class _MyAccountTab extends ConsumerWidget {
  const _MyAccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(ConcordSpacing.lg),
      children: [
        const _AccountHeader(),
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
        // Appearance sits with the other per-device preferences (language,
        // notifications) rather than in a tab of its own - same placement as
        // the web app's Appearance block.
        const AppearanceSection(),
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
    );
  }
}

/// Avatar + identity + the Stars chip, with the two profile actions on their
/// own row underneath.
///
/// The actions used to be a fixed-width column squeezed to the right of the
/// name; at 430pt with the default text size that was fine, but at 320pt -
/// and at any width once the Extra large text size is on - the name column
/// collapsed to a couple of ellipsized characters. Giving the buttons a
/// full-width [Wrap] of their own keeps every label readable at every size and
/// lets them stack when they no longer fit side by side.
class _AccountHeader extends ConsumerWidget {
  const _AccountHeader();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile?.email != null)
                    Text(
                      profile!.email!,
                      style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (profile?.customStatusText?.isNotEmpty == true)
                    Text(
                      '${profile?.customStatusEmoji ?? ''} ${profile?.customStatusText}'.trim(),
                      style: textTheme.bodySmall?.copyWith(color: colors.fgMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: ConcordSpacing.xs),
                  StarsBalanceChip(
                    onTap: () => DefaultTabController.of(context).animateTo(_starsTabIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ConcordSpacing.md),
        Wrap(
          spacing: ConcordSpacing.sm,
          runSpacing: ConcordSpacing.sm,
          children: [
            ConcordButton(
              label: l10n.editProfileButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: profile == null ? null : () => showEditProfileSheet(context, ref),
            ),
            ConcordButton(
              label: l10n.statusButton,
              variant: ConcordButtonVariant.secondary,
              size: ConcordButtonSize.sm,
              onPressed: profile == null ? null : () => showCustomStatusSheet(context, ref),
            ),
          ],
        ),
      ],
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
