import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  int _coins = 0;

  // ⭐ Test Ad IDs (Google recommended)
  final String _bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String _interstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  final String _rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

 @override
  void initState() {
    super.initState();

    //  initialize the SDK before loading ads!
    MobileAds.instance.initialize().then((InitializationStatus status) {
      print('Initialization done: ${status.adapterStatuses}');
      
      
      _loadBannerAd();
      _loadInterstitialAd();
      _loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // ---------------- LOAD ADS ----------------

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isBannerAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          Fluttertoast.showToast(msg: "Banner ad failed to load");
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          Fluttertoast.showToast(msg: "Failed to load interstitial ad");
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) {
          Fluttertoast.showToast(msg: "Failed to load rewarded ad");
        },
      ),
    );
  }

  // ---------------- SHOW ADS ----------------

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      Fluttertoast.showToast(msg: "Interstitial ad not loaded yet, Please wait a second and try again");
      return;
    }
    _interstitialAd!.show();
    _interstitialAd = null;
    _loadInterstitialAd();
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      Fluttertoast.showToast(msg: "Rewarded ad not loaded, Please wait a second and try again");
      return;
    }
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        setState(() => _coins += reward.amount.toInt());
        Fluttertoast.showToast(msg: "+${reward.amount} Coins earned!");
      },
    );
    _rewardedAd = null;
    _loadRewardedAd();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      appBar: AppBar(
        title: const Text(
          'Ads Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF46D3A),
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Coins Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Your Coins",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_coins',
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF46D3A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Buttons
            ElevatedButton(
              onPressed: _showInterstitialAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF46D3A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Show Interstitial Ad',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _showRewardedAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF46D3A),
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFFF46D3A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Watch Ad for Coins',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _isBannerAdLoaded
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox(),
    );
  }
}
