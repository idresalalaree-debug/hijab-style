import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hijab_style.dart';

/// Optional remote feed (GitHub Pages). The app is fully functional without it.
const remoteFeedUrl = 'https://idresalalaree-debug.github.io/hijab-style/styles.json';

/// Highest feed schema this build understands; newer feeds are ignored.
const supportedSchema = 1;

class StyleCatalog {
  final List<Category> categories;
  final List<HijabStyle> styles;
  const StyleCatalog(this.categories, this.styles);
}

class StyleRepository {
  static const _cacheKey = 'remote_feed_json';
  static const _fetchedAtKey = 'remote_feed_fetched_at';
  static const refreshInterval = Duration(hours: 24);

  final SharedPreferences prefs;
  final AssetBundle bundle;
  final http.Client? client;

  StyleRepository(this.prefs, {AssetBundle? bundle, this.client}) : bundle = bundle ?? rootBundle;

  Future<StyleCatalog> loadLocal() async {
    final raw = await _loadBundled();
    final bundled = parseFeed(raw, remote: false)!;
    final cached = prefs.getString(_cacheKey);
    final remote = cached == null ? null : parseFeed(cached, remote: true);
    return merge(bundled, remote);
  }

  /// Fetches the remote feed at most once per [refreshInterval].
  /// Returns a new catalog only when something changed; never throws.
  Future<StyleCatalog?> refreshRemote(StyleCatalog bundledBase, {bool force = false}) async {
    final last = prefs.getInt(_fetchedAtKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - last < refreshInterval.inMilliseconds) return null;
    final c = client ?? http.Client();
    try {
      final res = await c.get(Uri.parse(remoteFeedUrl)).timeout(const Duration(seconds: 8));
      await prefs.setInt(_fetchedAtKey, now);
      if (res.statusCode != 200) return null;
      final body = utf8.decode(res.bodyBytes);
      final feed = parseFeed(body, remote: true);
      if (feed == null) return null;
      if (body == prefs.getString(_cacheKey)) return null;
      await prefs.setString(_cacheKey, body);
      final raw = await _loadBundled();
      return merge(parseFeed(raw, remote: false)!, feed);
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  // Decodes on the current isolate: loadString() hops to compute() for files >50 KB,
  // which never completes inside widget tests, and parsing ~70 KB here is cheap.
  Future<String> _loadBundled() async =>
      utf8.decode((await bundle.load('assets/data/styles.json')).buffer.asUint8List());

  static StyleCatalog? parseFeed(String raw, {required bool remote}) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (((j['schema'] ?? 1) as num) > supportedSchema) return null;
      final cats = ((j['categories'] ?? const []) as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      final styles = ((j['styles'] ?? const []) as List)
          .map((e) => HijabStyle.tryParse(e as Map<String, dynamic>, remote: remote))
          .whereType<HijabStyle>()
          .toList();
      return StyleCatalog(cats, styles);
    } catch (_) {
      return null;
    }
  }

  /// Bundled styles always win on id clashes; remote only adds new styles/categories.
  static StyleCatalog merge(StyleCatalog bundled, StyleCatalog? remote) {
    if (remote == null) return bundled;
    final cats = [...bundled.categories];
    final catIds = cats.map((c) => c.id).toSet();
    cats.addAll(remote.categories.where((c) => catIds.add(c.id)));
    final ids = bundled.styles.map((s) => s.id).toSet();
    final validCats = cats.map((c) => c.id).toSet();
    final extra = remote.styles.where((s) => validCats.contains(s.categoryId) && ids.add(s.id));
    return StyleCatalog(cats, [...bundled.styles, ...extra]);
  }
}

/// Same style for everyone on a given local day, cycling through all styles
/// in a fixed shuffled order so consecutive days rarely share a category.
HijabStyle? styleOfTheDay(List<HijabStyle> styles, DateTime now) {
  if (styles.isEmpty) return null;
  final sorted = [...styles]..sort((a, b) => a.id.compareTo(b.id));
  final day = DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final n = sorted.length;
  // Multiplying by a step coprime with n visits every index once per cycle.
  var step = 7;
  while (_gcd(step, n) != 1) {
    step++;
  }
  return sorted[(day * step) % n];
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// Normalises Arabic/Latin text for forgiving search.
String normalizeForSearch(String s) {
  var t = s.toLowerCase();
  t = t.replaceAll(RegExp('[ً-ْـ]'), ''); // harakat + tatweel
  t = t.replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي');
  return t.trim();
}

/// [tagLabel] maps a tag id to its localised labels so "عمل" finds tag `work`.
bool styleMatches(HijabStyle s, String query, {String Function(String tag)? tagLabel}) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return true;
  final hay = normalizeForSearch([
    s.name.ar,
    s.name.en,
    s.summary.ar,
    s.summary.en,
    s.fabrics.ar,
    s.fabrics.en,
    ...s.tags,
    if (tagLabel != null) ...s.tags.map(tagLabel),
  ].join(' '));
  return q.split(RegExp(r'\s+')).every(hay.contains);
}
