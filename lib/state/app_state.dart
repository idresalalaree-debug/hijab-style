import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/style_repository.dart';
import '../models/hijab_style.dart';

class AppState extends ChangeNotifier {
  static const _kFav = 'favorites';
  static const _kTried = 'tried';
  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale';

  final SharedPreferences prefs;
  final StyleRepository repo;

  AppState(this.prefs, this.repo)
      : favorites = (prefs.getStringList(_kFav) ?? const []).toSet(),
        tried = (prefs.getStringList(_kTried) ?? const []).toSet(),
        themeMode = ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ?? ThemeMode.system,
        localeCode = prefs.getString(_kLocale);

  StyleCatalog catalog = const StyleCatalog([], []);
  final Set<String> favorites;
  final Set<String> tried;
  ThemeMode themeMode;

  /// null = follow device language (Arabic if the device is Arabic, else English).
  String? localeCode;

  List<HijabStyle> get styles => catalog.styles;
  List<Category> get categories => catalog.categories;

  Future<void> load() async {
    catalog = await repo.loadLocal();
    notifyListeners();
  }

  /// Background refresh of the optional remote feed. Returns true when styles were added.
  Future<bool> refreshRemote({bool force = false}) async {
    final before = styles.length;
    final updated = await repo.refreshRemote(catalog, force: force);
    if (updated == null) return false;
    catalog = updated;
    notifyListeners();
    return styles.length > before;
  }

  HijabStyle? byId(String id) {
    for (final s in styles) {
      if (s.id == id) return s;
    }
    return null;
  }

  Category? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool isFavorite(String id) => favorites.contains(id);
  bool isTried(String id) => tried.contains(id);

  /// Only counts styles that still exist in the catalog.
  int get triedCount => styles.where((s) => tried.contains(s.id)).length;

  List<HijabStyle> get favoriteStyles => styles.where((s) => favorites.contains(s.id)).toList();

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    prefs.setStringList(_kFav, favorites.toList());
    notifyListeners();
  }

  void setTried(String id, bool value) {
    value ? tried.add(id) : tried.remove(id);
    prefs.setStringList(_kTried, tried.toList());
    notifyListeners();
  }

  void resetTried() {
    tried.clear();
    prefs.remove(_kTried);
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    prefs.setString(_kTheme, m.name);
    notifyListeners();
  }

  void setLocale(String? code) {
    localeCode = code;
    code == null ? prefs.remove(_kLocale) : prefs.setString(_kLocale, code);
    notifyListeners();
  }

  Locale resolveLocale(List<Locale>? device) {
    if (localeCode != null) return Locale(localeCode!);
    final first = (device == null || device.isEmpty) ? null : device.first;
    return first?.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
  }
}

/// Provides [AppState] down the tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
