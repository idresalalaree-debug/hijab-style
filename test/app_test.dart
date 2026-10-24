import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijab_style/app.dart';
import 'package:hijab_style/data/style_repository.dart';
import 'package:hijab_style/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> makeState([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final s = AppState(p, StyleRepository(p));
  await s.load();
  return s;
}

/// Reduced motion makes pumpAndSettle terminate (the style-of-day badge shimmers forever otherwise).
Future<void> pumpApp(WidgetTester tester, AppState state) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(HijabStyleApp(state: state));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Arabic UI is right-to-left and shows the style of the day', (tester) async {
    final state = await makeState({'locale': 'ar'});
    await pumpApp(tester, state);
    expect(find.text('لفة اليوم'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('لفة اليوم'))), TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('English: favorite persists and appears in Favorites tab', (tester) async {
    final state = await makeState({'locale': 'en'});
    await pumpApp(tester, state);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
    state.toggleFavorite('neck-wrap');
    await tester.pumpAndSettle();
    expect(find.text('Neck Wrap'), findsOneWidget);
    expect(state.prefs.getStringList('favorites'), ['neck-wrap']);
  });

  testWidgets('Explore search filters and shows empty state', (tester) async {
    final state = await makeState({'locale': 'en'});
    await pumpApp(tester, state);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'turban');
    await tester.pumpAndSettle();
    expect(find.text('Modern Turban'), findsOneWidget);
    expect(find.text('1 style'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching styles'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('${state.styles.length} styles'), findsOneWidget);
  });

  testWidgets('Follow mode walks all steps and marks the style as tried', (tester) async {
    final state = await makeState({'locale': 'en'});
    await pumpApp(tester, state);
    final style = state.byId('neck-wrap')!;
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'neck wrap');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neck Wrap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start step by step'));
    await tester.pumpAndSettle();
    for (var i = 1; i <= style.steps.length; i++) {
      expect(find.text('Step $i of ${style.steps.length}'), findsOneWidget);
      await tester.tap(find.text(i == style.steps.length ? 'Done' : 'Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Well done!'), findsOneWidget);
    await tester.tap(find.text('Yes, mark as tried'));
    await tester.pumpAndSettle();
    expect(state.isTried('neck-wrap'), isTrue);
    expect(state.triedCount, 1);
  });

  testWidgets('Dark mode setting applies', (tester) async {
    final state = await makeState({'locale': 'en', 'theme_mode': 'dark'});
    await pumpApp(tester, state);
    expect(Theme.of(tester.element(find.text('Style of the day'))).brightness, Brightness.dark);
  });

  testWidgets('full-motion home renders without errors', (tester) async {
    final state = await makeState({'locale': 'ar'});
    await tester.pumpWidget(HijabStyleApp(state: state));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });
}
