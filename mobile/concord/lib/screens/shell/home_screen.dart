import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/deep_link_providers.dart';
import '../../providers/notifications_controller.dart';
import '../../providers/push_notifications_controller.dart';
import '../../providers/voice_call_controller.dart';
import '../../providers/voice_call_state.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../direct_messages/conversation_list_screen.dart';
import '../friends/friends_screen.dart';
import '../servers/add_server_sheet.dart';
import 'server_rail_drawer.dart';
import 'user_panel_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingInviteIfAny();
      ref.read(pushNotificationsControllerProvider.notifier).ensureRegistered(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _consumePendingInviteIfAny() {
    if (!mounted) return;
    final code = ref.read(pendingInviteCodeProvider);
    if (code == null) return;
    ref.read(pendingInviteCodeProvider.notifier).state = null;
    showAddServerSheet(context, initialMode: AddServerMode.join, initialInviteCode: code);
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(voiceCallControllerProvider);
    final unreadCount = ref.watch(notificationsControllerProvider.select((s) => s.unreadCount));
    ref.listen<String?>(pendingInviteCodeProvider, (previous, next) {
      if (next != null) WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingInviteIfAny());
    });

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      endDrawer: const ServerRailDrawer(),
      appBar: AppBar(
        title: const Text('Concord'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.messagesTab),
            Tab(text: l10n.friendsTab),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: l10n.notificationsTooltip,
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: ConcordBadge(
                      label: unreadCount > 99 ? '99+' : '$unreadCount',
                      variant: ConcordBadgeVariant.danger,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchTooltip,
            onPressed: () => context.push('/search'),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: l10n.serversTooltip,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (callState.activeCall != null) _ActiveCallBanner(state: callState),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ConversationListScreen(),
                FriendsScreen(),
              ],
            ),
          ),
          const UserPanelBar(),
        ],
      ),
    );
  }
}

class _ActiveCallBanner extends ConsumerWidget {
  const _ActiveCallBanner({required this.state});

  final VoiceCallState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
    final call = state.activeCall!;
    final label = call.kind == ActiveCallKind.channel ? l10n.voiceConnectedLabel : l10n.callConnectedLabel;

    return Material(
      color: colors.brand.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () {
          if (call.kind == ActiveCallKind.channel) {
            context.push('/servers/${call.serverId}/channels/${call.channelId}');
          } else {
            context.push('/dm/${call.conversationId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.call, size: 16, color: colors.brand),
              const SizedBox(width: ConcordSpacing.sm),
              Expanded(child: Text(label, style: TextStyle(color: colors.brand, fontWeight: FontWeight.w500))),
              Text(l10n.tapToReturnLabel, style: TextStyle(color: colors.fgMuted, fontSize: type.size(12))),
            ],
          ),
        ),
      ),
    );
  }
}
