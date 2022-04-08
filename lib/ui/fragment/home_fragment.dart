// ignore_for_file: unused_local_variable, avoid_print, unused_element, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/Router/route.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/controller/update_controller.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/main.dart';
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

  List<String> _events = [];

  @override
  void initState() {
    super.initState();
    initVPN();
    controller.onInit();
    _createRewardedAd();
    initPlatformStates();
  }


  initVPN() async{
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
  }


  Future<void> initVPNPlatformState({required Vpn vpn}) async {
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
        initVPNPlatformState(vpn: controller.vpn!);

        _showRewardedAd();
        _onClickEnable(true);
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

//                 FirebaseFirestore.instance.collection("notiHistory").doc("$cur").set(
//                   {
//                     "title": "Notice",
//                     "subtitle": "notice",
//                     "context": """OvO vpn's Admin Console Account is currently suspended due to payment issues.
// We have addressed credit issues but are not yet available. An appeal is made and may take at least 2 business days.
// Currently the GCP server is only available in Hong Kong 1. Updates will only be able to be made if the original accounts are now re-enabled.""",
//                     "image": "",
//                     "type": "notice,server",
//                     "time": "$currentTime"
//                   },
//                 );

                // FirebaseFirestore.instance
                //     .collection("vpnServer")
                //     .doc("HK1")
                //     .set({
                //   "server_name": "Hong Kong 1",
                //   "cod": "HK",
                //   "config": "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBUaHUgTWFyIDEwIDEwOjU4OjEwIDIwMjIgYnkgaXAtMTcyLTI2LTQtNzkuY2EtY2VudHJhbC0xLmNvbXB1dGUuaW50ZXJuYWwKCiMgRGVmYXVsdCBDaXBoZXIKY2lwaGVyIEFFUy0yNTYtQ0JDCiMgTm90ZTogdGhpcyBjb25maWcgZmlsZSBjb250YWlucyBpbmxpbmUgcHJpdmF0ZSBrZXlzCiMgICAgICAgYW5kIHRoZXJlZm9yZSBzaG91bGQgYmUga2VwdCBjb25maWRlbnRpYWwhCiMgTm90ZTogdGhpcyBjb25maWd1cmF0aW9uIGlzIHVzZXItbG9ja2VkIHRvIHRoZSB1c2VybmFtZSBiZWxvdwojIE9WUE5fQUNDRVNTX1NFUlZFUl9VU0VSTkFNRT1vcGVudnBuCiMgRGVmaW5lIHRoZSBwcm9maWxlIG5hbWUgb2YgdGhpcyBwYXJ0aWN1bGFyIGNvbmZpZ3VyYXRpb24gZmlsZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9QUk9GSUxFPW9wZW52cG5AMTUuMjIzLjEzMy43L0FVVE9MT0dJTgojIE9WUE5fQUNDRVNTX1NFUlZFUl9BVVRPTE9HSU49MQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9BTExPV19XRUJfSU1QT1JUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfQkFTSUNfQ0xJRU5UPUZhbHNlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0VOQUJMRV9DT05ORUNUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfRU5BQkxFX1hEX1BST1hZPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV1NIT1NUPTE1LjIyMy4xMzMuNzo0NDMKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVEFSVAojIC0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQojIE1JSURIRENDQWdTZ0F3SUJBZ0lFWWltZjh6QU5CZ2txaGtpRzl3MEJBUXNGQURCSE1VVXdRd1lEVlFRREREeFAKIyBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpFd0lEQTJPalV4T2pNeElGVlVReUJwY0MweE56SXRNall0CiMgTkMwM09TNWpZUzFqWlc0d0hoY05Nakl3TXpBek1EWTFNVE14V2hjTk16SXdNekEzTURZMU1UTXhXakJITVVVdwojIFF3WURWUVFERER4UGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakV3SURBMk9qVXhPak14SUZWVVF5QnAKIyBjQzB4TnpJdE1qWXROQzAzT1M1allTMWpaVzR3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCiMgQW9JQkFRQ2dvUkgvN2o0Mml2d2RraXdOMnJualg5b0VTczdDVTJrZEFWYUplblJzTk84TnVNVmxlTC83b2QvYwojIGVHa3VtdUJQdlJSVWRNZmNWaWk1ZDFOQzVKS1hkWnhUdGVDeDBoTWFHQVFVbFlUL0VxdG5heE5QSjdwcmR2aUUKIyBQeStjZFhWMEd6UnRtRXY2cFlYM2ZaVlpYbVBPQzdaOU5SSjVTbytReDg1Rk9ZekNFSllkeEMxV3crVFBGTmxsCiMgQ2pIS0FYSlRhTXhwWGJKRXhiSGJWaUh6Yk84bVQrYXl0azRubmdEZHFUU2dCd2VJb3VXdTAzS1c3THBYaGQ3MQojIHdGcjIvZ1AyY2JMRDZOdlpmMUNlMDZpR0ROUWNpYTcyN0NvaWJjMWZDM0l4U0pzSTlWZTNiLzhJQm1YUmZSbFIKIyBIMDJzaVJ1Njc2aGlrWW1oQkI1SHRZTmtCOXVuQWdNQkFBR2pFREFPTUF3R0ExVWRFd1FGTUFNQkFmOHdEUVlKCiMgS29aSWh2Y05BUUVMQlFBRGdnRUJBR1EwWk0zd084NTdZMlJ5eEdiRmtLbE1rWHlxa0RYY3hSTklpTVhxT2RvegojIDhBeUxDN3o3Znl4bFI4QzNzNjA5dHJDQ3I0NnExNmtNWktFTU5DdVc4YStNYUEyVDZDaG5jRkZjUGpUREZ1cU4KIyBjbzRoa2cvVFJCanRCbGUrZndIWkc1TnNDbklCRmlvU0xudVBUTHNtbS9lU09IMEJFK2VWeFdJNXNYL0dSQXFSCiMgR1FpdTBLNUFNWmtDTHd6MWhrYXZVRzRmZHo1OXhxY3FpcnNTanRNK3VmVk4yNU1jZTYxQUV2a2kvUzFaVXJuNwojIEd0R2FhSU5NZGM3Q1dKb1FqYXJFeVpzU2xtRFVBeXRLV1dpYmdWMWlVaHFHOVNpM2gzYXZDSWRDWVdoSjFBd1YKIyBBMmRScmhiNlN3NHM2eGpTL0xyRjZoRjlhSmtwTXY3NjZ5UDc2a3BIOFVNPQojIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVE9QCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0lTX09QRU5WUE5fV0VCX0NBPTEKIyBPVlBOX0FDQ0VTU19TRVJWRVJfT1JHQU5JWkFUSU9OPU9wZW5WUE4sIEluYy4Kc2V0ZW52IEZPUldBUkRfQ09NUEFUSUJMRSAxCmNsaWVudApzZXJ2ZXItcG9sbC10aW1lb3V0IDQKbm9iaW5kCnJlbW90ZSAxNS4yMjMuMTMzLjcgMTE5NCB1ZHAKcmVtb3RlIDE1LjIyMy4xMzMuNyAxMTk0IHVkcApyZW1vdGUgMTUuMjIzLjEzMy43IDQ0MyB0Y3AKcmVtb3RlIDE1LjIyMy4xMzMuNyAxMTk0IHVkcApyZW1vdGUgMTUuMjIzLjEzMy43IDExOTQgdWRwCnJlbW90ZSAxNS4yMjMuMTMzLjcgMTE5NCB1ZHAKcmVtb3RlIDE1LjIyMy4xMzMuNyAxMTk0IHVkcApyZW1vdGUgMTUuMjIzLjEzMy43IDExOTQgdWRwCmRldiB0dW4KZGV2LXR5cGUgdHVuCm5zLWNlcnQtdHlwZSBzZXJ2ZXIKc2V0ZW52IG9wdCB0bHMtdmVyc2lvbi1taW4gMS4wIG9yLWhpZ2hlc3QKcmVuZWctc2VjIDYwNDgwMApzbmRidWYgMTAwMDAwCnJjdmJ1ZiAxMDAwMDAKIyBOT1RFOiBMWk8gY29tbWFuZHMgYXJlIHB1c2hlZCBieSB0aGUgQWNjZXNzIFNlcnZlciBhdCBjb25uZWN0IHRpbWUuCiMgTk9URTogVGhlIGJlbG93IGxpbmUgZG9lc24ndCBkaXNhYmxlIExaTy4KY29tcC1sem8gbm8KdmVyYiAzCnNldGVudiBQVVNIX1BFRVJfSU5GTwoKPGNhPgotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJQ3VEQ0NBYUNnQXdJQkFnSUVZaW1mOGpBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwUApjR1Z1VmxCT0lFTkJNQjRYRFRJeU1ETXdNekEyTlRFek1Gb1hEVE15TURNd056QTJOVEV6TUZvd0ZURVRNQkVHCkExVUVBd3dLVDNCbGJsWlFUaUJEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUIKQUxIOTBUNnFQVHpUQ0VxYUpocWk2S005dkZBeEtUem9jQWtNZkxpZHh6QWI1VTRubUhveHE5VWp4RVF3UFFNWQpHZmFWa015aUltYjZNY25IOTJESElGQ01LbmJ2bXRrSkxBazloSTNuYzkrZ21ZTXVTS09vNlBPVWxlWDd3NzUzCjVaeEpiNVlrbUJYN1ZzRGl6MXJVT2FzVTcwSnp2SEwrQzJPNnhjRVowTHNPczNKb3N4dHQ3Z3FaWG9CdkUyQVMKTDhRR1p5YmhhQ0NlTFN2N044ckYvRkVlcTV0dmRuVG94TEQyN0ptbU84NEJZUDlUWm53Nms4RVJBQU96N1k4egpCc0Q0OGVkQmtDdzN5MzdjSy91UGxJQzMvOWs5STZESC9jUXdzYlgzWGVVTWZMdE03ZUlqa0tWaEpvN3B0MDAxCmJITUEvYmJGb0RzdzI0UFgzMnRnNG5FQ0F3RUFBYU1RTUE0d0RBWURWUjBUQkFVd0F3RUIvekFOQmdrcWhraUcKOXcwQkFRc0ZBQU9DQVFFQXBrRWlkSWErUEJUOXd0N2htODRGV1YzTUY5eFZ4ZndpemlzUkwzOWZWVldSTDNpWApCWWVIYU11Um5NcktkMUpBV3AvK2NHeGthalhUUnJCWCtpTHNaMElhelRHbHRJUXFpemt2aWVONmU1V1FVZ0ZyCjMxejBNb0JsckEybjV5d2xDZGNVOTVJRzVzNVNNdHhMY0lTaC9pK09DdFk5eHY3dzRsMi85SWlFczlRV0U2aTkKaTVIOHlQQ2l3eTVQZTZ6bnZJcHQzb0FIWmpjd0wweEdNbndmUDlmVU5WdzlickdaZGloMThPVzBjUVlEN1ZRRgpFcnJOQ0hGQnRZZ0tlaFNLaTVGTmpsUVhQVXJhY3BrWlkrY1MzZ2lSUGo2bGZpSzFVT1l2N2MzNHo3Vmo5aHhJCmlIQnNCTDRSUFdxZXRGOXBOc3ZKVVJaS0FUdnpFMzFlTnJjWkFRPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo8L2NhPgoKPGNlcnQ+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlDekRDQ0FiU2dBd0lCQWdJQkJUQU5CZ2txaGtpRzl3MEJBUXNGQURBVk1STXdFUVlEVlFRRERBcFBjR1Z1ClZsQk9JRU5CTUI0WERUSXlNRE13TXpFd05UZ3dOMW9YRFRNeU1ETXdOekV3TlRnd04xb3dIREVhTUJnR0ExVUUKQXd3UmIzQmxiblp3Ymw5QlZWUlBURTlIU1U0d2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFSwpBb0lCQVFDM05nRnc3R0ZwSXZGRnBiemJyQm5HY0cvL3BaN0wvSUNFMmFTM0g4YnE4MUVZeXNqd2hKek9QYzBMCm9ZdzZUSG9QaEVpZk1kM0k0R1NpcTJ6UWxZenhQanluK2NlUThCN2tRdkNRbWpPRkpyOXlkZkllUXgvbW9GTFIKdUY1alRGQzcvd2owdGxnK2VDdVhCZWZSS2p6U0VpMWZDeXJRN3QwWE1nNWtJVEZUOXprRTNmMEZNNVZyUFRsVgpFazZHRmZ2Sm0wOVoyRVdKMlorV1B6dTBHTTJBcmhiZ3lRM0pDckFhdWx5UUtYNlVKdkJ0OTY3TTRFVnY0ZEt0ClplVkZyVTd0S2J5SHluZlZrZFpZNzc2WnpIcy8waDBtYlEwN3I0c2hVQWVQNU00S3ZuL2RJRHdPWjk4ODhjRlUKT05mbUx0SmZRanhuMHN6bCs2c3BEbGxFZmEwVEFnTUJBQUdqSURBZU1Ba0dBMVVkRXdRQ01BQXdFUVlKWUlaSQpBWWI0UWdFQkJBUURBZ2VBTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFBcHlDbytxSkkrQlRyTTh0SzRSVmFSCnlXd2ZTa0ZBQUsrZTgyL0g2Ty9VVks0UlBMZ056cFRVdVdkYnI2TngvQUR3TG9FVElISXkweWZNbGIwUmJOeW0KbS9vYmVGTXMzV1I0b3pxZTlMTCtESU1EQXFnc0dzWDRmTzdRUFBkNDV3bDMrNGg3dTRuTlNKS2k0SkE4YXl6bApWcE4xMm1oN2psc1g0TTNHUlNOWHhBdDdaVzkvVmozbUxIVU1Ic1ZCM1Z3SFpVKzZxQnpZTDVOOXJvenhWam1uCjN0T1o4djYzc3QxMGlNbjVUdkNldmdkdFQ5ZFk5ZFZwaUR1U0EzVUhxRDY5MStUVXpSSEFEaXlCaHErNlkraloKSjk4RllxbkIzSzVsd3dCTHlOWk83Nmx6NWRiUWZwS3BzQ05oc1Z1MEVTQlVVVU5yMXpIOHJWQS9weSthV05ndwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2VydD4KCjxrZXk+Ci0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLQpNSUlFdndJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLa3dnZ1NsQWdFQUFvSUJBUUMzTmdGdzdHRnBJdkZGCnBiemJyQm5HY0cvL3BaN0wvSUNFMmFTM0g4YnE4MUVZeXNqd2hKek9QYzBMb1l3NlRIb1BoRWlmTWQzSTRHU2kKcTJ6UWxZenhQanluK2NlUThCN2tRdkNRbWpPRkpyOXlkZkllUXgvbW9GTFJ1RjVqVEZDNy93ajB0bGcrZUN1WApCZWZSS2p6U0VpMWZDeXJRN3QwWE1nNWtJVEZUOXprRTNmMEZNNVZyUFRsVkVrNkdGZnZKbTA5WjJFV0oyWitXClB6dTBHTTJBcmhiZ3lRM0pDckFhdWx5UUtYNlVKdkJ0OTY3TTRFVnY0ZEt0WmVWRnJVN3RLYnlIeW5mVmtkWlkKNzc2WnpIcy8waDBtYlEwN3I0c2hVQWVQNU00S3ZuL2RJRHdPWjk4ODhjRlVPTmZtTHRKZlFqeG4wc3psKzZzcApEbGxFZmEwVEFnTUJBQUVDZ2dFQkFJNko2ZDBkU3p3cy8yR2NiSzdMMnRIVXNJNUpJSjY3dUpHamNzODJYZUIxCnBXYVFmbjBCNzYxVno2MTQ1a3lGSzRIZS9WRTl6cnQyT1ZXRjRZYjJrMDB0aXF0MVhacVo5cTdJbGJrcS8ySmMKbng1Q1BUam1LRytaMUZWdUI2Rmh3bjVCRVlxeVF6MTI2Ukw2ZVR6Mmk1TTBxVEFFMUM3eFovbWY3Q3BpMktubApudVgreVRGNVpvM0hicHo1THF6SDdHTHdraEtkT1JqRFhTNnRuUGtTVS9Hc0lHQllUcW1sSFcrYVUxVXpCanl5Cm0vNTlFNCtJL0t3OHNUZVpqbkhBZmthZjI5eE53UXFaWVh5VXNObGRXUVNPUnVTZ2xhR0F6bEJ0YVUreXNYK2MKWElYb3A2ZXhFbVBuVmVmeWlZaVBEOTI3a1hTdWxJeFRlQldRcE9yRHFnRUNnWUVBOGJGbCttMG9zRFR6bERmbwplZjBZNWVCKy9xcDdqMHY1NTVpeG82d1pEV21MMXhrOWpCeXFRV1YxcEtvM2t1ZTNJdDQ3K3QvRmx4YWFWMUNPCng5YTR4THVGNXlTbEowclNwNXJMNTZFSUZsSXFUT2NvaFhKQXNIQzN0QmE0emZ4b0ZFWmRKdHBieVUzTk5HWlAKSXU5R1RDR0VoYXhaMTNXenhiYWxyMFNEd2NFQ2dZRUF3ZzVmMEdKODR5Q2w3TlF1cHVWMVlMbmV4bm9RbzJudgpITnVlWFhTTlQ3bWdVaWMzdVg2bUFVKy8wRGluMjFQSkViSzJjMnFBTGliZEdCY1QyelBnUEZEYnl2YWJ0OWtVCk8vemViTmVQQlhhcWxuUU1nZFR0cmlqR0phaDN1bERTMWJKcEgxMFg4Y0p0MHluclRsMDZuMGZuN3NOWVRCOTgKZU0vYUpEcWR1OU1DZ1lCbFlVWW5iMVpiNHpvdzkrcWFFT0k2dXBwS2RIUnp2U2pNVHE1a3V6R2ZBS0RaendxVQpGUW9OZUdPS2VLUHJDU3MyZ3dXaHkrOXoydFZPdnNuRlpYb0hlNmxGTllmWkhYZVRPa2xCbGJod3RISnQ0NkNKCnFVMGROWXE1RGJiaklIYi8yaXdFdWg4NkoxcG1HbXdqZVQ2QmZLVzc5SG1TK1JvNVdzM1E0T3ByZ1FLQmdRQ2MKem5xejYzR1pJcitSRUorbDh4S1hGM3Foak84MjdSbnZpck44TnZzZEtoVVhiV05FKzhidWxsK2J4THcycVl4MwpSWjdTd29OVFI4b3VkaTl3V0luZ2swSVh6cEJqemdEZ3ZHT0xOZC8yL1QyNUY0c251a1JaRDgrVmpIMDZ5NmFpClVXbEtrN0lPaEJxMG9GSG8zOExJQkpXd3hKN3IzQ0Y3aWhGdVp3TWdTd0tCZ1FEQ2xERDczb3Y4SFBxRFlOK0oKbEVibGJJbFRydGc1VElQemJjdVM2ekVCSVVEemI1VldURGR1Zy83OWZiOXRzUHJsZ1B5UmFNeSs0QzN6U2tYSwprcVZZOVUyN0lSRGxacStlNFBWTWRMcXl3ZVgwNEpXN0lOYVd1QUQ5OHZnbWNrNFIyNlVSU2EvMVp3Y0RXK3A5CmNFTGduajhKT09oeERzR3NDVS9CREgwaFpBPT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo8L2tleT4KCmtleS1kaXJlY3Rpb24gMQo8dGxzLWF1dGg+CiMKIyAyMDQ4IGJpdCBPcGVuVlBOIHN0YXRpYyBrZXkgKFNlcnZlciBBZ2VudCkKIwotLS0tLUJFR0lOIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjZiMTNmN2Y3Y2MwMzE3YjkyMGEwYWM3Zjc1MjQ3YjljCjNhMTY0OWRlOWM0MDVjMTBhNjk3ZWU1MGM3ZWQ2N2VmCmM4Zjc5YTY4OTJkODg4YzFhN2IzN2U5MWE1YzllYzI3CjdmMmZjYjFlZjk1MTVhMTQyMTYzNzJiODUwODU0YWE4CjAyYTc0YTEyZDNkNmFjN2ZhYzZmMTdjMTQ3M2M5NjU3CmE4ZGRiMTU1ZDYzNjVkNzc3MjdiNGRiOGJlODVhMzAxCmZjYjBkNTE1MTg5OWU4M2RkMWNhNmM5NWY5NDY0MmI5CjZkYjUyMGQyZWFjOGQ2ZTg3NjI1MGQ4NDkyZmFkYmY0CjM4OWNlMTFlZTVjMDAzZmI3NjAxYzBmZDM3YmVjYWE0Cjk3Yjk1OTFlMDNlM2JiNDE1MTNjNTkwYWY1ZDdkYjZlCjg5ZjJlNWQ5ZTQxYTM0ZmNjMzE5ODg4NDU2YTFlZmEzCjRkMmI3MDM0MWUxZTQwZDRjMmMyOTUyMWI5ZDNiZTAxCjlhMTEzOGQzN2U2ZmIwZWFmNWJiMjYzNGRlMDQzZmJmCmM3NzYyNDJiOTI3ODBiZWM0ZTI3YzExZmQ4ODRmNDg3CjhjMjAyMjNlMzkwYjdjMDI4MjNhZjYxZDQ1ZjlmMjU5CjBhYjM4NWIyMWVlYTQ4NjJmOWI1OGM0OTI0NGJjMDk2Ci0tLS0tRU5EIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjwvdGxzLWF1dGg+CgojIyAtLS0tLUJFR0lOIFJTQSBTSUdOQVRVUkUtLS0tLQojIyBESUdFU1Q6c2hhMjU2CiMjIFFKL3AvRTRKTW9KVG5vTVdlMXYrbnRvMS9Wc2N6TjBWSC8zczJnRUxGbUJUT1h1TndRCiMjIHVwK0dhLzRRNEtsbFZUdkZvL3poWkRFV2hVcGlYL2p1VnluQ2xXZmVLK1RCR0VBVzdYCiMjIGh5eGNoQkpUOXlqQm1JWUNQaHg1c1lyclJQNTZuM1M0ZGh2OGQyUjhwVndXYzVIaFZiCiMjIHZFcCtIYXlsTXBWOVI3VTVzeWVkVGVUQjdpcW56MC94SlQ3UzdxUDZkcGtxN1haaUhVCiMjIHVTSVBpZytPSXdqL2V3U25pSzVuNlE2UXRBSlFOdmFSZnBpK3U4OHkvRG1jK1BrUFB4CiMjIDJGcUZodGphcWFOVDNHQVpOODEvZGluY29NWHBBcUhTU1hWRGtxanpSNEsrekljMGovCiMjIHFNS3VIL1pxZ2RwMkNuSEs5MW1JODE4c1dzazJQV0JlMUVodnBpOWczZz09CiMjIC0tLS0tRU5EIFJTQSBTSUdOQVRVUkUtLS0tLQojIyAtLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KIyMgTUlJREhEQ0NBZ1NnQXdJQkFnSUVZaW1mOURBTkJna3Foa2lHOXcwQkFRc0ZBREJITVVVd1F3WURWUVFERER4UAojIyBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpFd0lEQTJPalV4T2pNeElGVlVReUJwY0MweE56SXRNall0CiMjIE5DMDNPUzVqWVMxalpXNHdIaGNOTWpJd016QXpNRFkxTVRNeFdoY05Nekl3TXpBM01EWTFNVE14V2pBM01UVXcKIyMgTXdZRFZRUUREQ3hwY0MweE56SXRNall0TkMwM09TNWpZUzFqWlc1MGNtRnNMVEV1WTI5dGNIVjBaUzVwYm5SbAojIyBjbTVoYkRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBSkh3V0k2TmV2OWo5bzRmCiMjIGlySEVMeXNMZjc4THpSNnVCQnhxOW1qMXhrQXh3SmZHUDFuQ0Vjb2g4aGVhaTBzQ0FNL3R6RGRTMCtzMkxCTXUKIyMga3hVc2l5QWc2TjU1MXY3SEx0TEZGTlc4OXB6dUJ3Nmprd09LalZwNkE5VU85bk9SUVJ6R2hNQTQ2K0RZNGIvKwojIyBDL1oydHBsOVdjbTF2bUh2QW1pcEF1dGs1QzJnVVNSNC9NMEd4SDB3b0pwZENZa0lvN0dkWWhFaEtvMWpoTFhpCiMjIEduZ2cxenVETk9XV1l4T0FVQ1BiWnNoUHViWWZqVWZWdU1ROTBQU1h1d1hHZkF5RU12Q0h3UTlqWXFaU3Zudi8KIyMgY1V5L2FzeWNVQTh1Y0FYM2RvekpuZ1orSU5DT1FESW1ReGJ2cEkwSjBNYlBtL3hZVWJSQUg5Mnh6V01pZ1JZaAojIyBRemREQTRzQ0F3RUFBYU1nTUI0d0NRWURWUjBUQkFJd0FEQVJCZ2xnaGtnQmh2aENBUUVFQkFNQ0JrQXdEUVlKCiMjIEtvWklodmNOQVFFTEJRQURnZ0VCQUdOS0twK3lmVjk3azZ6aDNBZGMxaDFLdDNQR2FZMUk5anVSUlh4endjM2sKIyMgY2xNbExFWTc3dXFJODhRM2Zta1ErTWJET1VGZjhwNGdvY1lIWWE5ZExSYVR1OXRzd0UxU3crWjFvTHNlR05HZAojIyB6enBrcUkxMkFTNlBqdG9TV0tJZjE2cjE0WGwwM2VxN1dJT0YzcTdLWGlRWnlJYkZrZjJROHg4bzAwV1ZSS0NkCiMjIGYzQWhDeUxFaTl2aGFzNmZNL3RtRDRaQUpoTCt6R2RsTmdIREhzU2dickFGUVhTQTVhTmVSdHRyR3FXQk5IUjgKIyMgaXJLN3JwaHZQUHJWS3hJREdDaURFcVY3Z2RyenhXN2FvV1ZuOExWL0M2NzJMSUkwc2l0UTA4ajQwZmN4akJCcQojIyA4VnlkckFuRHpuMExNdkpYSzdiT3BmSUk1Q0M5YmRmSzE4OEh3UWhtdlBvPQojIyAtLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCiMjIC0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQojIyBNSUlESERDQ0FnU2dBd0lCQWdJRVlpbWY4ekFOQmdrcWhraUc5dzBCQVFzRkFEQkhNVVV3UXdZRFZRUURERHhQCiMjIGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakV3SURBMk9qVXhPak14SUZWVVF5QnBjQzB4TnpJdE1qWXQKIyMgTkMwM09TNWpZUzFqWlc0d0hoY05Nakl3TXpBek1EWTFNVE14V2hjTk16SXdNekEzTURZMU1UTXhXakJITVVVdwojIyBRd1lEVlFRREREeFBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpFd0lEQTJPalV4T2pNeElGVlVReUJwCiMjIGNDMHhOekl0TWpZdE5DMDNPUzVqWVMxalpXNHdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUsKIyMgQW9JQkFRQ2dvUkgvN2o0Mml2d2RraXdOMnJualg5b0VTczdDVTJrZEFWYUplblJzTk84TnVNVmxlTC83b2QvYwojIyBlR2t1bXVCUHZSUlVkTWZjVmlpNWQxTkM1SktYZFp4VHRlQ3gwaE1hR0FRVWxZVC9FcXRuYXhOUEo3cHJkdmlFCiMjIFB5K2NkWFYwR3pSdG1FdjZwWVgzZlpWWlhtUE9DN1o5TlJKNVNvK1F4ODVGT1l6Q0VKWWR4QzFXdytUUEZObGwKIyMgQ2pIS0FYSlRhTXhwWGJKRXhiSGJWaUh6Yk84bVQrYXl0azRubmdEZHFUU2dCd2VJb3VXdTAzS1c3THBYaGQ3MQojIyB3RnIyL2dQMmNiTEQ2TnZaZjFDZTA2aUdETlFjaWE3MjdDb2liYzFmQzNJeFNKc0k5VmUzYi84SUJtWFJmUmxSCiMjIEgwMnNpUnU2NzZoaWtZbWhCQjVIdFlOa0I5dW5BZ01CQUFHakVEQU9NQXdHQTFVZEV3UUZNQU1CQWY4d0RRWUoKIyMgS29aSWh2Y05BUUVMQlFBRGdnRUJBR1EwWk0zd084NTdZMlJ5eEdiRmtLbE1rWHlxa0RYY3hSTklpTVhxT2RvegojIyA4QXlMQzd6N2Z5eGxSOEMzczYwOXRyQ0NyNDZxMTZrTVpLRU1OQ3VXOGErTWFBMlQ2Q2huY0ZGY1BqVERGdXFOCiMjIGNvNGhrZy9UUkJqdEJsZStmd0haRzVOc0NuSUJGaW9TTG51UFRMc21tL2VTT0gwQkUrZVZ4V0k1c1gvR1JBcVIKIyMgR1FpdTBLNUFNWmtDTHd6MWhrYXZVRzRmZHo1OXhxY3FpcnNTanRNK3VmVk4yNU1jZTYxQUV2a2kvUzFaVXJuNwojIyBHdEdhYUlOTWRjN0NXSm9RamFyRXlac1NsbURVQXl0S1dXaWJnVjFpVWhxRzlTaTNoM2F2Q0lkQ1lXaEoxQXdWCiMjIEEyZFJyaGI2U3c0czZ4alMvTHJGNmhGOWFKa3BNdjc2NnlQNzZrcEg4VU09CiMjIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                //   "source": "GCP",
                //   "status": "live",
                //   "username": "ovo",
                //   "password": "123456"
                // });
              },
            ),
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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformStates() async {
    // Load persisted fetch events from SharedPreferences
    var prefs = await SharedPreferences.getInstance();

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 25,
            enableHeadless: true,
            stopOnTerminate: false,
            startOnBoot: false,
            forceAlarmManager: true,
          ),
          _onBackgroundFetch,
          _onBackgroundFetchTimeout);
      print('[BackgroundFetch] configure success: $status');
    } on Exception catch (e) {
      print("[BackgroundFetch] configure ERROR: $e");
    }
    if (!mounted) return;
  }

  void _onBackgroundFetch(String taskId) async {
    var timestamp = DateTime.now();
    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    setState(() {
      _events.insert(0, "$taskId@${timestamp.toString()}");
    });
    if (stage.toString() == VPNStage.connected.toString()) {
      engine.disconnect();
      print("VPN is disconnected : DONE");
    }
    print("VPN is disconnected");
    BackgroundFetch.finish(taskId);
  }

  void _onBackgroundFetchTimeout(String taskId) {
    print("[BackgroundFetch] TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
  }

  void _onClickEnable(enabled) {
    BackgroundFetch.start().then((status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });
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
