import 'package:flutter/material.dart';

import '../data/style_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/style_image.dart';
import 'home_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;
  const ExploreScreen({super.key, this.initialCategory});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _query = TextEditingController();
  late String? _category = widget.initialCategory;
  int? _difficulty;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
        _query.clear();
        _category = null;
        _difficulty = null;
      });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final results = app.styles
        .where((st) =>
            (_category == null || st.categoryId == _category) &&
            (_difficulty == null || st.difficulty == _difficulty) &&
            styleMatches(st, _query.text, tagLabel: s.tag))
        .toList();
    final filtered = _category != null || _difficulty != null || _query.text.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(s.navExplore, style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: s.clearFilters,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_query.clear),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ChoiceChip(
                    label: Text(s.all),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final c in app.categories) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(categoryIcon(c.icon), size: 18),
                      label: Text(c.name.of(locale)),
                      selected: _category == c.id,
                      onSelected: (v) => setState(() => _category = v ? c.id : null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                for (final d in [1, 2, 3]) ...[
                  FilterChip(
                    label: Text(s.difficulty(d)),
                    selected: _difficulty == d,
                    onSelected: (v) => setState(() => _difficulty = v ? d : null),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(s.resultsCount(results.length), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: s.noResults,
                body: s.noResultsHint,
                action: filtered ? s.clearFilters : null,
                onAction: _clear,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: StyleGrid(styles: results, heroPrefix: 'explore'),
            ),
        ],
      ),
    );
  }
}
