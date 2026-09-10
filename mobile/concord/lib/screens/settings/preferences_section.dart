import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../providers/locale_provider.dart';
import '../../theme/theme.dart';

class PreferencesSection extends ConsumerStatefulWidget {
  const PreferencesSection({super.key});

  @override
  ConsumerState<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends ConsumerState<PreferencesSection> {
  bool _saving = false;

  Future<void> _update({bool? notificationsMuted, bool? notificationsSoundEnabled}) async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(usersServiceProvider).updatePreferences(
            locale: profile.locale,
            notificationsMuted: notificationsMuted ?? profile.notificationsMuted,
            notificationsSoundEnabled: notificationsSoundEnabled ?? profile.notificationsSoundEnabled,
          );
      ref.read(authControllerProvider.notifier).setProfile(updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSavePreferenceFailed(e.message))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final current = ref.read(localeControllerProvider);
    final options = <(String code, String label)>[
      ('en', l10n.languageEnglish),
      ('az', l10n.languageAzerbaijani),
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option.$2),
                trailing: option.$1 == current?.languageCode ? Icon(Icons.check, color: colors.brand) : null,
                onTap: () => Navigator.of(sheetContext).pop(option.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).setLocale(Locale(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(authControllerProvider).profile;
    final locale = ref.watch(localeControllerProvider);
    if (profile == null) return const SizedBox.shrink();

    final languageValue = locale?.languageCode == 'az' ? l10n.languageAzerbaijani : l10n.languageEnglish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.preferencesTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.languageLabel),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(languageValue, style: TextStyle(color: colors.fgMuted)),
              const SizedBox(width: ConcordSpacing.xs),
              Icon(Icons.chevron_right, color: colors.fgMuted),
            ],
          ),
          onTap: () => _pickLanguage(context),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.muteNotificationsLabel),
          subtitle: Text(l10n.muteNotificationsSubtitle, style: TextStyle(color: colors.fgMuted)),
          value: profile.notificationsMuted,
          onChanged: _saving ? null : (value) => _update(notificationsMuted: value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationSoundLabel),
          subtitle: Text(l10n.notificationSoundSubtitle, style: TextStyle(color: colors.fgMuted)),
          value: profile.notificationsSoundEnabled,
          onChanged: _saving ? null : (value) => _update(notificationsSoundEnabled: value),
        ),
      ],
    );
  }
}
