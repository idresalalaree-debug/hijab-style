import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    final withPhoto = app.styles.where((e) => e.credit != null && e.credit!.photographer.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.credits)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        for (final st in withPhoto)
          ListTile(
            title: Text(st.name.of(locale)),
            subtitle: Text('${st.credit!.photographer} · ${st.credit!.source} · ${st.credit!.license}\n${st.credit!.url}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            isThreeLine: true,
          ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.font_download_outlined),
          title: const Text('Tajawal · El Messiri · Playfair Display'),
          subtitle: Text(s.fontsLicense),
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined),
          title: Text(s.noPhotoNote),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(MaterialLocalizations.of(context).licensesPageTitle),
          onTap: () => showLicensePage(context: context, applicationName: s.appName),
        ),
      ]),
    );
  }
}
