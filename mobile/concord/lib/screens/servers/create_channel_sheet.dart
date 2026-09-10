import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Future<void> showCreateChannelSheet(
  BuildContext context,
  WidgetRef ref, {
  required String serverId,
  ChannelType defaultType = ChannelType.text,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CreateChannelSheet(serverId: serverId, defaultType: defaultType),
  );
}

class _CreateChannelSheet extends ConsumerStatefulWidget {
  const _CreateChannelSheet({required this.serverId, required this.defaultType});

  final String serverId;
  final ChannelType defaultType;

  @override
  ConsumerState<_CreateChannelSheet> createState() => _CreateChannelSheetState();
}

class _CreateChannelSheetState extends ConsumerState<_CreateChannelSheet> {
  final _nameController = TextEditingController();
  late ChannelType _type = widget.defaultType;
  String? _nameError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.channelNameRequired : null;
      _formError = null;
    });
    if (_nameError != null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(channelsServiceProvider).createChannel(widget.serverId, name: name, type: _type);
      ref.invalidate(channelsProvider(widget.serverId));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (e.isValidationError) {
        setState(() => _nameError = e.message.isNotEmpty ? e.message : l10n.channelNameInvalid);
      } else {
        setState(() => _formError = e.message.isNotEmpty ? e.message : l10n.errorCreateChannelFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
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
          Text(l10n.createChannelTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ConcordSpacing.lg),
          Text(l10n.channelTypeLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: ConcordSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TypeOption(
                  label: l10n.textChannelsLabel,
                  icon: Icons.tag,
                  selected: _type == ChannelType.text,
                  onTap: _submitting ? null : () => setState(() => _type = ChannelType.text),
                ),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(
                child: _TypeOption(
                  label: l10n.voiceChannelsLabel,
                  icon: Icons.volume_up_outlined,
                  selected: _type == ChannelType.voice,
                  onTap: _submitting ? null : () => setState(() => _type = ChannelType.voice),
                ),
              ),
            ],
          ),
          const SizedBox(height: ConcordSpacing.lg),
          ConcordTextField(
            controller: _nameController,
            label: l10n.channelNameLabel,
            hint: _type == ChannelType.voice ? l10n.channelNameHintVoice : l10n.channelNameHintText,
            required: true,
            errorText: _nameError,
            enabled: !_submitting,
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
              child: Text(_formError!, style: TextStyle(color: colors.danger, fontSize: 13)),
            ),
          ],
          const SizedBox(height: ConcordSpacing.lg),
          ConcordButton(
            label: _submitting ? l10n.creatingChannelLoading : l10n.createChannelTitle,
            size: ConcordButtonSize.lg,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    return Material(
      color: selected ? colors.brandBg : Colors.transparent,
      borderRadius: BorderRadius.circular(ConcordRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ConcordRadii.md),
            border: Border.all(color: selected ? colors.brand : colors.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? colors.brand : colors.fgMuted),
              const SizedBox(width: ConcordSpacing.xs),
              Text(label, style: TextStyle(color: selected ? colors.brand : colors.fgMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
