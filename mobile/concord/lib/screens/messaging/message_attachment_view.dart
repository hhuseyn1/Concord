import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_config.dart';
import '../../theme/theme.dart';

const _imageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

String _filename(String url) {
  final withoutQuery = url.split('?').first;
  final segments = withoutQuery.split('/');
  return segments.isEmpty ? 'attachment' : segments.last;
}

String _extension(String url) {
  final name = _filename(url);
  final dot = name.lastIndexOf('.');
  return dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
}

class MessageAttachmentView extends StatelessWidget {
  const MessageAttachmentView({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final attachmentUrl = url;
    if (attachmentUrl == null || attachmentUrl.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<ConcordColors>()!;
    final absoluteUrl = attachmentUrl.resolveUploadUrl()!;
    final extension = _extension(attachmentUrl);
    final filename = _filename(attachmentUrl);

    if (_imageExtensions.contains(extension)) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(ConcordRadii.md),
          onTap: () => _open(absoluteUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ConcordRadii.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
              child: Image.network(
                absoluteUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _FileChip(
                  filename: filename,
                  colors: colors,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        onTap: () => _open(absoluteUrl),
        child: _FileChip(filename: filename, colors: colors),
      ),
    );
  }

  Future<void> _open(String absoluteUrl) async {
    final uri = Uri.parse(absoluteUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.filename, required this.colors});

  final String filename;
  final ConcordColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ConcordSpacing.md, vertical: ConcordSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        borderRadius: BorderRadius.circular(ConcordRadii.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 16, color: colors.fgMuted),
          const SizedBox(width: ConcordSpacing.sm),
          Flexible(
            child: Text(
              filename,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.fgDefault),
            ),
          ),
        ],
      ),
    );
  }
}
