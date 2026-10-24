import 'package:flutter/material.dart';

import '../ads/ads.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'credits_screen.dart';

const appVersion = '1.0.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final total = app.styles.length;
    final tried = app.triedCount;

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(s.navSettings, style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 16),
        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: Brand.roseGoldGradient, borderRadius: BorderRadius.circular(26)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.myProgress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(s.triedProgress(tried, total),
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTheme.displayFamily(Localizations.localeOf(context)),
                  fontVariations: wght(700),
                  fontSize: 22,
                )),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : tried / total,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                color: Colors.white,
              ),
            ),
            if (tried > 0)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => _confirmReset(context),
                  child: Text(s.resetProgress),
                ),
              ),
          ]),
        ),
        _Group(title: s.language, children: [
          _Segmented<String?>(
            value: app.localeCode,
            options: [(null, s.themeSystem), ('ar', 'العربية'), ('en', 'English')],
            onChanged: app.setLocale,
          ),
        ]),
        _Group(title: s.appearance, children: [
          _Segmented<ThemeMode>(
            value: app.themeMode,
            options: [(ThemeMode.system, s.themeSystem), (ThemeMode.light, s.themeLight), (ThemeMode.dark, s.themeDark)],
            onChanged: app.setThemeMode,
          ),
        ]),
        _Group(title: s.about, children: [
          ListTile(
            leading: Icon(Icons.cloud_off_rounded, color: cs.secondary),
            title: Text(s.offlineNote),
          ),
          ListTile(
            leading: Icon(Icons.refresh_rounded, color: cs.secondary),
            title: Text(s.checkNewStyles),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final added = await app.refreshRemote(force: true);
              messenger.showSnackBar(SnackBar(content: Text(added ? s.newStylesAdded : s.upToDate)));
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: cs.secondary),
            title: Text(s.credits),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: Ads.instance.privacyOptionsRequired,
            builder: (context, required, _) => !required
                ? const SizedBox.shrink()
                : ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: cs.secondary),
                    title: Text(s.privacyOptions),
                    onTap: Ads.instance.showPrivacyOptions,
                  ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.secondary),
            title: Text(s.version),
            trailing: Text(appVersion, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ]),
      ]),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.resetProgress),
        content: Text(s.resetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.confirm)),
        ],
      ),
    );
    if (ok == true && context.mounted) AppScope.read(context).resetTried();
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 24, 6, 8),
        child: Text(title, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 13.5)),
      ),
      Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: cs.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    ]);
  }
}

class _Segmented<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const _Segmented({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [for (final o in options) ButtonSegment<T>(value: o.$1, label: Text(o.$2))],
          selected: {value},
          onSelectionChanged: (v) => onChanged(v.first),
        ),
      ),
    );
  }
}
