import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final favs = app.favoriteStyles;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Text(s.navFavorites, style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        if (favs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.favorite_outline_rounded,
              title: s.favoritesEmpty,
              body: s.favoritesEmptyHint,
              action: s.browseStyles,
              onAction: () => ShellScope.of(context).go(1),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            sliver: StyleGrid(styles: favs, heroPrefix: 'fav'),
          ),
      ]),
    );
  }
}
