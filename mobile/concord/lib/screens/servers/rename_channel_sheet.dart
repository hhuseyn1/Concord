import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../providers/api_providers.dart';
import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Future<void> showRenameChannelSheet(BuildContext context, WidgetRef ref, {required ChannelResponse channel}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RenameChannelSheet(channel: channel),
  );
}

class _RenameChannelSheet extends ConsumerStatefulWidget {
  const _RenameChannelSheet({required this.channel});

  final ChannelResponse channel;

  @override
  ConsumerState<_RenameChannelSheet> createState() => _RenameChannelSheetState();
}

class _RenameChannelSheetState extends ConsumerState<_RenameChannelSheet> {
  late final _nameController = TextEditingController(text: widget.channel.name);
  String? _nameError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    setState(() => _nameError = name.isEmpty ? 'Channel name is required.' : null);
    if (_nameError != null) return;
    if (name == widget.channel.name) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(channelsServiceProvider)
          .updateChannel(widget.channel.serverId, widget.channel.id, name: name);
      ref.invalidate(channelsProvider(widget.channel.serverId));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _nameError = e.message.isNotEmpty ? e.message : 'Could not rename channel.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Rename #${widget.channel.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ConcordSpacing.lg),
          ConcordTextField(
            controller: _nameController,
            label: 'Channel name',
            required: true,
            errorText: _nameError,
            enabled: !_submitting,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: ConcordSpacing.lg),
          Row(
            children: [
              const Spacer(),
              ConcordButton(
                label: 'Cancel',
                variant: ConcordButtonVariant.secondary,
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: ConcordSpacing.sm),
              ConcordButton(label: 'Save', loading: _submitting, onPressed: _submitting ? null : _submit),
            ],
          ),
        ],
      ),
    );
  }
}
