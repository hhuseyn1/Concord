import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/font_scale_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../theme/theme.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final fontOption = ref.watch(fontScaleOptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appearanceTitle, style: textTheme.titleMedium),
        const SizedBox(height: ConcordSpacing.xs),
        Text(l10n.appearanceDescription, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
        const SizedBox(height: ConcordSpacing.sm),
        _PickerTile(
          label: l10n.appearanceThemeLabel,
          value: _themeLabel(l10n, themeMode),
          onTap: () => _pickTheme(context, ref),
        ),
        _PickerTile(
          label: l10n.appearanceFontSizeLabel,
          value: _fontLabel(l10n, fontOption),
          subtitle: l10n.appearanceFontSizeHint,
          onTap: () => _pickFontSize(context, ref),
        ),
        const SizedBox(height: ConcordSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ConcordSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceSidebar,
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(ConcordRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appearanceFontSizePreview, style: textTheme.bodyLarge),
              const SizedBox(height: ConcordSpacing.xs),
              Text(
                l10n.appearanceFontSizePreviewMeta,
                style: textTheme.bodySmall?.copyWith(color: colors.fgFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
    ThemeMode.system => l10n.themeSystem,
  };

  static String _fontLabel(AppLocalizations l10n, FontScaleOption option) => switch (option) {
    FontScaleOption.small => l10n.fontSizeSmall(option.previewPx),
    FontScaleOption.standard => l10n.fontSizeDefault(option.previewPx),
    FontScaleOption.large => l10n.fontSizeLarge(option.previewPx),
    FontScaleOption.extraLarge => l10n.fontSizeExtraLarge(option.previewPx),
  };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(themeModeControllerProvider);
    final selected = await showOptionSheet<ThemeMode>(
      context,
      options: [
        (ThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
        (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
        (ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_outlined),
      ],
      selected: current,
    );
    if (selected != null) {
      await ref.read(themeModeControllerProvider.notifier).setThemeMode(selected);
    }
  }

  Future<void> _pickFontSize(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(fontScaleOptionProvider);
    final selected = await showOptionSheet<FontScaleOption>(
      context,
      options: [
        for (final option in FontScaleOption.values) (option, _fontLabel(l10n, option), null),
      ],
      selected: current,
    );
    if (selected != null) {
      await ref.read(fontScaleControllerProvider.notifier).setOption(selected);
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.value, required this.onTap, this.subtitle});

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colors.fgMuted)),
      trailing: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.fgMuted),
              ),
            ),
            const SizedBox(width: ConcordSpacing.xs),
            Icon(Icons.chevron_right, color: colors.fgMuted),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required List<(T value, String label, IconData? icon)> options,
  required T selected,
}) {
  final colors = Theme.of(context).extension<ConcordColors>()!;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label, icon) in options)
              ListTile(
                leading: icon == null ? null : Icon(icon, color: colors.fgMuted),
                title: Text(label),
                trailing: value == selected ? Icon(Icons.check, color: colors.brand) : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    ),
  );
}
