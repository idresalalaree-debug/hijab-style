import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/hijab_style.dart';
import '../screens/style_detail_screen.dart';
import '../state/app_state.dart';
import 'style_image.dart';

bool reduceMotion(BuildContext c) => MediaQuery.maybeDisableAnimationsOf(c) ?? false;

/// [heroTag] must be unique on the current screen (a style can appear in several sections).
void openStyle(BuildContext context, HijabStyle style, {String? heroTag}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => StyleDetailScreen(styleId: style.id, heroTag: heroTag)));
}

/// Fades + slides children in once, staggered by [index]. Skipped when the OS asks for reduced motion.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 45 * widget.index.clamp(0, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - _a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

class MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool onImage;
  const MetaPill({super.key, required this.icon, required this.label, this.onImage = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = onImage ? Colors.white : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage ? Colors.black.withValues(alpha: 0.28) : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: fg)),
      ]),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 26, 8, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]),
    );
  }
}

/// Grid/list tile for a style: photo (or designed cover), name, meta and quick favorite.
class StyleCard extends StatelessWidget {
  final HijabStyle style;
  final double? width;
  final String heroPrefix;
  const StyleCard({super.key, required this.style, required this.heroPrefix, this.width});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    final fav = app.isFavorite(style.id);
    final tried = app.isTried(style.id);
    final iconKey = app.category(style.categoryId)?.icon ?? '';
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: style.name.of(locale),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => openStyle(context, style, heroTag: '$heroPrefix-${style.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image takes whatever height the grid/list cell leaves after the text.
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  Hero(
                    tag: '$heroPrefix-${style.id}',
                    child: StyleImage(style: style, iconKey: iconKey, showFallbackTitle: false),
                  ),
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: _FavButton(active: fav, onTap: () => app.toggleFavorite(style.id), label: fav ? s.removeFavorite : s.addFavorite),
                  ),
                  if (tried)
                    PositionedDirectional(
                      bottom: 10,
                      start: 10,
                      child: MetaPill(icon: Icons.check_rounded, label: s.tried.replaceAll(' ✓', ''), onImage: true),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                child: Text(style.name.of(locale),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                child: Text('${s.difficulty(style.difficulty)} · ${s.minutes(style.minutes)}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final String label;
  const _FavButton({required this.active, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            key: ValueKey(active),
            color: const Color(0xFFB0566A),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
            child: Icon(icon, size: 42, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(action!)),
          ],
        ]),
      ),
    );
  }
}
