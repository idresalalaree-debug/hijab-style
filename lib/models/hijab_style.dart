import 'package:flutter/widgets.dart';

/// Bilingual text: {"ar": "...", "en": "..."}. Falls back to the other language.
class LText {
  final String ar;
  final String en;
  const LText(this.ar, this.en);

  factory LText.fromJson(Object? json) {
    if (json is Map) {
      final ar = (json['ar'] ?? '').toString();
      final en = (json['en'] ?? '').toString();
      return LText(ar.isEmpty ? en : ar, en.isEmpty ? ar : en);
    }
    final s = (json ?? '').toString();
    return LText(s, s);
  }

  Map<String, String> toJson() => {'ar': ar, 'en': en};

  String of(Locale l) => l.languageCode == 'ar' ? ar : en;
  bool get isEmpty => ar.isEmpty && en.isEmpty;
}

class Category {
  final String id;
  final LText name;
  final String icon;
  const Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: LText.fromJson(j['name']),
        icon: (j['icon'] ?? 'spark') as String,
      );
}

class PhotoCredit {
  final String photographer;
  final String source;
  final String license;
  final String url;
  const PhotoCredit({required this.photographer, required this.source, required this.license, required this.url});

  /// "Name · Source", or just the source when the photographer's name is unknown.
  String get label => [photographer, source].where((e) => e.isNotEmpty).join(' · ');

  static PhotoCredit? fromJson(Object? j) {
    if (j is! Map) return null;
    return PhotoCredit(
      photographer: (j['photographer'] ?? '').toString(),
      source: (j['source'] ?? '').toString(),
      license: (j['license'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
    );
  }
}

class HijabStyle {
  final String id;
  final String categoryId;
  final LText name;
  final LText summary;
  final LText fabrics;

  /// 1 = easy, 2 = medium, 3 = advanced.
  final int difficulty;
  final int minutes;
  final int pins;
  final List<LText> steps;
  final List<LText> tips;
  final List<String> tags;

  /// Asset path (bundled) or https URL (remote styles). Null → designed fallback card.
  final String? image;
  final PhotoCredit? credit;

  /// The photo shows a general hijab look, not this exact wrap.
  final bool illustrative;
  final bool isRemote;

  const HijabStyle({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.summary,
    required this.fabrics,
    required this.difficulty,
    required this.minutes,
    required this.pins,
    required this.steps,
    required this.tips,
    required this.tags,
    this.image,
    this.credit,
    this.illustrative = false,
    this.isRemote = false,
  });

  bool get hasImage => image != null && image!.isNotEmpty;
  bool get isNetworkImage => hasImage && image!.startsWith('https://');

  /// Returns null when the entry is malformed, so one bad remote item can't break the app.
  static HijabStyle? tryParse(Map<String, dynamic> j, {bool remote = false}) {
    try {
      final steps = (j['steps'] as List).map(LText.fromJson).where((s) => !s.isEmpty).toList();
      final id = j['id'] as String;
      if (id.isEmpty || steps.isEmpty) return null;
      final image = j['image'] as String?;
      // Remote entries may only point at https images; bundled ones only at assets.
      final validImage = image == null
          ? null
          : remote
              ? (image.startsWith('https://') ? image : null)
              : (image.startsWith('assets/') ? image : null);
      return HijabStyle(
        id: id,
        categoryId: j['category'] as String,
        name: LText.fromJson(j['name']),
        summary: LText.fromJson(j['summary']),
        fabrics: LText.fromJson(j['fabrics']),
        difficulty: ((j['difficulty'] ?? 1) as num).toInt().clamp(1, 3),
        minutes: ((j['minutes'] ?? 3) as num).toInt(),
        pins: ((j['pins'] ?? 0) as num).toInt(),
        steps: steps,
        tips: ((j['tips'] ?? const []) as List).map(LText.fromJson).toList(),
        tags: ((j['tags'] ?? const []) as List).map((e) => e.toString()).toList(),
        image: validImage,
        credit: PhotoCredit.fromJson(j['credit']),
        illustrative: j['illustrative'] == true,
        isRemote: remote,
      );
    } catch (_) {
      return null;
    }
  }
}
