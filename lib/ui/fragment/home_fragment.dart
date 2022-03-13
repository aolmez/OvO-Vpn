// ignore_for_file: unused_local_variable, avoid_print, unused_element, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn/Router/route.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/controller/update_controller.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/model/vpn.dart';

const String testDevice = '64A17126E86385C49F5365F1FB0E3508';
const int maxFailedLoadAttempts = 3;

class HomeFragment extends StatefulWidget {
  const HomeFragment({Key? key}) : super(key: key);

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  UpdateController controller = Get.put(UpdateController());

  static const AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;
  bool _granted = false;

  // Admob
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  @override
  void initState() {
    engine = OpenVPN(
      onVpnStatusChanged: (data) {
        setState(() {
          status = data;
        });
      },
      onVpnStageChanged: (data, raw) {
        setState(() {
          stage = data;
        });
      },
    );
    engine.initialize(
        groupIdentifier: "group.com.laskarmedia.vpn",
        providerBundleIdentifier:
            "id.laskarmedia.openvpnFlutterExample.VPNExtension",
        localizedDescription: "VPN by OvO God");
    super.initState();
    controller.onInit();
    _createRewardedAd();
  }

  Future<void> initPlatformState({required Vpn vpn}) async {
    engine.connect(
        utf8.fuse(base64).decode(vpn.config!), vpn.serverName ?? "OvO Server",
        username: vpn.username, password: vpn.password);
    if (!mounted) return;
  }

