import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/hijab_style.dart';
import '../theme/app_theme.dart';

IconData categoryIcon(String key) => switch (key) {
      'sun' => Icons.wb_sunny_outlined,
      'pashmina' => Icons.waves_rounded,
      'drape' => Icons.air_rounded,
      'layers' => Icons.layers_outlined,
      'globe' => Icons.public_rounded,
      'turban' => Icons.blur_circular_rounded,
      'crown' => Icons.diamond_outlined,
      _ => Icons.auto_awesome_outlined,
    };

/// Cover photo of a style, or a designed fallback card when there is no licensed photo.
class StyleImage extends StatelessWidget {
  final HijabStyle style;
  final String iconKey;
  final BorderRadius radius;
  final bool showFallbackTitle;

  const StyleImage({
    super.key,
    required this.style,
    required this.iconKey,
    this.radius = const BorderRadius.all(Radius.circular(24)),
    this.showFallbackTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = FallbackCover(style: style, iconKey: iconKey, showTitle: showFallbackTitle);
    Widget child;
    if (!style.hasImage) {
      child = fallback;
    } else if (style.isNetworkImage) {
      child = Image.network(
        style.image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: _fadeIn,
      );
    } else {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      child = LayoutBuilder(
        builder: (context, c) => Image.asset(
          style.image!,
          fit: BoxFit.cover,
          // Decode at display size to keep memory low on long grids.
          cacheWidth: c.maxWidth.isFinite ? (c.maxWidth * dpr).round() : null,
          errorBuilder: (_, _, _) => fallback,
          frameBuilder: _fadeIn,
        ),
      );
    }
    return ClipRRect(borderRadius: radius, child: child);
  }

  static Widget _fadeIn(BuildContext context, Widget child, int? frame, bool sync) {
    if (sync) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

class FallbackCover extends StatelessWidget {
  final HijabStyle style;
  final String iconKey;
  final bool showTitle;
  const FallbackCover({super.key, required this.style, required this.iconKey, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Vary hue slightly per style so a grid of fallbacks doesn't look repetitive.
    final seed = style.id.codeUnits.fold<int>(0, (a, b) => a + b);
    final palettes = dark
        ? const [
            [Color(0xFF4A2E37), Color(0xFF2E2328)],
            [Color(0xFF4D3A30), Color(0xFF2B2124)],
            [Color(0xFF3F2B3E), Color(0xFF231B21)],
          ]
        : const [
            [Color(0xFFF4D6D6), Color(0xFFE7B8B4)],
            [Color(0xFFF3E1CF), Color(0xFFDDB79F)],
            [Color(0xFFEBD3DE), Color(0xFFCFA2B4)],
          ];
    final colors = palettes[seed % palettes.length];
    final fg = dark ? Brand.goldNight : Brand.plum;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
      ),
      child: CustomPaint(
        painter: _DrapePainter(color: (dark ? Brand.goldNight : Colors.white).withValues(alpha: dark ? 0.12 : 0.45), seed: seed),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon(iconKey), color: fg.withValues(alpha: 0.75), size: 30),
                if (showTitle) ...[
                  const SizedBox(height: 8),
                  Text(
                    style.name.of(locale),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily(locale),
                      fontVariations: wght(600),
                      fontSize: 17,
                      height: 1.3,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft flowing curves evoking draped fabric.
class _DrapePainter extends CustomPainter {
  final Color color;
  final int seed;
  _DrapePainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final phase = (seed % 10) / 10 * math.pi;
    for (var i = 0; i < 7; i++) {
      final path = Path();
      final y0 = size.height * (0.15 + i * 0.12);
      path.moveTo(-10, y0);
      for (double x = -10; x <= size.width + 10; x += 6) {
        final y = y0 + math.sin(x / size.width * math.pi * 1.6 + phase + i * 0.5) * size.height * 0.06;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_DrapePainter old) => old.color != color || old.seed != seed;
}
