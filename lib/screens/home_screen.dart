import 'package:flutter/material.dart';

import '../app.dart';
import '../data/style_repository.dart';
import '../l10n/strings.dart';
import '../models/hijab_style.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/style_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final today = styleOfTheDay(app.styles, DateTime.now());
    final quick = app.styles.where((e) => e.difficulty == 1 && e.minutes <= 3).take(10).toList();
    final occasions = app.styles.where((e) => e.tags.contains('occasion') || e.categoryId == 'bridal').take(10).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _Header(tried: app.triedCount, total: app.styles.length)),
        if (today != null)
          SliverToBoxAdapter(
            // Keep the hero card phone-sized on tablets and wide windows.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: FadeSlideIn(child: _StyleOfDayCard(style: today)),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SectionHeader(title: s.categories)),
        SliverToBoxAdapter(child: _CategoryStrip(categories: app.categories)),
        if (quick.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeader(title: s.quickStyles, action: s.seeAll, onAction: () => ShellScope.of(context).go(1))),
          SliverToBoxAdapter(child: _HorizontalStyles(styles: quick, heroPrefix: 'quick')),
        ],
        if (occasions.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeader(title: s.occasionStyles)),
          SliverToBoxAdapter(child: _HorizontalStyles(styles: occasions, heroPrefix: 'occ')),
        ],
        SliverToBoxAdapter(child: SectionHeader(title: s.allStyles)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          sliver: StyleGrid(styles: app.styles, heroPrefix: 'home-grid'),
        ),
      ]),
    );
  }
}

/// Responsive 2–4 column grid used by Home, Explore and Favorites.
class StyleGrid extends StatelessWidget {
  final List<HijabStyle> styles;
  final String heroPrefix;
  const StyleGrid({super.key, required this.styles, required this.heroPrefix});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => FadeSlideIn(index: i % 6, child: StyleCard(style: styles[i], heroPrefix: heroPrefix)),
        childCount: styles.length,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int tried;
  final int total;
  const _Header({required this.tried, required this.total});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : tried / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.greeting(DateTime.now().hour), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.5)),
            const SizedBox(height: 2),
            ShaderMask(
              shaderCallback: (r) => Brand.roseGoldGradient.createShader(r),
              child: Text(s.appName, style: tt.headlineMedium?.copyWith(color: Colors.white)),
            ),
          ]),
        ),
        Semantics(
          label: s.triedProgress(tried, total),
          child: Tooltip(
            message: s.triedProgress(tried, total),
            child: SizedBox(
              width: 58,
              height: 58,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: cs.surfaceContainer,
                      color: cs.secondary,
                    ),
                  ),
                  Text('$tried', style: tt.titleMedium?.copyWith(color: cs.secondary)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StyleOfDayCard extends StatelessWidget {
  final HijabStyle style;
  const _StyleOfDayCard({required this.style});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final locale = Localizations.localeOf(context);
    final iconKey = app.category(style.categoryId)?.icon ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: '${s.styleOfDay}: ${style.name.of(locale)}',
        child: GestureDetector(
          onTap: () => openStyle(context, style, heroTag: 'day-${style.id}'),
          child: AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Brand.roseDeep.withValues(alpha: 0.22), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'day-${style.id}',
                  child: StyleImage(style: style, iconKey: iconKey, radius: BorderRadius.circular(30), showFallbackTitle: false),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Colors.transparent, Color(0xD9201418)],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(top: 16, start: 16, child: _ShimmerBadge(label: s.styleOfDay)),
                PositionedDirectional(
                  start: 20,
                  end: 20,
                  bottom: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(style.name.of(locale),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(style.summary.of(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.45)),
                    const SizedBox(height: 12),
                    Row(children: [
                      MetaPill(icon: Icons.schedule_rounded, label: s.minutes(style.minutes), onImage: true),
                      const SizedBox(width: 6),
                      MetaPill(icon: Icons.signal_cellular_alt_rounded, label: s.difficulty(style.difficulty), onImage: true),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(gradient: Brand.roseGoldGradient, borderRadius: BorderRadius.circular(30)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(s.startNow, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ]),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rose-gold badge with a slow light sweep.
class _ShimmerBadge extends StatefulWidget {
  final String label;
  const _ShimmerBadge({required this.label});
  @override
  State<_ShimmerBadge> createState() => _ShimmerBadgeState();
}

class _ShimmerBadgeState extends State<_ShimmerBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduceMotion(context) ? _c.stop() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(gradient: Brand.roseGoldGradient, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
    return AnimatedBuilder(
      animation: _c,
      child: badge,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) {
          final x = -1.0 + _c.value * 3;
          return LinearGradient(
            begin: Alignment(x - 0.4, 0),
            end: Alignment(x + 0.4, 0),
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.55), Colors.transparent],
          ).createShader(r);
        },
        child: child,
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<Category> categories;
  const _CategoryStrip({required this.categories});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = categories[i];
          return FadeSlideIn(
            index: i,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => ShellScope.of(context).go(1, category: c.id),
              child: SizedBox(
                width: 84,
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: cs.primaryContainer,
                      border: Border.all(color: cs.secondary.withValues(alpha: 0.35)),
                    ),
                    child: Icon(categoryIcon(c.icon), color: cs.primary, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(c.name.of(locale),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalStyles extends StatelessWidget {
  final List<HijabStyle> styles;
  final String heroPrefix;
  const _HorizontalStyles({required this.styles, required this.heroPrefix});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) => FadeSlideIn(index: i, child: StyleCard(style: styles[i], width: 160, heroPrefix: heroPrefix)),
      ),
    );
  }
}
