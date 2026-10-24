import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/hijab_style.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'style_image.dart';

Future<void> showShareSheet(BuildContext context, HijabStyle style) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareSheet(style: style),
  );
}

class _ShareSheet extends StatefulWidget {
  final HijabStyle style;
  const _ShareSheet({required this.style});
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final name = widget.style.name.of(Localizations.localeOf(context));
    setState(() => _busy = true);
    try {
      final ro = _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await ro.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) throw StateError('encode failed');
      await SharePlus.instance.share(ShareParams(
        text: s.shareText(name),
        files: [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png')],
        fileNameOverrides: ['hijab-style-${widget.style.id}.png'],
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.shareTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: RepaintBoundary(key: _boundary, child: ShareCard(style: widget.style)),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.ios_share_rounded),
            label: Text(s.shareAsImage),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ]),
      ),
    );
  }
}

/// The image that gets shared: cover photo, style name, meta and the app wordmark.
class ShareCard extends StatelessWidget {
  final HijabStyle style;
  const ShareCard({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final app = AppScope.of(context);
    final iconKey = app.category(style.categoryId)?.icon ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(fit: StackFit.expand, children: [
        StyleImage(style: style, iconKey: iconKey, radius: BorderRadius.zero, showFallbackTitle: false),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.4, 1],
              colors: [Colors.transparent, Color(0xE6201418)],
            ),
          ),
        ),
        PositionedDirectional(
          top: 14,
          start: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome, size: 14, color: Brand.roseDeep),
              const SizedBox(width: 5),
              Text(s.appName,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily(locale),
                    fontVariations: wght(700),
                    color: Brand.plum,
                    fontSize: 14,
                  )),
            ]),
          ),
        ),
        PositionedDirectional(
          start: 18,
          end: 18,
          bottom: 18,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(style.name.of(locale),
                style: TextStyle(
                  fontFamily: AppTheme.displayFamily(locale),
                  fontVariations: wght(700),
                  fontSize: 26,
                  height: 1.2,
                  color: Colors.white,
                )),
            const SizedBox(height: 6),
            Text(
              '${s.difficulty(style.difficulty)} · ${s.minutes(style.minutes)} · ${s.stepsCount(style.steps.length)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13.5),
            ),
            if (style.credit != null && style.credit!.photographer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${s.photoBy} ${style.credit!.photographer} · ${style.credit!.source}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
            ],
          ]),
        ),
      ]),
    );
  }
}
