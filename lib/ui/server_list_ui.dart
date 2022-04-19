// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/controller/server_controller.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/model/vpn.dart';
import 'package:vpn/network/data_agent.dart';
import 'package:vpn/network/data_agent_impl.dart';
import 'package:vpn/network/response/server.dart';
import 'package:vpn/ui/fragment/home_fragment.dart';

class ServerListUI extends StatefulWidget {
  const ServerListUI({Key? key}) : super(key: key);

  @override
  State<ServerListUI> createState() => _ServerListUIState();
}


class _ServerListUIState extends State<ServerListUI> {
  VpnController vpnController = Get.find();
  final ServerController serverController = Get.put(ServerController());

  // Admob
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  int _numRewardedInterstitialLoadAttempts = 0;

  static const AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  @override
  void initState() {
    super.initState();
    _createRewardedInterstitialAd();
  }

  void _createRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? AdmobConfig.interstitialVideoIdIAndroid
            : 'ca-app-pub-3940256099942544/6978759866',
        request: request,
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            print('$ad loaded.');
            _rewardedInterstitialAd = ad;
            _numRewardedInterstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedInterstitialAd failed to load: $error');
            _rewardedInterstitialAd = null;
            _numRewardedInterstitialLoadAttempts += 1;
            if (_numRewardedInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedInterstitialAd();
            }
          },
        ));
  }

  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd == null) {
      print('Warning: attempt to show rewarded interstitial before loaded.');
      return;
    }
    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) =>
          print('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedInterstitialAd();
      },
    );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
    });
    _rewardedInterstitialAd = null;
  }

  @override
  Widget build(BuildContext context) {
    serverController.fetchServers();
    final BannerAd? bannerAd = _bannerAd;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Server"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (serverController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: serverController.servers.length,
                  itemBuilder: (context, index) {
                    return serverItem(server: serverController.servers[index]);
                  },
                ),
              ),
              (_bannerAdIsLoaded && _bannerAd != null)
                  ? SizedBox(
                      height: bannerAd!.size.height.toDouble(),
                      width: bannerAd.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!))
                  : const SizedBox()
            ],
          );
        }
      }),
    );
  }

  Widget serverItem({required Server server}) {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        String vpndata = jsonEncode(server);
        print(vpndata);
        await prefs.setString('vpnData', vpndata);
        await prefs.setBool('haveVpn', true);
        vpnController.getVPN();
        _showRewardedInterstitialAd();
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 5),
        margin: const EdgeInsets.only(top: 5, bottom: 5, left: 8, right: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey.shade200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/flag/${server.category!.code ?? "US"}.png",
                  height: 35,
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name ?? "",
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w800),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        (server.category != null)
                            ? Container(
                                padding: const EdgeInsets.only(
                                    top: 3, bottom: 3, right: 5, left: 5),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.green.shade100,
                                ),
                                child: Text(server.category?.name ?? "",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              )
                            : const SizedBox(),
                        const SizedBox(
                          width: 3.5,
                        ),
                        Text(
                          server.ip ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w400,
                              fontSize: 11),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),

            /// server status
          ],
        ),
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
          _showRewardedInterstitialAd();
          Get.back();
        },
        child: Container(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 5),
            margin: const EdgeInsets.only(top: 5, bottom: 5, left: 8, right: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey.shade200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      "assets/flag/${vpn.cod}.png",
                      height: 35,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vpn.serverName!,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w800),
                        ),
                        (vpn.source != null)
                            ? Container(
                                padding: const EdgeInsets.only(
                                    top: 3, bottom: 3, right: 5, left: 5),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.green.shade100,
                                ),
                                child: Text(vpn.source!,
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ],
                ),
                (vpn.status != null)
                    ? Container(
                        padding: const EdgeInsets.only(
                            top: 3, bottom: 3, right: 5, left: 5),
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: (vpn.status == "live" || vpn.status == "LIVE")
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                        ),
                        child: Text(vpn.status!,
                            style: TextStyle(
                                color: (vpn.status == "live" ||
                                        vpn.status == "LIVE")
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      )
                    : SizedBox(),
              ],
            )));
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
    // ignore: todo
    // TODO: implement dispose
    super.dispose();
    if (Platform.isAndroid) {
      _bannerAd?.dispose();
    }
  }
}
