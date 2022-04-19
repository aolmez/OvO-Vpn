// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:line_icons/line_icons.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/model/noti.dart';

class NotificationUI extends StatefulWidget {
  const NotificationUI({Key? key}) : super(key: key);

  @override
  State<NotificationUI> createState() => _NotificationUIState();
}

class _NotificationUIState extends State<NotificationUI> {
  // Admob
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Notification"),
        ),
        body: Container());
  }

  // return Column(
  //           children: [
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: data.size,
  //                 itemBuilder: (context, index) {
  //                   return item(noti: data.docs[index].data());
  //                 },
  //               ),
  //             ),
  //             (_bannerAdIsLoaded && _bannerAd != null)
  //                 ? SizedBox(
  //                     height: bannerAd!.size.height.toDouble(),
  //                     width: bannerAd.size.width.toDouble(),
  //                     child: AdWidget(ad: _bannerAd!))
  //                 : const SizedBox()
  //           ],
  //         );

  Widget item({required Noti noti}) {
    return GestureDetector(
      onTap: () async {
        //
      },
      child: Container(
        // padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top: 5, left: 8, right: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey.shade200),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 8, right: 8, top: 5),
          title: Text(
            noti.title!,
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 5,
              ),
              Text(noti.context!),
              const SizedBox(
                height: 3,
              ),
              Text(noti.time ?? ""),
            ],
          ),
          trailing: const Icon(
            LineIcons.bellAlt,
            color: Colors.red,
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
    // ignore: todo
    // TODO: implement dispose
    super.dispose();
    if (Platform.isAndroid) {
      _bannerAd?.dispose();
    }
  }
}
