import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'screens/explore_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class HijabStyleApp extends StatelessWidget {
  final AppState state;
  const HijabStyleApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final locale = state.resolveLocale(WidgetsBinding.instance.platformDispatcher.locales);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (c) => S.of(c).appName,
            locale: locale,
            supportedLocales: S.supported,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light(locale),
            darkTheme: AppTheme.dark(locale),
            themeMode: state.themeMode,
            home: const RootShell(),
          );
        },
      ),
    );
  }
}

/// Lets any screen switch tabs (e.g. Home → Explore with a category preselected).
class ShellController extends ChangeNotifier {
  int index = 0;
  String? exploreCategory;

  void go(int i, {String? category}) {
    index = i;
    if (i == 1) exploreCategory = category;
    notifyListeners();
  }
}

class ShellScope extends InheritedWidget {
  final ShellController controller;
  const ShellScope({super.key, required this.controller, required super.child});
  static ShellController of(BuildContext c) => c.getInheritedWidgetOfExactType<ShellScope>()!.controller;
  @override
  bool updateShouldNotify(ShellScope old) => false;
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _shell = ShellController();

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ShellScope(
      controller: _shell,
      child: ListenableBuilder(
        listenable: _shell,
        builder: (context, _) => PopScope(
          // Back from another tab returns Home before leaving the app.
          canPop: _shell.index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _shell.go(0);
          },
          child: Scaffold(
            body: IndexedStack(
              index: _shell.index,
              children: [
                const HomeScreen(),
                ExploreScreen(initialCategory: _shell.exploreCategory, key: ValueKey(_shell.exploreCategory)),
                const FavoritesScreen(),
                const SettingsScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _shell.index,
              onDestinationSelected: (i) => _shell.go(i, category: i == 1 ? _shell.exploreCategory : null),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.navHome),
                NavigationDestination(icon: const Icon(Icons.search_rounded), selectedIcon: const Icon(Icons.manage_search_rounded), label: s.navExplore),
                NavigationDestination(icon: const Icon(Icons.favorite_outline_rounded), selectedIcon: const Icon(Icons.favorite_rounded), label: s.navFavorites),
                NavigationDestination(icon: const Icon(Icons.tune_rounded), selectedIcon: const Icon(Icons.tune_rounded), label: s.navSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
