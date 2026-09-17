import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/server_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../servers/add_server_sheet.dart';

class ServerRailDrawer extends ConsumerWidget {
  const ServerRailDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final type = ConcordTypography.of(context);
    final l10n = AppLocalizations.of(context);
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
              tooltip: l10n.homeTooltip,
              selected: currentServerId == null,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              // Self-contained badge asset - reads fine even when this tile's own selected-state
              // background is filled brand-blue (see AuthLayout for the same reasoning).
              child: Image.asset('assets/logo_badge.png', width: 32, height: 32),
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
                    l10n.couldNotLoadServersText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: type.size(11), color: colors.fgMuted),
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
                tooltip: l10n.addOrJoinServerTooltip,
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
          // Unselected tiles use `surfaceBase`, not `surfaceSidebar`: the
          // drawer itself is `surfaceRail`, and in light mode rail and sidebar
          // are the same value now, which would make every unselected server
          // bubble disappear into the rail. `surfaceBase` is a step away from
          // the rail in both themes.
          color: selected ? colors.brand : colors.surfaceBase,
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
