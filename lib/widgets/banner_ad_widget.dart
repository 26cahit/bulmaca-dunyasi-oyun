import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  bool _isAdLoaded = false;
  bool _isLoadingAd = false;

  int? _lastWidth;

  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double screenWidth = MediaQuery.sizeOf(context).width;

    final int adWidth = screenWidth.floor();

    if (_lastWidth == adWidth) {
      return;
    }

    _lastWidth = adWidth;

    _loadAdaptiveBanner(adWidth);
  }

  Future<void> _loadAdaptiveBanner(int adWidth) async {
    if (_isLoadingAd) {
      return;
    }

    _isLoadingAd = true;

    final BannerAd? oldBannerAd = _bannerAd;

    _bannerAd = null;

    if (mounted) {
      setState(() {
        _isAdLoaded = false;
      });
    }

    await oldBannerAd?.dispose();

    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);

    if (!mounted) {
      _isLoadingAd = false;
      return;
    }

    if (adaptiveSize == null) {
      _isLoadingAd = false;
      return;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId,
      request: const AdRequest(),
      size: adaptiveSize,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
            _isLoadingAd = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();

          _isLoadingAd = false;

          if (!mounted) {
            return;
          }

          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });

          debugPrint('BANNER REKLAM YÜKLENEMEDİ: $error');
        },
      ),
    );

    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;

    if (!_isAdLoaded || bannerAd == null) {
      return const SizedBox(height: 0);
    }

    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    final double adHeight = bannerAd.size.height.toDouble();

    return Container(
      width: double.infinity,
      height: adHeight + bottomPadding,
      color: const Color(0xFF0F172A),
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: adHeight,
        child: AdWidget(ad: bannerAd),
      ),
    );
  }
}
