import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/server_providers.dart';
import '../channel/channel_message_view.dart';
import '../voice/voice_channel_view.dart';

class ChannelScreen extends ConsumerWidget {
  const ChannelScreen({super.key, required this.serverId, required this.channelId});

  final String serverId;
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider(serverId));
    final channel = channelsAsync.maybeWhen(
      data: (channels) => channels.where((c) => c.id == channelId).firstOrNull,
      orElse: () => null,
    );
    final stillResolvingType = channel == null && channelsAsync.isLoading;
    final isVoice = channel?.type == ChannelType.voice;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isVoice ? Icons.volume_up_outlined : Icons.tag, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(channel?.name ?? AppLocalizations.of(context).channelFallbackTitle, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: stillResolvingType
          ? const Center(child: CircularProgressIndicator())
          : (isVoice
              ? VoiceChannelView(serverId: serverId, channelId: channelId, channelName: channel?.name)
              : ChannelMessageView(serverId: serverId, channelId: channelId)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
