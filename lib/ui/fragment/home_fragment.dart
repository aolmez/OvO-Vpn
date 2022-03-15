// ignore_for_file: unused_local_variable, avoid_print, unused_element, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
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

// Backgroud  Task
  bool _enabled = true;
  int _status = 0;
  List<String> _events = [];

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
    initPlatformStates();
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
        // _onClickEnable(true);
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

                // FirebaseFirestore.instance.collection("vpnServer").add({
                //   "server_name": "Australia (Sydney)",
                //   "cod": "AU",
                //   "config": "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBNb24gTWFyIDE0IDA5OjM1OjMxIDIwMjIgYnkgaXAtMTcyLTI2LTEyLTI3LmFwLXNvdXRoZWFzdC0yLmNvbXB1dGUuaW50ZXJuYWwKCiMgRGVmYXVsdCBDaXBoZXIKY2lwaGVyIEFFUy0yNTYtQ0JDCiMgTm90ZTogdGhpcyBjb25maWcgZmlsZSBjb250YWlucyBpbmxpbmUgcHJpdmF0ZSBrZXlzCiMgICAgICAgYW5kIHRoZXJlZm9yZSBzaG91bGQgYmUga2VwdCBjb25maWRlbnRpYWwhCiMgTm90ZTogdGhpcyBjb25maWd1cmF0aW9uIGlzIHVzZXItbG9ja2VkIHRvIHRoZSB1c2VybmFtZSBiZWxvdwojIE9WUE5fQUNDRVNTX1NFUlZFUl9VU0VSTkFNRT1vcGVudnBuCiMgRGVmaW5lIHRoZSBwcm9maWxlIG5hbWUgb2YgdGhpcyBwYXJ0aWN1bGFyIGNvbmZpZ3VyYXRpb24gZmlsZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9QUk9GSUxFPW9wZW52cG5ANTIuNjQuMjM0LjQyL0FVVE9MT0dJTgojIE9WUE5fQUNDRVNTX1NFUlZFUl9BVVRPTE9HSU49MQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9BTExPV19XRUJfSU1QT1JUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfQkFTSUNfQ0xJRU5UPUZhbHNlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0VOQUJMRV9DT05ORUNUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfRU5BQkxFX1hEX1BST1hZPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV1NIT1NUPTUyLjY0LjIzNC40Mjo0NDMKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVEFSVAojIC0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQojIE1JSURIRENDQWdTZ0F3SUJBZ0lFWWk4S1Z6QU5CZ2txaGtpRzl3MEJBUXNGQURCSE1VVXdRd1lEVlFRREREeFAKIyBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpFMElEQTVPakkyT2pRM0lGVlVReUJwY0MweE56SXRNall0CiMgTVRJdE1qY3VZWEF0YzI4d0hoY05Nakl3TXpBM01Ea3lOalEzV2hjTk16SXdNekV4TURreU5qUTNXakJITVVVdwojIFF3WURWUVFERER4UGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakUwSURBNU9qSTJPalEzSUZWVVF5QnAKIyBjQzB4TnpJdE1qWXRNVEl0TWpjdVlYQXRjMjh3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCiMgQW9JQkFRREJuY1lKMlBJZDQ4cHdYZlJ5ZjB6OXVkTmMyUEZiclpoZ3RkeDJsQ1pMR0pQck9UVy9FQVE0VFhwVwojIFVzbjhRSmRyK1VvcFpZaXUwb2lUcWFQUjgvUkE3R3NQblJTZzRaQjM0M2tNM29HZW91TUNvRnpMbTZJV2ZOVDAKIyBXNWIrcU5FUmhjZ0h2WC9nR1N5VjhqcGZkK1EwR2JtdDlFQm5QTzVWb3hDZytUejZKaUYxV2xFZENkeG1Na29aCiMgb25qVEZuWVgrMFU0WUFYQXZaOGFnME1uZGEzMXFTTXdDRUNIaEZXTy9QNk1sOGNhUjJBQlB6NHFVeWdMalZhNQojIG1mUDVKenRIRXBxUk93dGw2NThraEo3bUZjc0tPVUJSTFpiUlFvclZNN09pNnZLTFRNK2NnbUtCTDdrOWxEZWUKIyBnaWtHRTNKOUFCcWYwUGQ2QnlPeHNpVjZZTFBEQWdNQkFBR2pFREFPTUF3R0ExVWRFd1FGTUFNQkFmOHdEUVlKCiMgS29aSWh2Y05BUUVMQlFBRGdnRUJBQklVZWI4RzI3UmNDMVNwa0xyQ0dST0Nzc0pNeVh2TytCdXN2RU1vcWFGMgojIExlWVZTYjYrcGlHT2tad3hJUC9qYXZVT3VUVjVuRHBWL01nOGRlaDRiVVFCellyT29URkZFcDRhZGFkUHZ6cmcKIyBzdmtwekl4cklCblhyM2NNSkFhQlUrWUpKZ2lWZFNTR0FudUZUaGFOV0RGR2VmT1IrdjFyV0VndDdRcUNMUUtnCiMgU1lSMlU3cnRxdE8rckFvYURUeEMyazBPL1FNVHFicXZXRHlDblh1MncrYWpzVXJRMXh5em5NeU04Z3NXU3U0eAojIFhWMW1pQksxYis0clNKaWQ5S2dzbUU0R3BDQVNzWVFDTWw3ODRTTjVVNDh1anNydW9uMnhLTnlabnY0MW1IR3UKIyBLR0lTQTNIYk02WDY4U1JwdnA5ZndvU0JkbUdobmhvZGhpOHhtRnVRU1ZJPQojIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVE9QCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0lTX09QRU5WUE5fV0VCX0NBPTEKIyBPVlBOX0FDQ0VTU19TRVJWRVJfT1JHQU5JWkFUSU9OPU9wZW5WUE4sIEluYy4Kc2V0ZW52IEZPUldBUkRfQ09NUEFUSUJMRSAxCmNsaWVudApzZXJ2ZXItcG9sbC10aW1lb3V0IDQKbm9iaW5kCnJlbW90ZSA1Mi42NC4yMzQuNDIgMTE5NCB1ZHAKcmVtb3RlIDUyLjY0LjIzNC40MiAxMTk0IHVkcApyZW1vdGUgNTIuNjQuMjM0LjQyIDQ0MyB0Y3AKcmVtb3RlIDUyLjY0LjIzNC40MiAxMTk0IHVkcApyZW1vdGUgNTIuNjQuMjM0LjQyIDExOTQgdWRwCnJlbW90ZSA1Mi42NC4yMzQuNDIgMTE5NCB1ZHAKcmVtb3RlIDUyLjY0LjIzNC40MiAxMTk0IHVkcApyZW1vdGUgNTIuNjQuMjM0LjQyIDExOTQgdWRwCmRldiB0dW4KZGV2LXR5cGUgdHVuCm5zLWNlcnQtdHlwZSBzZXJ2ZXIKc2V0ZW52IG9wdCB0bHMtdmVyc2lvbi1taW4gMS4wIG9yLWhpZ2hlc3QKcmVuZWctc2VjIDYwNDgwMApzbmRidWYgMTAwMDAwCnJjdmJ1ZiAxMDAwMDAKIyBOT1RFOiBMWk8gY29tbWFuZHMgYXJlIHB1c2hlZCBieSB0aGUgQWNjZXNzIFNlcnZlciBhdCBjb25uZWN0IHRpbWUuCiMgTk9URTogVGhlIGJlbG93IGxpbmUgZG9lc24ndCBkaXNhYmxlIExaTy4KY29tcC1sem8gbm8KdmVyYiAzCnNldGVudiBQVVNIX1BFRVJfSU5GTwoKPGNhPgotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJQ3VEQ0NBYUNnQXdJQkFnSUVZaThLVlRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwUApjR1Z1VmxCT0lFTkJNQjRYRFRJeU1ETXdOekE1TWpZME5Wb1hEVE15TURNeE1UQTVNalkwTlZvd0ZURVRNQkVHCkExVUVBd3dLVDNCbGJsWlFUaUJEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUIKQU5aMHhNa3Y3WENxdnZqUCtYM08xR1Q3ZHVIQTQ3RHM5ek8wSGtRemRLdkNRajNlTXhyZTNvakRmYlpiVWtNeAp1NHJjdTBkcjVrUEhGTk1Rb0RyVGpQWFZER3dxcjRpZENIMk9hMmxPMVYzMURkdHZtd2ZONjJMQS94NXZkak80ClNGUHN1ZXRRWmxXbEw5U3lWK3pISGFacFU1ZnFMRFRPRlovR09QU3BYWW5QNmpBN0x4VXdnaEgzNmM4RjhvRWwKcmhKb21DZUJzYldSbXFERmJsMjVtaElhdDVwUCsvUmlRVEtMVVlMRm5kS1hxeGRaRjl6Y2ZXY0w1NmdMNWxrcwp2ZCs3Y1lXWDRkQm9tRTJmSDhWRjFKNEZlREY1Q3M4eTVZQzRrd01OTGVyTVBBcHNGaUJYVU5hRnRHaENlVjdqCmpLdi9MUnBHRjhnVnhYeUtUTVpaNytjQ0F3RUFBYU1RTUE0d0RBWURWUjBUQkFVd0F3RUIvekFOQmdrcWhraUcKOXcwQkFRc0ZBQU9DQVFFQW1aVFJHMVpFa0g5bnJodmgxRTRWTWg3Z0pQYlVxZENmbEtONFF4RCtrU0hGK2cwUApLTkJPMlJ0MXdXaXhjZWl3Q0szUkg5VjdmMmpoTVFNMFppUTRJcldHSlJ5MVdQQTFkZTVyVkx4TDBWclhMT1NPCkI3NEtoYTk3KzBMT2hwaHc1eVAzZGxtSjU0QXh4R09MdVJudEFXbzRmMjFsNXMyMHpwY3haWjNaY2RUK3pUTEQKR2lFcWt3Um5ZMUI3SWZMZVFpOHVWQmlQaXo2SEZQdWlwUFhKelhXQnBFZ2xuR0NqYVhTRCsxNzhCMlZhUkx5YQp4VUxVYlE2SHpHcTVGK3dmZ1FQNHA5bE8vTEQ3VTVSWlRabkFsa0l3UVkwZ01aN3F3VERyR0RGVzBGRW5HSFdiCmUvYzhDZ3lPR2hxVDdteXpQRnpzTUI4eVdmV1Vqai9qWDdTTC9BPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo8L2NhPgoKPGNlcnQ+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlDekRDQ0FiU2dBd0lCQWdJQkF6QU5CZ2txaGtpRzl3MEJBUXNGQURBVk1STXdFUVlEVlFRRERBcFBjR1Z1ClZsQk9JRU5CTUI0WERUSXlNRE13TnpBNU16VXlPRm9YRFRNeU1ETXhNVEE1TXpVeU9Gb3dIREVhTUJnR0ExVUUKQXd3UmIzQmxiblp3Ymw5QlZWUlBURTlIU1U0d2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFSwpBb0lCQVFDNzMwSGhzZWdzMVkvZGlEdWRmSFdtWUU5TmpHMm45YWR0NEFkT1FySVVOMWJCSVBvWlpJZXI3bGk2CjJXZjBDcFZPK1B0d0YvMVkrQVgxQmx1MGdtUjJLWjRYMThuSk9pRFhKUURKODFwaE53WlY1enI4SjZNdlZ1akcKSVFZRHllMlpoYXBIR1JaRjJVUkUvaDdOMW1NNXd5TExRUmdGRGJWNUNqZG5xdHJjcjRVVWxnVHpNY2FOb29pTwpjbFJremxTQlpZRVJIOVd5YUhpc003aEJHcFI2YUVQcGN2a0YzSVBvNWVuU2dCK1lGa054ajJIVVF6TE5WUHVLCm5lbSt2ZnFYV2VCeHBpdGZiNEZnRUNaZ1FaREN2Qm9IWlorZnRHbHNCN2xTRjdjbXh2cWgzamxtM1pHOUVYMkwKNlFBODJGZ1VTSW05NkJPT1dETTQ5STlkSkJzN0FnTUJBQUdqSURBZU1Ba0dBMVVkRXdRQ01BQXdFUVlKWUlaSQpBWWI0UWdFQkJBUURBZ2VBTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDWXZySXdGbTkwVE16VkgrZmpHZ0lDCm1xZlZ3UmwrRjEzNnExbVU2aGQrR21HNmtjRVZVdW8zeG8xaS9UQ1dpblVteDlTRlB5aXkrWkRxSFk1SWQ2T3IKZkg4UXF0c1NNb0pkei9CeWIrQ2RXTDVxWDJuR2ZGWlM3WFlWNWdGaWYvNjRRRHNBeHc4SHBpNWlSTVF5WjE3Qwp1d29BSDJBTk5sYlcxTTFLdFZUZk1nSldlRDVNVGQvSXg4b3R0dUY0dkc4N01IUzdEKzFkQVhlN2NPY0hmK3IwCkF1QlY5RHFPZUVFa2REWTBNejduK2c3NmJ3VEFHMzFKMGp1WXFRTHdHeU9kRGN0SnI5QW0rQm55QnFaaERpaGcKYW9nbEJzbzFicGRTdDZxUTRSMjgrME5mVng3dC9ScTVOK2JqcWkzU2M3R1c2cWZudkhocFFzdFVFdmhxWkcraQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2VydD4KCjxrZXk+Ci0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLQpNSUlFdndJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLa3dnZ1NsQWdFQUFvSUJBUUM3MzBIaHNlZ3MxWS9kCmlEdWRmSFdtWUU5TmpHMm45YWR0NEFkT1FySVVOMWJCSVBvWlpJZXI3bGk2MldmMENwVk8rUHR3Ri8xWStBWDEKQmx1MGdtUjJLWjRYMThuSk9pRFhKUURKODFwaE53WlY1enI4SjZNdlZ1akdJUVlEeWUyWmhhcEhHUlpGMlVSRQovaDdOMW1NNXd5TExRUmdGRGJWNUNqZG5xdHJjcjRVVWxnVHpNY2FOb29pT2NsUmt6bFNCWllFUkg5V3lhSGlzCk03aEJHcFI2YUVQcGN2a0YzSVBvNWVuU2dCK1lGa054ajJIVVF6TE5WUHVLbmVtK3ZmcVhXZUJ4cGl0ZmI0RmcKRUNaZ1FaREN2Qm9IWlorZnRHbHNCN2xTRjdjbXh2cWgzamxtM1pHOUVYMkw2UUE4MkZnVVNJbTk2Qk9PV0RNNAo5STlkSkJzN0FnTUJBQUVDZ2dFQWQ4S2s2NnVPTm01WkRENFl5cGFaSk5zR0VvZ3ZLcjlrNEp6TDYyNkd1RzVpClpqQ1FYWG1CSnUrRUxuQUNYVVlWMGNiVCthdkJPMkszNFc4UkxHdG1nUkNjajlSbDlGbVNyN01ONHE2M2NYc3oKRmJXV0cwRmxPL3NwM1lzVm0zcXdkSW9KZHRNZUtKNk1iM0tTem1JWTFLeDQxSnFGSmt1TDRFSEwrZENuUGIrcAowdnRtUzVKMFJ0TjlLNWljeEE4UEdLZDkzYndYMlI5eDU0V21RT25qQldJTFNLK25lazU5Ui9RcEpUUG9NTzdYClhNeDNZekxuMSt5T0RMQW9jYkk2NTJ5L2ZSYXYrWjZxYi9UMk1oTkhINTZjSlRsL3YwSTA3a3A5UzdkTUNZQU4Kc0xxK0xxRVFiVUZuU2g4bmdabzN5TFNuL1N3eEVRRkVySmZxN0hSaXlRS0JnUURpeGY0cjkxUHh5OHVtNnM0OAp0ZE45TnF4SUVTSWRQTHBRQVY5dWdoNzdLaVB3VXJ0dUFjMGw3RE9Yd0FkZFEzblVvT0VrVE1rbmVKaGNtVUVxCnd0V2duemVWZlRVOWxEVlcwTzlHUVNsRi9ONkpmdXpqSUR0UHhKN1RyOW5qcE80MVA3TDJRZ0xRZ3UzQTF5ZS8Kb0FFOHVMTHVrNWdmRVdCM1dpTkIvRTBOcHdLQmdRRFVGY2Y4VmN5YzYxQkhYQmdzd2tvZkJPeXhXUm4zVEhhTwpKa25LSFFHcWNHTm5Dam5UR20wMTNCYUZkcXc1VHUvQnE4WXJETVc3K0tQYVFoZ3M2VG5kazl4M283c3NMMW5pCkhOeURXbFhXbGJjUElMWlRwYWZPRUpjbFZqcWQ0L090U2xkd0hRaXh3amJIWnVZWVIvam53WmpNOFRadWI0N2YKQ2R5UDJ6RUFUUUtCZ1FDdUc4K0syQWltVTQ3WFo5M1NOTlBjaGZaK0dsRnoyeVU4dWVFWVNtVVk5NERDU2ZMSApnakNNMWkzQ2E5ZjduZ3ZTMlhZaVZhWDNYUnExdGFDWUFTRGRnb0M5a0hVcEF6cDBubE9uUCs0OVl1bEU3YU5ZCnVtMXZVQW1WZzZVcHAzNlFlWWlnazR2dnBTWi9jWEYrS1kzcG5mRWJSVXg5UmUwbmxaZ09XSFNjYndLQmdRQ0QKMFFuY1Z3TjJvSGJqODJSL0pUN21hcXdtU2tmdVFaTUtKTmdHQytOR0tOWlBhN2FtODZ6ZkplekZoUTNrREtETgowZEs0WFJibER0UGdTdVkxdTd1Z2NVODgrUUhUbzVhTkIvMHlrc241TmxKeHo1WWpCVG4zeEszOG9jeUs1K3hEClQ0cHEvMUN4RXhIeSs0eVZtTjRtUlZpUVFIZmhTZXNWeTA1UUJ4ODhuUUtCZ1FDUVRYVW14YkMvelpzN0Z4ajUKS2pjT2ovOTMxUXNQclZqZ0dqdzF0QVNzaXEyS1Q5SWcveGl6L3ZqNWFXZXlRM0V0VURKNFBzSGZXL3RUUHhteAo2TkpTaHFzS24vcmUxVzJlV0V3NmsyQ3c4M3lWS09uYzAvbUdmVTUxRTdTWm5za2VkMWpKM2hyL0xnRm5PSDl0CmQ1NnE1RCsxa3YwY28wK0tWSFg5VGlFUGtRPT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo8L2tleT4KCmtleS1kaXJlY3Rpb24gMQo8dGxzLWF1dGg+CiMKIyAyMDQ4IGJpdCBPcGVuVlBOIHN0YXRpYyBrZXkgKFNlcnZlciBBZ2VudCkKIwotLS0tLUJFR0lOIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjAxMjk3ZDUzMjFmNTg3YTllMzZhNmI3YjAwNjExN2UzCmZmOTZjYTRiNTMxNzJjYmRlODg0OWQzNjYzMWFkYjI5CjQzZWQ0NGRiMGZjMmNkODg4OGI4MzQzNjE3NTEwNzgyCjNlZTQ0YTRmNDBmYTkzNDcwZGVhZmM2MWI2NzU2ZGRmCjM3Nzk0ZjQ5OGQyYmYxNGVlMzk4NzA0ZGJmMGE4MzMyCmM2NDM4ZTI5MjZkODcyZWQ5ZDU1ZTMxMmNmNWJiMDZkCjMxNjUyNmY2NzE1YTFjNjk5MDMxMTdkZDg4YTA0ZDBiCmUyYmQ5M2VlMzJkMzUwNzczMjdjN2U2OWM1NTg0YTc3CmM0ODc1YTJmODYwYjg5ZmRhZGU0MWMzYmMzNGFmOTRiCmEyYjhhYzIwNmYzODFmMTE2Zjk4ODg4M2Y5OWIzYTljCmI3ODk5Mzc4ODg0YmVhMGMyZGE4ZDJjMWE5YWM2ZGY2CjA0NDllN2EwY2UyZjg1N2M2MzJlZjI4Zjk5YmMzZjUzCjRkNmFkNTNjYTNiNWQ2MDI3MGM2NDY3ZDY4NjhjM2QwCjJmODc0NDIxYjYzZjBhMTZlNWQ2YjllNTNiMjFkZmExCmU1MmMxMzkwMTNjOGQ0MzkxMzI0YmJlOGE1OTI1OGVhCmFmMWIyYmEwOWY0YjQ3MjBmYTAyNTJjNDI5MWM0OTZmCi0tLS0tRU5EIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjwvdGxzLWF1dGg+Cg==",
                //   "source": "aws",
                //   "status": "live",
                //   "username": "ovo",
                //   "password": "123456"
                // }).then((value) {
                //   print(value.id);
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
    var json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
    }

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 15,
            //
          ),
          _onBackgroundFetch,
          _onBackgroundFetchTimeout);
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 30000,
          // delay: 3600000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true));
    } on Exception catch (e) {
      print("[BackgroundFetch] configure ERROR: $e");
    }
    if (!mounted) return;
  }

  void _onBackgroundFetch(String taskId) async {
    var prefs = await SharedPreferences.getInstance();
    var timestamp = DateTime.now();
    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    setState(() {
      _events.insert(0, "$taskId@${timestamp.toString()}");
    });
    // Persist fetch events in SharedPreferences
    prefs.setString(EVENTS_KEY, jsonEncode(_events));
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
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
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
