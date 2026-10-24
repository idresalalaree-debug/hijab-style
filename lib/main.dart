import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads/ads.dart';
import 'app.dart';
import 'data/style_repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(prefs, StyleRepository(prefs));
  await state.load();
  runApp(HijabStyleApp(state: state));
  // Optional: pick up new styles from the remote feed; silently ignored offline.
  state.refreshRemote();
  Ads.instance.start();
}

Stream<LicenseEntry> _fontLicenses() async* {
  for (final (pkg, file) in [
    ('Tajawal', 'tajawal'),
    ('El Messiri', 'elmessiri'),
    ('Playfair Display', 'playfairdisplay'),
  ]) {
    yield LicenseEntryWithLineBreaks([pkg], await rootBundle.loadString('assets/licenses/OFL-$file.txt'));
  }
}
