// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/model/vpn.dart';

import 'home_ui.dart';

class ServerListUI extends StatefulWidget {
  const ServerListUI({Key? key}) : super(key: key);

  @override
  State<ServerListUI> createState() => _ServerListUIState();
}

final vpnsRef =
    FirebaseFirestore.instance.collection('vpnServer').withConverter<Vpn>(
          fromFirestore: (snapshots, _) => Vpn.fromJson(snapshots.data()!),
          toFirestore: (vpn, _) => vpn.toJson(),
        );

class _ServerListUIState extends State<ServerListUI> {
  VpnController vpnController = Get.find();

  // Admob
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  static const AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? AdmobConfig.interstitialIdIAndroid
            : 'ca-app-pub-3940256099942544/4411468910',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Server"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Vpn>>(
        stream: vpnsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.requireData;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    return item(vpn: data.docs[index].data());
                  },
                ),
              ),
              (_bannerAdIsLoaded && _bannerAd != null)
                  ? SizedBox(
                      height: bannerAd!.size.height.toDouble(),
                      width: bannerAd.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!))
                  : SizedBox()
            ],
          );
        },
      ),
    );
  }

  Widget item({required Vpn vpn}) {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        String vpndata = jsonEncode(vpn);
        print(vpndata);
        await prefs.setString('vpnData', vpndata);
        await prefs.setBool('haveVpn', true);
        vpnController.getVPN();
        _showInterstitialAd();
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top: 5, left: 8, right: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 5),
          leading: Image.asset("assets/flag/${vpn.cod}.png", height: 35),
          title: Text(
            vpn.serverName!,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Platform.isAndroid) {
      _bannerAd = BannerAd(
          size: AdSize.banner,
          adUnitId: Platform.isAndroid
              ? AdmobConfig.bannerIdAndroid
              : 'ca-app-pub-3940256099942544/2934735716',
          listener: BannerAdListener(
            onAdLoaded: (Ad ad) {
              print('$BannerAd loaded.');
              setState(() {
                _bannerAdIsLoaded = true;
              });
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              print('$BannerAd failedToLoad: $error');
              ad.dispose();
            },
            onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
            onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
          ),
          request: const AdRequest())
        ..load();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (Platform.isAndroid) {
      _bannerAd?.dispose();
    }
  }
}
