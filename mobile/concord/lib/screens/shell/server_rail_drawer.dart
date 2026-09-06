import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../servers/add_server_sheet.dart';

class ServerRailDrawer extends ConsumerWidget {
  const ServerRailDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final serversAsync = ref.watch(myServersProvider);
    final currentServerId = GoRouterState.of(context).pathParameters['serverId'];

    return Drawer(
      backgroundColor: colors.surfaceRail,
      width: 88,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: ConcordSpacing.sm),
            _RailTile(
              tooltip: 'Home (Messages & Friends)',
              selected: currentServerId == null,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: SvgPicture.asset('assets/logo.svg', width: 22, height: 22),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.sm),
              child: Container(width: 32, height: 1, color: colors.borderDefault),
            ),
            Expanded(
              child: serversAsync.when(
                loading: () => const Center(
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.sm),
                  child: Text(
                    'Couldn’t load servers',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.fgMuted),
                  ),
                ),
                data: (servers) => ListView(
                  padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.xs),
                  children: [
                    for (final server in servers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: ConcordSpacing.sm),
                        child: _RailTile(
                          tooltip: server.name,
                          selected: server.id == currentServerId,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/servers/${server.id}');
                          },
                          child: ConcordAvatar(imageUrl: server.iconUrl, name: server.name, size: ConcordAvatarSize.md),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ConcordSpacing.md),
              child: ConcordIconButton(
                icon: Icons.add,
                tooltip: 'Add or join a server',
                variant: ConcordButtonVariant.secondary,
                size: ConcordButtonSize.lg,
                onPressed: () {
                  Navigator.of(context).pop();
                  showAddServerSheet(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;

    return Tooltip(
      message: tooltip,
      child: Center(
        child: Material(
          color: selected ? colors.brand : colors.surfaceSidebar,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(selected ? ConcordRadii.md : ConcordRadii.full),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(selected ? ConcordRadii.md : ConcordRadii.full),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(color: selected ? colors.fgOnBrand : colors.fgDefault),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
