import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_controller.dart';
import '../providers/presence_controller.dart';
import '../providers/servers_controller.dart';

class AppSessionOverlay extends ConsumerWidget {
  const AppSessionOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(presenceControllerProvider);
    ref.watch(serversControllerProvider);
    ref.watch(notificationsControllerProvider);
    return child;
  }
}
