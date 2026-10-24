import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hijab_style/data/style_repository.dart';
import 'package:hijab_style/models/hijab_style.dart';

void main() {
  final raw = File('assets/data/styles.json').readAsStringSync();

  test('bundled catalog parses fully and is consistent', () {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final cat = StyleRepository.parseFeed(raw, remote: false)!;
    expect(cat.styles.length, (j['styles'] as List).length, reason: 'no style may be dropped as malformed');
    final ids = cat.styles.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'ids are unique');
    final catIds = cat.categories.map((c) => c.id).toSet();
    for (final s in cat.styles) {
      expect(catIds, contains(s.categoryId), reason: s.id);
      expect(s.name.ar, isNotEmpty, reason: s.id);
      expect(s.name.en, isNotEmpty, reason: s.id);
      expect(s.steps, isNotEmpty, reason: s.id);
      for (final st in s.steps) {
        expect(st.ar.trim(), isNotEmpty, reason: s.id);
        expect(st.en.trim(), isNotEmpty, reason: s.id);
      }
      if (s.hasImage) {
        expect(File(s.image!).existsSync(), isTrue, reason: 'missing image for ${s.id}');
        expect(s.credit?.license, isNotEmpty, reason: 'image without license: ${s.id}');
      }
    }
  });

  test('remote feed: rejects non-https images, unknown categories, id clashes, newer schema', () {
    final bundled = StyleRepository.parseFeed(raw, remote: false)!;
    final remoteRaw = jsonEncode({
      'schema': 1,
      'categories': [],
      'styles': [
        {'id': 'classic-wrap', 'category': 'everyday', 'name': {'ar': 'x', 'en': 'x'}, 'steps': [{'ar': 'a', 'en': 'a'}]},
        {'id': 'new-one', 'category': 'everyday', 'name': {'ar': 'جديدة', 'en': 'New'}, 'image': 'http://evil/x.png', 'steps': [{'ar': 'a', 'en': 'a'}]},
        {'id': 'orphan', 'category': 'nope', 'name': {'ar': 'x', 'en': 'x'}, 'steps': [{'ar': 'a', 'en': 'a'}]},
        {'id': 'broken'},
      ],
    });
    final remote = StyleRepository.parseFeed(remoteRaw, remote: true)!;
    final merged = StyleRepository.merge(bundled, remote);
    expect(merged.styles.length, bundled.styles.length + 1);
    final added = merged.styles.firstWhere((s) => s.id == 'new-one');
    expect(added.image, isNull);
    expect(added.isRemote, isTrue);
    expect(merged.styles.firstWhere((s) => s.id == 'classic-wrap').name.en, 'Classic Wrap');
    expect(StyleRepository.parseFeed(jsonEncode({'schema': 99, 'styles': []}), remote: true), isNull);
    expect(StyleRepository.parseFeed('not json', remote: true), isNull);
  });

  test('style of the day is stable within a day and visits every style once per cycle', () {
    final styles = StyleRepository.parseFeed(raw, remote: false)!.styles;
    final d = DateTime(2026, 10, 24);
    expect(styleOfTheDay(styles, d)!.id, styleOfTheDay(styles, DateTime(2026, 10, 24, 23, 59))!.id);
    final seen = {for (var i = 0; i < styles.length; i++) styleOfTheDay(styles, d.add(Duration(days: i)))!.id};
    expect(seen.length, styles.length);
    expect(styleOfTheDay(const [], d), isNull);
  });

  test('search normalises Arabic and matches tags', () {
    final styles = StyleRepository.parseFeed(raw, remote: false)!.styles;
    HijabStyle byId(String id) => styles.firstWhere((s) => s.id == id);
    expect(normalizeForSearch('الإطلالة'), 'الاطلاله');
    expect(styleMatches(byId('classic-wrap'), 'الكلاسيكيه'), isTrue);
    expect(styleMatches(byId('classic-wrap'), 'CLASSIC'), isTrue);
    expect(styleMatches(byId('modern-turban'), 'بلا دبابيس', tagLabel: (t) => t == 'no-pins' ? 'بلا دبابيس' : t), isTrue);
    expect(styleMatches(byId('classic-wrap'), 'تربان'), isFalse);
  });
}
