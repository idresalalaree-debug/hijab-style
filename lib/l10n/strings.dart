import 'package:flutter/widgets.dart';

/// Lightweight bilingual strings (no codegen). Access with `S.of(context)`.
class S {
  final Locale locale;
  const S(this.locale);

  static const supported = [Locale('ar'), Locale('en')];

  static S of(BuildContext context) => S(Localizations.localeOf(context));

  bool get isAr => locale.languageCode == 'ar';
  String _t(String ar, String en) => isAr ? ar : en;

  String get appName => _t('حجاب ستايل', 'Hijab Style');
  String get tagline => _t('لفّتكِ المثالية، خطوة بخطوة', 'Your perfect wrap, step by step');

  // Navigation
  String get navHome => _t('الرئيسية', 'Home');
  String get navExplore => _t('استكشفي', 'Explore');
  String get navFavorites => _t('المفضلة', 'Favorites');
  String get navSettings => _t('الإعدادات', 'Settings');

  // Home
  String get styleOfDay => _t('لفة اليوم', 'Style of the day');
  String get categories => _t('الأقسام', 'Categories');
  String get quickStyles => _t('سريعة وسهلة', 'Quick & easy');
  String get occasionStyles => _t('للمناسبات', 'For occasions');
  String get allStyles => _t('كل اللفات', 'All styles');
  String get seeAll => _t('عرض الكل', 'See all');
  String triedProgress(int n, int total) => _t('جرّبتِ $n من $total لفة', 'You tried $n of $total styles');
  String get startNow => _t('ابدئي الآن', 'Start now');
  String greeting(int hour) => hour < 12
      ? _t('صباح الأناقة', 'Good morning, beautiful')
      : hour < 18
          ? _t('نهارك أنيق', 'Good afternoon')
          : _t('مساء الأناقة', 'Good evening');

  // Explore
  String get searchHint => _t('ابحثي باسم اللفة أو القماش…', 'Search by style or fabric…');
  String get all => _t('الكل', 'All');
  String get noResults => _t('لا توجد لفات مطابقة', 'No matching styles');
  String get noResultsHint => _t('جرّبي كلمة أخرى أو امسحي الفلاتر', 'Try another word or clear the filters');
  String get clearFilters => _t('مسح الفلاتر', 'Clear filters');
  String resultsCount(int n) => _t('$n لفة', n == 1 ? '1 style' : '$n styles');

  // Style meta
  String difficulty(int d) => switch (d) {
        1 => _t('سهلة', 'Easy'),
        2 => _t('متوسطة', 'Medium'),
        _ => _t('متقدمة', 'Advanced'),
      };
  String minutes(int m) => _t('$m د', '$m min');
  String pins(int p) => p == 0 ? _t('بلا دبابيس', 'No pins') : _t('$p دبابيس', '$p pins');
  String get fabric => _t('القماش المناسب', 'Best fabric');
  String get steps => _t('الخطوات', 'Steps');
  String get tips => _t('نصائح', 'Tips');
  String stepOf(int i, int n) => _t('الخطوة $i من $n', 'Step $i of $n');
  String get followMode => _t('ابدئي خطوة بخطوة', 'Start step by step');
  String get photoBy => _t('تصوير', 'Photo by');
  String get addFavorite => _t('أضيفي للمفضلة', 'Add to favorites');
  String get removeFavorite => _t('إزالة من المفضلة', 'Remove from favorites');
  String get share => _t('مشاركة', 'Share');
  String get markTried => _t('جرّبتها', 'I tried it');
  String get tried => _t('جرّبتِها ✓', 'Tried ✓');
  String get newBadge => _t('جديدة', 'New');

  // Follow mode
  String get next => _t('التالي', 'Next');
  String get previous => _t('السابق', 'Previous');
  String get finish => _t('انتهيت', 'Done');
  String get wellDone => _t('أحسنتِ!', 'Well done!');
  String get wellDoneBody => _t('لفّتكِ جاهزة. هل نسجّلها ضمن اللفات التي جرّبتِها؟', 'Your wrap is ready. Mark it as tried?');
  String get yesMark => _t('نعم، سجّليها', 'Yes, mark as tried');
  String get backToStyle => _t('العودة للّفة', 'Back to style');
  String get screenStaysOn => _t('الشاشة ستبقى مضاءة أثناء المتابعة', 'Screen stays on while you follow');

  // Share
  String get shareTitle => _t('شاركي اللفة', 'Share this style');
  String get shareAsImage => _t('مشاركة كصورة', 'Share as image');
  String shareText(String name) => _t('جرّبي لفة "$name" من تطبيق حجاب ستايل', 'Try the "$name" style from the Hijab Style app');
  String get shareFailed => _t('تعذّرت المشاركة، حاولي مرة أخرى', 'Could not share, please try again');

  // Favorites
  String get favoritesEmpty => _t('لا توجد مفضلات بعد', 'No favorites yet');
  String get favoritesEmptyHint => _t('اضغطي على القلب في أي لفة لتجديها هنا', 'Tap the heart on any style to keep it here');
  String get browseStyles => _t('تصفّحي اللفات', 'Browse styles');

  // Settings
  String get language => _t('اللغة', 'Language');
  String get appearance => _t('المظهر', 'Appearance');
  String get themeSystem => _t('حسب الجهاز', 'System');
  String get themeLight => _t('فاتح', 'Light');
  String get themeDark => _t('ليلي', 'Dark');
  String get myProgress => _t('تقدّمي', 'My progress');
  String get resetProgress => _t('إعادة تعيين التقدّم', 'Reset progress');
  String get resetConfirm => _t('سيتم مسح علامة "جرّبتها" من كل اللفات.', 'This clears the "tried" mark from all styles.');
  String get cancel => _t('إلغاء', 'Cancel');
  String get confirm => _t('تأكيد', 'Confirm');
  String get credits => _t('حقوق الصور والخطوط', 'Photo & font credits');
  String get privacyOptions => _t('خيارات الخصوصية والإعلانات', 'Privacy & ad choices');
  String get privacyPolicy => _t('سياسة الخصوصية', 'Privacy policy');
  String get about => _t('عن التطبيق', 'About');
  String get version => _t('الإصدار', 'Version');
  String get offlineNote => _t('كل اللفات متاحة بدون إنترنت', 'All styles work offline');
  String get checkNewStyles => _t('البحث عن لفات جديدة', 'Check for new styles');
  String get upToDate => _t('لديكِ أحدث اللفات', 'You have the latest styles');
  String get newStylesAdded => _t('أُضيفت لفات جديدة', 'New styles added');
  String get fontsLicense => _t('الخطوط مرخّصة بموجب SIL Open Font License 1.1', 'Fonts licensed under the SIL Open Font License 1.1');
  String get noPhotoNote => _t('لفات بلا صورة تُعرض ببطاقة مصمّمة', 'Styles without a photo use a designed card');

  String tag(String id) => switch (id) {
        'work' => _t('عمل', 'Work'),
        'summer' => _t('صيف', 'Summer'),
        'occasion' => _t('مناسبة', 'Occasion'),
        'glasses' => _t('نظارات', 'Glasses'),
        'no-pins' => _t('بلا دبابيس', 'No pins'),
        'full-coverage' => _t('ساترة', 'Full coverage'),
        'sport' => _t('رياضة', 'Sport'),
        'wedding' => _t('زفاف', 'Wedding'),
        _ => id,
      };
}
