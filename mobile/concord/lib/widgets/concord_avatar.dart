import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../theme/theme.dart';

enum ConcordAvatarSize { sm, md, lg, xl }

class ConcordAvatar extends StatelessWidget {
  const ConcordAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = ConcordAvatarSize.md,
    this.presence,
  });

  final String? imageUrl;
  final String? name;
  final ConcordAvatarSize size;
  final ConcordPresence? presence;

  double get _dimension => switch (size) {
    ConcordAvatarSize.sm => 32,
    ConcordAvatarSize.md => 40,
    ConcordAvatarSize.lg => 48,
    ConcordAvatarSize.xl => 64,
  };

  double get _fontSize => switch (size) {
    ConcordAvatarSize.sm => 12,
    ConcordAvatarSize.md => 13,
    ConcordAvatarSize.lg => 15,
    ConcordAvatarSize.xl => 17,
  };

  double get _dotSize => switch (size) {
    ConcordAvatarSize.sm => 10,
    ConcordAvatarSize.md => 12,
    ConcordAvatarSize.lg => 14,
    ConcordAvatarSize.xl => 16,
  };

  String get _initials {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).take(2);
    return parts.map((part) => part.isEmpty ? '' : part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ConcordColors>()!;
    final resolvedUrl = imageUrl.resolveUploadUrl();

    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: _dimension,
              height: _dimension,
              // A translucent neutral rather than a fixed surface token: the
              // fallback circle sits on the rail, the sidebar, cards and sheets
              // alike, and in light mode `surfaceRail` and `surfaceSidebar` are
              // now the same value - so a hardcoded surface would make the
              // fallback vanish on some of them. Tinting whatever is behind it
              // keeps the circle visible on every surface in both themes.
              color: colors.fgDefault.withValues(alpha: 0.16),
              alignment: Alignment.center,
              child: resolvedUrl != null && resolvedUrl.isNotEmpty
                  ? Image.network(
                      resolvedUrl,
                      width: _dimension,
                      height: _dimension,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _Initials(
                        initials: _initials,
                        fontSize: _fontSize,
                        color: colors.fgDefault,
                      ),
                    )
                  : _Initials(initials: _initials, fontSize: _fontSize, color: colors.fgDefault),
            ),
          ),
          if (presence != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.presenceColor(presence!),
                  border: Border.all(color: colors.surfaceBase, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.fontSize, required this.color});

  final String initials;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Icon(Icons.person_outline, size: fontSize * 1.4, color: color);
    }
    return Text(
      initials,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color),
    );
  }
}