  formatBytes(bytes) {
    var marker = 1024; // Change to 1000 if required
    var decimal = 3; // Change as required
    var kiloBytes = marker; // One Kilobyte is 1024 bytes
    var megaBytes = marker * marker; // One MB is 1024 KB
    var gigaBytes = marker * marker * marker; // One GB is 1024 MB
    var teraBytes = marker * marker * marker * marker; // One TB is 1024 GB

    // return bytes if less than a KB
    if (bytes < kiloBytes) {
      return bytes + " Bytes";
    } else if (bytes < megaBytes) {
      return (bytes / kiloBytes).toStringAsFixed(decimal) + " KB";
    } else if (bytes < gigaBytes) {
      return (bytes / megaBytes).toStringAsFixed(decimal) + " MB";
    } else {
      return (bytes / gigaBytes).toStringAsFixed(decimal) + " GB";
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? AdmobConfig.videoAdIdIAndroid
            : 'ca-app-pub-3940256099942544/1712485313',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
    });
    _rewardedAd = null;
  }

  void connect({required VpnController controller}) {
    if (controller.haveVpn == true) {
      if (_granted == null) {
        engine.requestPermissionAndroid().then((value) {
          setState(() {
            _granted = value;
          });
        });
      }
      if (stage.toString() == VPNStage.disconnected.toString() ||
          stage.toString() == "null") {
        initPlatformState(vpn: controller.vpn!);
        _showRewardedAd();
      } else {
        Get.defaultDialog(
          titlePadding: const EdgeInsets.only(top: 10, bottom: 10),
          contentPadding:
              const EdgeInsets.only(top: 10, bottom: 10, right: 15, left: 15),
          title: "Warning:",
          middleText: "The connection will be disconnected.",
          middleTextStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          textConfirm: "Confirm",
          textCancel: "Cancel",
          radius: 8,
          onConfirm: () {
            engine.disconnect();
            Get.back();
          },
          onCancel: () {
            //
            Get.back();
          },
          buttonColor: Colors.red,
        );
      }
    } else {
      Get.toNamed(VPNRoute.serverlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    dynamic currentTime = DateFormat().format(DateTime.now());
    dynamic cur = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OvO VPN',
              style: TextStyle(color: Colors.black),
            ),
            IconButton(
              icon: const Icon(LineIcons.bellAlt),
              onPressed: () {
                Get.toNamed(VPNRoute.notilist);
                print("datea : $cur");
                // FirebaseFirestore.instance.collection("notiHistory").doc("$cur").set(
                //   {
                //     "title": "Server Alart",
                //     "subtitle": "server_alart",
                //     "context": "If the connection is not good, switch servers",
                //     "image": "",
                //     "type": "server,alart",
                //     "time": "$currentTime"
                //   },
                // );
              },
            ),

            // GestureDetector(
            //   onTap: () {
            // FirebaseFirestore.instance.collection("vpnServer").add({
            //   "server_name": "Hong Kong - 4 (Beta)",
            //   "cod": "HK",
            //   "config":
            //       "config",
            //   "username": "ovo",
            //   "password": "123456"
            // }).then((value) {
            //   print(value.id);
            // });
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(children: [
            //
            GetBuilder<VpnController>(
              init: VpnController(),
              builder: (controller) {
                return GestureDetector(
                  onTap: (() => connect(controller: controller)),
                  child: Card(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/icon/map.png'),
                            opacity: 0.08,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                        margin: const EdgeInsets.all(5),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                height: 80,
                                child: Image.asset(
                                  (stage.toString() ==
                                          VPNStage.connected.toString())
                                      ? "assets/icon/vpn.png"
                                      : "assets/icon/vpn_off.png",
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.north_sharp,
                                        size: 15,
                                      ),
                                      Text(
                                        "Up      : ${status?.byteOut == "0" ? "0" : formatBytes(double.parse(status!.byteIn!))}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.south_sharp,
                                        size: 15,
                                      ),
                                      Text(
                                        "Down : ${status?.byteIn == "0" ? "0" : formatBytes(double.parse(status!.byteIn!))}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 10,
                              bottom: 5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  controller.haveVpn
                                      ? Column(
                                          children: [
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10, right: 5),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Image.asset(
                                                      "assets/flag/${controller.vpn!.cod ?? "US"}.png",
                                                      height: 35),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                      (stage.toString() ==
                                                                  VPNStage
                                                                      .disconnected
                                                                      .toString() ||
                                                              stage.toString() ==
                                                                  "null")
                                                          ? "Disconnected"
                                                          : stage!.name
                                                              .toString(),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        connect(controller: controller);
                                      },
                                      child: Container(
                                        height: 45,
                                        width: 150,
                                        padding: const EdgeInsets.all(5),
                                        margin: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: (stage.toString() ==
                                                      VPNStage.disconnected
                                                          .toString() ||
                                                  stage.toString() == "null")
                                              ? Colors.grey.shade400
                                              : (stage.toString() ==
                                                      VPNStage.connected
                                                          .toString())
                                                  ? Colors.green.shade400
                                                  : Colors.green.shade200,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (stage.toString() ==
                                                            VPNStage
                                                                .disconnected
                                                                .toString() ||
                                                        stage.toString() ==
                                                            "null")
                                                    ? "Connect Now"
                                                    : (stage.toString() ==
                                                            VPNStage.connected
                                                                .toString())
                                                        ? "Connected"
                                                        : (stage.toString() ==
                                                                VPNStage
                                                                    .wait_connection
                                                                    .toString())
                                                            ? "Wating..."
                                                            : (stage.toString() ==
                                                                    VPNStage
                                                                        .vpn_generate_config
                                                                        .toString())
                                                                ? "Generate VPN"
                                                                : "Wating...",
                                                maxLines: 1,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Icon(
                                              Icons.power_settings_new,
                                              size: 23,
                                              color: (stage.toString() ==
                                                          VPNStage.disconnected
                                                              .toString() ||
                                                      stage.toString() ==
                                                          "null")
                                                  ? Colors.grey.shade800
                                                  : (stage.toString() ==
                                                          VPNStage.connected
                                                              .toString())
                                                      ? Colors.green.shade800
                                                      : Colors.white,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            (stage.toString() == VPNStage.connected.toString())
                ? GestureDetector(
                    onTap: (() => _showRewardedAd()),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 8, left: 5, right: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            LineIcons.adversal,
                            color: Colors.green,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Support Me",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.purpleAccent),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            LineIcons.adversal,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),

            _pickServer(
              icon: Icons.location_on,
              text: "Pick Your Server",
              onTap: () {
                if (stage.toString() == VPNStage.disconnected.toString() ||
                    stage.toString() == "null") {
                  Get.toNamed(VPNRoute.serverlist);
                } else {
                  Get.defaultDialog(
                    titlePadding: const EdgeInsets.only(top: 10, bottom: 10),
                    contentPadding: const EdgeInsets.only(
                        top: 10, bottom: 10, right: 15, left: 15),
                    title: "Warning:",
                    middleText: "The connection will be disconnected.",
                    middleTextStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                    textConfirm: "Confirm",
                    textCancel: "Cancel",
                    radius: 8,
                    onConfirm: () {
                      engine.disconnect();
                      Get.back();
                    },
                    onCancel: () {
                      //
                      Get.back();
                    },
                    buttonColor: Colors.red,
                  );
                }
              },
            ),
          ]),
          Positioned(
              bottom: 10,
              left: 5,
              right: 5,
              child: (_bannerAdIsLoaded && _bannerAd != null)
                  ? SizedBox(
                      height: bannerAd!.size.height.toDouble(),
                      width: bannerAd.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!))
                  : const SizedBox())
        ],
      ),
    );
  }

  Widget _pickServer(
      {required IconData icon, required String text, required Function onTap}) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        child: SizedBox(
          height: 50,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.green,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "Pick Your Server",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newAlart() {
    // 11 am - 11 pm US Server is Donwn
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.red.shade200,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "US Server is Down",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Get.back();
                },
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            "The server is down. Please try again later.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
