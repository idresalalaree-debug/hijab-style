import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad unit ids come from `--dart-define`; the defaults are Google's public test units,
/// so debug builds never request live ads.
class AdIds {
  static const _banner = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static String get banner => _banner.isEmpty ? 'ca-app-pub-3940256099942544/9214589741' : _banner;
  static String get interstitial => _interstitial.isEmpty ? 'ca-app-pub-3940256099942544/1033173712' : _interstitial;
}

/// Consent (UMP) first, then the Mobile Ads SDK. Ads only run on Android.
class Ads {
  Ads._();
  static final instance = Ads._();

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final ready = ValueNotifier<bool>(false);
  final privacyOptionsRequired = ValueNotifier<bool>(false);
  bool _started = false;

  InterstitialAd? _interstitial;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  int _completions = 0;
  static const _minGap = Duration(minutes: 4);

  Future<void> start() async {
    if (!supported || _started) return;
    _started = true;
    // Consent from a previous session lets ads start without waiting for the network.
    if (await ConsentInformation.instance.canRequestAds()) await _initSdk();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) async {
          if (await ConsentInformation.instance.canRequestAds()) await _initSdk();
          privacyOptionsRequired.value = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
        });
      },
      (_) {}, // Offline or blocked: keep the app ad-free for this session.
    );
  }

  Future<void> _initSdk() async {
    if (ready.value) return;
    await MobileAds.instance.initialize();
    ready.value = true;
    _loadInterstitial();
  }

  Future<void> showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((_) {});

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Called when a follow-mode session ends. Shows at most one interstitial every few minutes,
  /// never on the first completion, and never in the middle of steps.
  void onTutorialFinished() {
    _completions++;
    final ad = _interstitial;
    if (!ready.value || ad == null || _completions < 2) return;
    if (DateTime.now().difference(_lastInterstitial) < _minGap) return;
    _interstitial = null;
    _lastInterstitial = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}

/// Inline adaptive banner; takes no space until an ad has actually loaded.
class InlineBanner extends StatefulWidget {
  const InlineBanner({super.key});
  @override
  State<InlineBanner> createState() => _InlineBannerState();
}

class _InlineBannerState extends State<InlineBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    Ads.instance.ready.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_requested || !Ads.instance.ready.value || !mounted) return;
    _requested = true;
    final width = MediaQuery.sizeOf(context).width.truncate() - 32;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    Ads.instance.ready.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad)),
      ),
    );
  }
}
