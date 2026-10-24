import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// One step per screen, large type, screen kept awake.
class FollowModeScreen extends StatefulWidget {
  final String styleId;
  const FollowModeScreen({super.key, required this.styleId});
  @override
  State<FollowModeScreen> createState() => _FollowModeScreenState();
}

class _FollowModeScreenState extends State<FollowModeScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _setWakelock(true);
  }

  @override
  void dispose() {
    _setWakelock(false);
    _pages.dispose();
    super.dispose();
  }

  Future<void> _setWakelock(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {
      // Unsupported platform (tests): the screen still works.
    }
  }

  void _go(int page) {
    HapticFeedback.selectionClick();
    if (reduceMotion(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final style = app.byId(widget.styleId);
    if (style == null) return const Scaffold();
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    final total = style.steps.length;
    final onDone = _page == total;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(style.name.of(locale), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(children: [
              for (var i = 0; i < total; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: i <= _page ? Brand.roseGoldGradient : null,
                      color: i <= _page ? null : cs.surfaceContainerHigh,
                    ),
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 5),
              ],
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: total + 1,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, i) {
                if (i == total) {
                  return _DonePage(
                    tried: app.isTried(style.id),
                    onMark: () {
                      app.setTried(style.id, true);
                      Navigator.of(context).pop();
                    },
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.stepOf(i + 1, total), style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('${i + 1}',
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily(locale),
                          fontVariations: wght(700),
                          fontSize: 88,
                          height: 1,
                          color: cs.primary.withValues(alpha: 0.18),
                        )),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          style.steps[i].of(locale),
                          style: TextStyle(fontSize: 26, height: 1.55, fontWeight: FontWeight.w500, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
          if (!onDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(children: [
                SizedBox(
                  width: 62,
                  height: 62,
                  child: IconButton.outlined(
                    tooltip: s.previous,
                    onPressed: _page == 0 ? null : () => _go(_page - 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _go(_page + 1),
                    icon: Icon(_page == total - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                    label: Text(_page == total - 1 ? s.finish : s.next),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(62)),
                  ),
                ),
              ]),
            ),
          if (!onDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.light_mode_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(s.screenStaysOn, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _DonePage extends StatelessWidget {
  final bool tried;
  final VoidCallback onMark;
  const _DonePage({required this.tried, required this.onMark});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: Duration(milliseconds: reduceMotion(context) ? 0 : 700),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Brand.roseGoldGradient),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
          ),
        ),
        const SizedBox(height: 26),
        Text(s.wellDone, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(s.wellDoneBody, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant, height: 1.6)),
        const SizedBox(height: 28),
        if (!tried)
          FilledButton.icon(
            onPressed: onMark,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(s.yesMark),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
          ),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.backToStyle)),
      ]),
    );
  }
}
