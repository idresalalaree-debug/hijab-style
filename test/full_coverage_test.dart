import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijab_style/screens/credits_screen.dart';
import 'package:hijab_style/screens/follow_mode_screen.dart';
import 'package:hijab_style/screens/style_detail_screen.dart';
import 'package:hijab_style/widgets/share_sheet.dart';

import 'app_test.dart' show makeState, pumpApp;

/// Walks every screen and every style on small phones with large text, in both languages
/// and both themes. Any overflow, assertion or exception fails the test.
void main() {
  // (logical width, height, text scale): a 320 dp phone at 130 % and a 360 dp phone at Android's max 200 %.
  for (final (w, h, scale) in [(320.0, 568.0, 1.3), (360.0, 740.0, 2.0)]) {
    for (final locale in ['ar', 'en']) {
      for (final theme in ['light', 'dark']) {
        testWidgets(
          'all 50 styles: detail, share sheet and full follow mode ($locale/$theme, ${w.toInt()}dp @${scale}x)',
          (tester) async {
            tester.view.physicalSize = Size(w * 2, h * 2);
            tester.view.devicePixelRatio = 2;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

            final state = await makeState({'locale': locale, 'theme_mode': theme});
            await pumpApp(tester, state);
            final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
            expect(state.styles, hasLength(50));

            for (final style in state.styles) {
              nav.push(MaterialPageRoute(builder: (_) => StyleDetailScreen(styleId: style.id)));
              await tester.pumpAndSettle();
              await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -4000));
              await tester.pumpAndSettle();

              final ctx = tester.element(find.byType(StyleDetailScreen));
              showShareSheet(ctx, style);
              await tester.pumpAndSettle();
              Navigator.of(ctx).pop();
              await tester.pumpAndSettle();

              nav.push(MaterialPageRoute(builder: (_) => FollowModeScreen(styleId: style.id)));
              await tester.pumpAndSettle();
              for (var i = 0; i < style.steps.length; i++) {
                await tester.tap(find.byType(FilledButton).last);
                await tester.pumpAndSettle();
              }
              final mark = find.byIcon(Icons.check_circle_rounded); // "Yes, mark as tried"
              await tester.ensureVisible(mark);
              await tester.pumpAndSettle();
              await tester.tap(mark);
              await tester.pumpAndSettle();
              expect(state.isTried(style.id), isTrue, reason: style.id);
              nav.pop();
              await tester.pumpAndSettle();
            }
            expect(state.triedCount, 50);
            expect(tester.takeException(), isNull);
          },
        );
      }

      testWidgets('every tab, filters, settings and credits ($locale, ${w.toInt()}dp @${scale}x)', (tester) async {
        tester.view.physicalSize = Size(w * 2, h * 2);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final state = await makeState({'locale': locale});
        await pumpApp(tester, state);
        await tester.fling(find.byType(CustomScrollView).first, const Offset(0, -3000), 3000);
        await tester.pumpAndSettle();

        final tabs = find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination));
        expect(tabs, findsNWidgets(4));

        // Explore: each category chip and each difficulty chip.
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();
        for (var i = 0; i < find.byType(ChoiceChip).evaluate().length; i++) {
          await tester.ensureVisible(find.byType(ChoiceChip).at(i));
          await tester.tap(find.byType(ChoiceChip).at(i));
          await tester.pumpAndSettle();
          await tester.fling(find.byType(CustomScrollView).last, const Offset(0, -2000), 3000);
          await tester.pumpAndSettle();
          await tester.fling(find.byType(CustomScrollView).last, const Offset(0, 4000), 3000);
          await tester.pumpAndSettle();
        }
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(FilterChip).at(i));
          await tester.pumpAndSettle();
        }

        // Favorites, empty then filled.
        await tester.tap(tabs.at(2));
        await tester.pumpAndSettle();
        for (final s in state.styles.take(5)) {
          state.toggleFavorite(s.id);
        }
        await tester.pumpAndSettle();

        // Settings: every option, then credits.
        await tester.tap(tabs.at(3));
        await tester.pumpAndSettle();
        for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
          state.setThemeMode(mode);
          await tester.pumpAndSettle();
        }
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.push(MaterialPageRoute(builder: (_) => const CreditsScreen()));
        await tester.pumpAndSettle();
        await tester.fling(find.byType(Scrollable).last, const Offset(0, -5000), 3000);
        await tester.pumpAndSettle();
        nav.pop();
        await tester.pumpAndSettle();

        // Back from a non-home tab returns Home instead of closing the app.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);

        state.setLocale(locale == 'ar' ? 'en' : 'ar');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
