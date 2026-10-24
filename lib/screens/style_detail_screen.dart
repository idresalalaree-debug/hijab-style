import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';
import '../widgets/style_image.dart';
import 'follow_mode_screen.dart';

class StyleDetailScreen extends StatelessWidget {
  final String styleId;
  final String? heroTag;
  const StyleDetailScreen({super.key, required this.styleId, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final style = app.byId(styleId);
    if (style == null) return const Scaffold();
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cat = app.category(style.categoryId);
    final fav = app.isFavorite(style.id);
    final tried = app.isTried(style.id);
    final image = StyleImage(style: style, iconKey: cat?.icon ?? '', radius: BorderRadius.zero, showFallbackTitle: false);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.sizeOf(context).height * 0.52,
          pinned: true,
          stretch: true,
          backgroundColor: cs.surface,
          leading: const _CircleBack(),
          actions: [
            _CircleAction(
              icon: Icons.ios_share_rounded,
              tooltip: s.share,
              onTap: () => showShareSheet(context, style),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(fit: StackFit.expand, children: [
              heroTag == null ? image : Hero(tag: heroTag!, child: image),
              // Rounded "sheet" lip so the content appears to slide over the photo.
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cat != null)
                Text(cat.name.of(locale).toUpperCase(),
                    style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12.5)),
              const SizedBox(height: 6),
              Text(style.name.of(locale), style: tt.headlineMedium),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                MetaPill(icon: Icons.signal_cellular_alt_rounded, label: s.difficulty(style.difficulty)),
                MetaPill(icon: Icons.schedule_rounded, label: s.minutes(style.minutes)),
                MetaPill(icon: Icons.push_pin_outlined, label: s.pins(style.pins)),
              ]),
              const SizedBox(height: 16),
              Text(style.summary.of(locale), style: tt.bodyLarge),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => app.toggleFavorite(style.id),
                    icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: cs.primary),
                    label: Text(s.navFavorites, maxLines: 1, overflow: TextOverflow.ellipsis,
                        semanticsLabel: fav ? s.removeFavorite : s.addFavorite),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: tried
                        ? FilledButton.tonalIcon(
                            key: const ValueKey('t'),
                            onPressed: () => app.setTried(style.id, false),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(s.tried),
                          )
                        : OutlinedButton.icon(
                            key: const ValueKey('n'),
                            onPressed: () => app.setTried(style.id, true),
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: Text(s.markTried),
                          ),
                  ),
                ),
              ]),
              if (!style.fabrics.isEmpty) ...[
                const SizedBox(height: 18),
                _InfoCard(icon: Icons.texture_rounded, title: s.fabric, body: style.fabrics.of(locale)),
              ],
              const SizedBox(height: 26),
              Text(s.steps, style: tt.titleLarge),
              const SizedBox(height: 12),
              for (var i = 0; i < style.steps.length; i++)
                _StepTile(index: i + 1, text: style.steps[i].of(locale), last: i == style.steps.length - 1),
              if (style.tips.isNotEmpty) ...[
                const SizedBox(height: 18),
                _InfoCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: s.tips,
                  body: style.tips.map((t) => '• ${t.of(locale)}').join('\n'),
                ),
              ],
              if (style.credit != null) ...[
                const SizedBox(height: 18),
                Text('${s.photoBy}: ${style.credit!.label}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 110),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: Brand.roseGoldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Brand.roseDeep.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(58),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(fullscreenDialog: true, builder: (_) => FollowModeScreen(styleId: style.id)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: Text(s.followMode),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final String text;
  final bool last;
  const _StepTile({required this.index, required this.text, required this.last});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Brand.roseGoldGradient),
            child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: cs.outlineVariant)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 18),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cs.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: cs.onSurfaceVariant, height: 1.6)),
          ]),
        ),
      ]),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: _CircleAction(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, color: Brand.plum)),
    );
  }
}
