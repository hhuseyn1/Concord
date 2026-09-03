import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';

class PreferencesSection extends ConsumerStatefulWidget {
  const PreferencesSection({super.key});

  @override
  ConsumerState<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends ConsumerState<PreferencesSection> {
  bool _saving = false;

  Future<void> _update({bool? notificationsMuted, bool? notificationsSoundEnabled}) async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save preference: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(authControllerProvider).profile;
    if (profile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mute notifications'),
          subtitle: Text('Suppress in-app notification pop-ups.', style: TextStyle(color: colors.fgMuted)),
          value: profile.notificationsMuted,
          onChanged: _saving ? null : (value) => _update(notificationsMuted: value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notification sound'),
          subtitle: Text('Play a sound for new notifications.', style: TextStyle(color: colors.fgMuted)),
          value: profile.notificationsSoundEnabled,
          onChanged: _saving ? null : (value) => _update(notificationsSoundEnabled: value),
        ),
      ],
    );
  }
}
