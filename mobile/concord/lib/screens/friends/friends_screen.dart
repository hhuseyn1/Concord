import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'add_friend_tab.dart';
import 'blocked_tab.dart';
import 'friends_tab.dart';
import 'pending_tab.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return Column(
      children: [
        Material(
          color: colors.surfaceBase,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'Pending'),
              Tab(text: 'Blocked'),
              Tab(text: 'Add Friend'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              FriendsTab(),
              PendingTab(),
              BlockedTab(),
              AddFriendTab(),
            ],
          ),
        ),
      ],
    );
  }
}
