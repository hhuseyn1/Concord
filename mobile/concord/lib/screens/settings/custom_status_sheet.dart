import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Map<CustomStatusExpiryPreset, String> _expiryLabels(AppLocalizations l10n) => {
      CustomStatusExpiryPreset.never: l10n.expiryNeverLabel,
      CustomStatusExpiryPreset.thirtyMinutes: l10n.expiryThirtyMinLabel,
      CustomStatusExpiryPreset.oneHour: l10n.expiryOneHourLabel,
      CustomStatusExpiryPreset.fourHours: l10n.expiryFourHoursLabel,
      CustomStatusExpiryPreset.today: l10n.expiryTodayLabel,
    };

Future<void> showCustomStatusSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(authControllerProvider).profile;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CustomStatusSheet(
      initialEmoji: profile?.customStatusEmoji ?? '',
      initialText: profile?.customStatusText ?? '',
    ),
  );
}

class _CustomStatusSheet extends ConsumerStatefulWidget {
  const _CustomStatusSheet({required this.initialEmoji, required this.initialText});

  final String initialEmoji;
  final String initialText;

  @override
  ConsumerState<_CustomStatusSheet> createState() => _CustomStatusSheetState();
}

class _CustomStatusSheetState extends ConsumerState<_CustomStatusSheet> {
  late final _emojiController = TextEditingController(text: widget.initialEmoji);
  late final _textController = TextEditingController(text: widget.initialText);
  CustomStatusExpiryPreset _expiry = CustomStatusExpiryPreset.never;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _emojiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save({String emoji = '', String text = '', CustomStatusExpiryPreset? expiry}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await ref
          .read(usersServiceProvider)
          .updateCustomStatus(emoji: emoji, text: text, expiryPreset: expiry ?? _expiry);
      ref.read(authControllerProvider.notifier).setProfile(profile);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final l10n = AppLocalizations.of(context);
    final expiryLabels = _expiryLabels(l10n);
    final hasExisting = widget.initialText.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: ConcordSpacing.lg,
        right: ConcordSpacing.lg,
        top: ConcordSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ConcordSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.setCustomStatusTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: ConcordTextField(controller: _emojiController, hint: '\u{1F600}'),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: ConcordTextField(controller: _textController, hint: l10n.customStatusTextHint),
              ),
            ],
          ),
          const SizedBox(height: ConcordSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.clearAfterLabel, style: TextStyle(color: colors.fgMuted)),
              DropdownButton<CustomStatusExpiryPreset>(
                value: _expiry,
                onChanged: (value) => setState(() => _expiry = value ?? CustomStatusExpiryPreset.never),
                items: [
                  for (final preset in CustomStatusExpiryPreset.values)
                    DropdownMenuItem(value: preset, child: Text(expiryLabels[preset]!)),
                ],
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: ConcordSpacing.sm),
            Text(_error!, style: TextStyle(color: colors.danger)),
          ],
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              if (hasExisting)
                ConcordButton(
                  label: l10n.clearButton,
                  variant: ConcordButtonVariant.ghost,
                  onPressed: _saving ? null : () => _save(),
                ),
              const Spacer(),
              ConcordButton(
                label: l10n.cancelButton,
                variant: ConcordButtonVariant.secondary,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(
                label: l10n.saveButton,
                loading: _saving,
                onPressed: _saving
                    ? null
                    : () => _save(emoji: _emojiController.text.trim(), text: _textController.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
