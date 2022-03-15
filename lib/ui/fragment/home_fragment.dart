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
                //   "server_name": "India (Mumbai)",
                //   "cod": "IN",
                //   "config": "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBUdWUgTWFyIDE1IDA3OjA0OjQxIDIwMjIgYnkgaXAtMTcyLTI2LTAtNjAuYXAtc291dGgtMS5jb21wdXRlLmludGVybmFsCgojIERlZmF1bHQgQ2lwaGVyCmNpcGhlciBBRVMtMjU2LUNCQwojIE5vdGU6IHRoaXMgY29uZmlnIGZpbGUgY29udGFpbnMgaW5saW5lIHByaXZhdGUga2V5cwojICAgICAgIGFuZCB0aGVyZWZvcmUgc2hvdWxkIGJlIGtlcHQgY29uZmlkZW50aWFsIQojIE5vdGU6IHRoaXMgY29uZmlndXJhdGlvbiBpcyB1c2VyLWxvY2tlZCB0byB0aGUgdXNlcm5hbWUgYmVsb3cKIyBPVlBOX0FDQ0VTU19TRVJWRVJfVVNFUk5BTUU9b3BlbnZwbgojIERlZmluZSB0aGUgcHJvZmlsZSBuYW1lIG9mIHRoaXMgcGFydGljdWxhciBjb25maWd1cmF0aW9uIGZpbGUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfUFJPRklMRT1vcGVudnBuQDEzLjIzMi4yMTEuMjIvQVVUT0xPR0lOCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0FVVE9MT0dJTj0xCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0FMTE9XX1dFQl9JTVBPUlQ9VHJ1ZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9CQVNJQ19DTElFTlQ9RmFsc2UKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfRU5BQkxFX0NPTk5FQ1Q9VHJ1ZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9FTkFCTEVfWERfUFJPWFk9VHJ1ZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9XU0hPU1Q9MTMuMjMyLjIxMS4yMjo0NDMKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVEFSVAojIC0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQojIE1JSURIRENDQWdTZ0F3SUJBZ0lFWWpBNE96QU5CZ2txaGtpRzl3MEJBUXNGQURCSE1VVXdRd1lEVlFRREREeFAKIyBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpFMUlEQTJPalUwT2pVeElGVlVReUJwY0MweE56SXRNall0CiMgTUMwMk1DNWhjQzF6YjNVd0hoY05Nakl3TXpBNE1EWTFORFV4V2hjTk16SXdNekV5TURZMU5EVXhXakJITVVVdwojIFF3WURWUVFERER4UGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakUxSURBMk9qVTBPalV4SUZWVVF5QnAKIyBjQzB4TnpJdE1qWXRNQzAyTUM1aGNDMXpiM1V3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCiMgQW9JQkFRRFVORzF2cTA0YSt6MFhJZHU3aWV0RFdMTnpsUFkxUE9ZbGdqQVBhK0x2VkI3WDdrUnNaeXJkRDhtagojIEVJU25wYkoycDdpZ2cyWXQvRTJJZGNBRWZjQWFQZUFXbVBpYUM2dERVSnBaNS83NkRWTWppazR6Q2IxelpEZTYKIyBWYUdQRGt0VDBxK2FMWTBCN085YWdPS05QYkZSNEs3OHI0NHhFbGNCMlppVm96cy8rdG5HZU9OZ3N6TlpNWXBmCiMgSmExZWpZU0EwaldrT0IxRmlmSzZVL2NqRUZKQVhnTWZpMENEOWl2UnJrR3NDcXpBeVJBc3ZVUWg3TWhyUGRaOAojIDkreU9GcThSckUrMXBjMGlJYkhQTmpxcnhxNzVlRDRlOVlHYUZUbzduYnV3eVFKT3kwRzVxL3JEcDBUQnFGSEEKIyBQelJvREN2Yk9WV3lzUzFsTGMvSGZpZTIvU2dOQWdNQkFBR2pFREFPTUF3R0ExVWRFd1FGTUFNQkFmOHdEUVlKCiMgS29aSWh2Y05BUUVMQlFBRGdnRUJBQm9yTUp2aXhKNDhxVk9hUlJ5VnB5UHU1MFowcU9VNmVMdnVRWTIwOG5kdAojIG1ZVC9kMGJOZ3huV0YrSEpvbGpjcTk5L09DaGJKdk5qS2pBYXd5bnQrNWEzZUZMSkNZMXdaRXhhcXJJYXpURlAKIyAxNkUyazNmOURiejc1RDVBZ2o4WXdqTTU2cENmVWUzMmVnbm81b3VJaTFMSnRucTgwQ1ZIUERiZVhLc09UZFFHCiMgTUxWb3lyUDdSaHY4NEh3WmFCdmJ0SXladVBvUmVmbzBnWGsvdHJrYmRtS2tjY1RnRzN6UkxHbituNkRuTkJ4RAojIGFXYzJnMHNLTHFCOHFxR2tnWEYydzRyaSt5SXNGdXNZdTZkN1haYkltSko1VDZyd3lCMFFsZkZYV1J2dU8rTFEKIyAzeWxVWE0wNnNsREZibGQ5Q2pJRnBiZUJtN084b0NtYzZYdEVkTWhzWXFrPQojIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVE9QCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0lTX09QRU5WUE5fV0VCX0NBPTEKIyBPVlBOX0FDQ0VTU19TRVJWRVJfT1JHQU5JWkFUSU9OPU9wZW5WUE4sIEluYy4Kc2V0ZW52IEZPUldBUkRfQ09NUEFUSUJMRSAxCmNsaWVudApzZXJ2ZXItcG9sbC10aW1lb3V0IDQKbm9iaW5kCnJlbW90ZSAxMy4yMzIuMjExLjIyIDExOTQgdWRwCnJlbW90ZSAxMy4yMzIuMjExLjIyIDExOTQgdWRwCnJlbW90ZSAxMy4yMzIuMjExLjIyIDQ0MyB0Y3AKcmVtb3RlIDEzLjIzMi4yMTEuMjIgMTE5NCB1ZHAKcmVtb3RlIDEzLjIzMi4yMTEuMjIgMTE5NCB1ZHAKcmVtb3RlIDEzLjIzMi4yMTEuMjIgMTE5NCB1ZHAKcmVtb3RlIDEzLjIzMi4yMTEuMjIgMTE5NCB1ZHAKcmVtb3RlIDEzLjIzMi4yMTEuMjIgMTE5NCB1ZHAKZGV2IHR1bgpkZXYtdHlwZSB0dW4KbnMtY2VydC10eXBlIHNlcnZlcgpzZXRlbnYgb3B0IHRscy12ZXJzaW9uLW1pbiAxLjAgb3ItaGlnaGVzdApyZW5lZy1zZWMgNjA0ODAwCnNuZGJ1ZiAxMDAwMDAKcmN2YnVmIDEwMDAwMAojIE5PVEU6IExaTyBjb21tYW5kcyBhcmUgcHVzaGVkIGJ5IHRoZSBBY2Nlc3MgU2VydmVyIGF0IGNvbm5lY3QgdGltZS4KIyBOT1RFOiBUaGUgYmVsb3cgbGluZSBkb2Vzbid0IGRpc2FibGUgTFpPLgpjb21wLWx6byBubwp2ZXJiIDMKc2V0ZW52IFBVU0hfUEVFUl9JTkZPCgo8Y2E+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlDdURDQ0FhQ2dBd0lCQWdJRVlqQTRPakFOQmdrcWhraUc5dzBCQVFzRkFEQVZNUk13RVFZRFZRUUREQXBQCmNHVnVWbEJPSUVOQk1CNFhEVEl5TURNd09EQTJOVFExTUZvWERUTXlNRE14TWpBMk5UUTFNRm93RlRFVE1CRUcKQTFVRUF3d0tUM0JsYmxaUVRpQkRRVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQgpBS09OWkRvVEkvSFZjZ3BLaUUzSFdHSHd4aVdaZzA3UWpEZ25rTndnMTJLbVFWSTdzdEhPNUZndWdBRXhNUmVlCnVmSUp0WHhQMHErckxXN2RMT3ROQS8rSVd1c3IyQlh6SXh5SUN1YUZmOFUwTlVkbGxJOERFYm1WbWNBK2twYk8KeXFRQjFZTlpGWFVlUEFVMW5QVGIzMFFpVXNIMFo4c1RRcFlnbnZLUmRvVHFmdkVUNnVqeTZNbXQxeXFmWWY5Twoxam44QzJMT1N6Y1MvZWQxVFgwWVAyMUx0VG9mbDlnVEFDdzQxMTRWcGlzYUpYcXVaT1doQ1h4dWp1OXQ0T0dTClNIeDZLSm9ubWExMGxHNUtzcGxZb05rOGwyamhybGxValFmWEp3SGwrYXg5QW5JdlIxQWV4d1FlUTl6UEZvMnQKbXkwQ1c2cnBaVFNuZTdPWHFhcjB0Q1VDQXdFQUFhTVFNQTR3REFZRFZSMFRCQVV3QXdFQi96QU5CZ2txaGtpRwo5dzBCQVFzRkFBT0NBUUVBWDI4YXRubEVaalRMb1BlbWNDUms0SURyWVRXYWMzZGp4YUk3YTJOU1BmWGpnU1cwCkZETW41MVpaeDhWdlFYRmEzVFZaekFGVnZrblRZOU1seG1IY3k2MHBGSFdJMlBhT0ttcnVPWWlTUXJIKys1cVYKNmU1VnVlYzhVd29BaW5rM0JlK2drUmJsbFNrbkZseU9QT1EwMWU3MzNGakJWRFVVVThYemtGNStJRnNzb3cxZgp2VzlteWxkVmpZb0ZVUHR5MnNyY1BmRWFYZTEzVU1wTGpBMFk1VklVOHRnbUtycEViTkh6UjQvc1JWVkFHSmVrCmJ1aFA0dU1TMTVkekpHcHduVVFxZTlhN2JYb3hQb0lIaC9vOHpuWXNDY0VkcHc2ZnZYYkV4dFBSanFXY2ZxUVYKYU9vbE5rT1l3MStMMWgvZ3JFVTMrdUNDM0JSbG01Q0Y4VlExaFE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2E+Cgo8Y2VydD4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN6RENDQWJTZ0F3SUJBZ0lCQXpBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwUGNHVnUKVmxCT0lFTkJNQjRYRFRJeU1ETXdPREEzTURRek9Wb1hEVE15TURNeE1qQTNNRFF6T1Zvd0hERWFNQmdHQTFVRQpBd3dSYjNCbGJuWndibDlCVlZSUFRFOUhTVTR3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM3Zmc5V1VRek9LNmtUSmhLVzVTeWZ0VkZLaHo4dk9FcHFpRFMyckRxeUhnOXYvLzBSUHdPOERLelIKSUtOOHNHS3Z5SlBSYzRqQkZHcXRNTlZnVWQybVB0RFkvdTVtUnpqUW5BeU1odVFCQTRLaGpGL2o0OFh1eXM3egpySGtzY1phUlZ0c1lVaFBqYjlIUm9CaC9WRzkrMngzZGwydEZIQWRjcW9DbEhBeUo5ZXlTbkdIUTA0eHlZTCtXCis0N0JUTlBGam9Ddk1pN2k0RXhlN2hpbVd2MXRLMUMwd3lnL2dDYjkreHBzRHdSMUZKMXoxc1RaZ0I0YlJBK2kKcW8rRklSN1pnSENuUlJWazFVMFNRa3lqcW5BU2ZaT1pseTdLSGJoUW9YNHErZnQvU0cvbFkzZWwvdGxOS2dMVQowcXNqVG4zUHhmVWVmY0ZJdDR6bi9KL0t2RzJuQWdNQkFBR2pJREFlTUFrR0ExVWRFd1FDTUFBd0VRWUpZSVpJCkFZYjRRZ0VCQkFRREFnZUFNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUJVVVVKSCt5RDU1bDhkcHcwMGRDRXAKUDZMK01CczVUMEsvNG5qSzVTaFc5WkhsN2dXVFZjWThack55cEVnTUR1RVVwRzF1RmlvMDZHRFpKQmJyeWVjcApQMlZHZ2VEWjREMW1KUzNMMzNnY3NheERTRTdiZVgyeWEvZ2tLcHZ1VWxLRUpaM1poZzM1SS9OSzF3aklVcHVIClFtQSs4N080RXdPem5FZTNZVTZsbnQ3MlF6NlpqMVQ2MmtxdEwydm1KUmcvZ3UweXN2TkpOTjhycndiaEhvK3UKZkEwcUpZc1J4L2NUenBmcGU0dCtKNFBYbE1vMm9sV3NLQjlzSnV2VW4rVks5Zzd2U2JhOXZQYmRPUE5lWnpiTApveWJOV3c5bFJMZ2hrdkloajdWVEkvWjgrZEM3ak1HTUtYb0N0dGZ1SnB0SEdkcjE2WmxNbG5ZY0FiRnlnMGp4Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KPC9jZXJ0PgoKPGtleT4KLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV3QUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktvd2dnU21BZ0VBQW9JQkFRQzdmZzlXVVF6T0s2a1QKSmhLVzVTeWZ0VkZLaHo4dk9FcHFpRFMyckRxeUhnOXYvLzBSUHdPOERLelJJS044c0dLdnlKUFJjNGpCRkdxdApNTlZnVWQybVB0RFkvdTVtUnpqUW5BeU1odVFCQTRLaGpGL2o0OFh1eXM3enJIa3NjWmFSVnRzWVVoUGpiOUhSCm9CaC9WRzkrMngzZGwydEZIQWRjcW9DbEhBeUo5ZXlTbkdIUTA0eHlZTCtXKzQ3QlROUEZqb0N2TWk3aTRFeGUKN2hpbVd2MXRLMUMwd3lnL2dDYjkreHBzRHdSMUZKMXoxc1RaZ0I0YlJBK2lxbytGSVI3WmdIQ25SUlZrMVUwUwpRa3lqcW5BU2ZaT1pseTdLSGJoUW9YNHErZnQvU0cvbFkzZWwvdGxOS2dMVTBxc2pUbjNQeGZVZWZjRkl0NHpuCi9KL0t2RzJuQWdNQkFBRUNnZ0VCQUppdjZWZVcrOEd1eHFzRWQyRVJVMHpnd1VuYmFIWlE5akZacU93V3lGb2oKcHRqRDlOaWxvNm54L0k3MmNJMXJxNEtSNnVkSW1sYjdCSUQwWXVCazZ3ZW00amZGTEdwNGwra3pHL2taSlBjNgpYNWltRTdVbjJocEVhVk1CNDFCeFZIZ1o3cVVZdW4rZW9aV0FObE1EZFNVdTFseU9JbHFPbitRMEtqM0w0TjQ3CjA4eldPZXZISWw1TG1GMGhoTWNpVmpRWWhyWE5DeVQ1MU4vbWIxalhxTVhjKzBMRzRZY0NhZUxjbEJTeFViZVAKTnA0N1VVK3RxazVQY3hCQkE1NzJ0YUFrWXh0VEVYNnF5SGd2T1ViRjBNQzZGeEoxZ05QcUI3SmJ5Q2EzRnZDaQpCVUduUzc5ZTI0V1pzVDJiZFh6OHRXSUNNQXBnZ0NyOFozcEFveEt3ZHBrQ2dZRUE5cUZuUXdibnVxOHFYQXhXCmx5RytEc3lXNWdVdVlVUUx6YTExM1dVSVVxeHN6aUxwNGVrQVVUaUx2SUhzT0hvaWpVU3VGblA3N0hRZzRCbngKSGRpWVdIYlZQWVZmTmdvME5hYkRJYktkU3d3bXZFQWtCWlpmREdpY3hyV2xWbWp5MWRqNTBLQTNFd2tMQ2FCVApOeDFmbFpPWVBlOWZZN2NJUjc0V1ZoaTRIOVVDZ1lFQXdwMkM0NDltK01ISFNDQWQ4K0l5VEhoUEdHVnFOZzFiCngzNGlnOHNDZURCMm1BVjE5dGdhcHFoWFlsSkY5RGx6VnpYWFJVRThJNnFEODJRS0htM0p4OVd2eUxzRTlKU08KZm82TURKcGhnN2VGcElsSW9NVWo4YnFQQXBjUExDSGs5OTN6TjZSYzhlRW14Z1RiL21tenFzK2VjTVdab3NXegpmNkdYKzBzT0VZc0NnWUVBckt6eS9JWFFKdS9QYTZVajF5ckR3OTdRWS9vS3NBVVJjbzdaTUFvMTJwUm9sYWJ5Ck03NkwvMUhrM0RYbTZ0L3dZeEpNQk9KdDV1Nmp1ZVBQNG9Lc24zdUw3MGY3RW4zd2NnUHhLUjNDYlRIenlPZnIKa0pIb3VHcGlJZW81K1piL05tUjArL0hBdmE0ZU1UNDBKU21HcTlZcnlHbFpVeHBxVExpMU1OQ2IwWVVDZ1lFQQptYXlTL0dueUg1KzBZc21wblRrU0NydzlpTUFjSEU1MEdKVUxZQkpnQXRRUjhYenVaMXJCd0xQUlBMeEdyTkRvCnVRYTAwK1R0UGlTWlNRbkh5N3RaeUVoK0kvMDVybi9YL1N0R2YzVXdaemYxZWJWRitsMXhRcUhUNTNHczgyWlkKVFRtZm9tSlJXbFkxcmN1TWc5cW5tc3VUQ3UyZG9hQ0hXdE1aRmI5d2ZuMENnWUVBZ2ZiQk1TV0JZTkcxOFBjdQoyemNHdU9uQ2xvQWg5UzlTekpnUkZVaUJ1SFZyaHV3YUxvY3g1YUlwVXhBOWVZK296OVMxaStLbjZEc1FGc3UrCnh2SDJ3L1AxZ09nTHh5RjcvYVI3Nm5QL2g5UWd6ZEpZblN6Vk45QWtKRWFYVktVb0cvelZ2bkwrUWdXTlF3ZloKc2hrUmlEMGtDOWYxREhZVTdBMlNTN1hKbEVFPQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCjwva2V5PgoKa2V5LWRpcmVjdGlvbiAxCjx0bHMtYXV0aD4KIwojIDIwNDggYml0IE9wZW5WUE4gc3RhdGljIGtleSAoU2VydmVyIEFnZW50KQojCi0tLS0tQkVHSU4gT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KNmZlMzZmMmY4NGY5Yzg3NDE3OTVkYzYwNDdhMmE5ZGUKMjQwOWMxNGEwZTJlMzVjNDAyZjU5NjU0MmYxOWZhZjEKNDYzZTRkMjMyYTY1YzkyMjljMjJhYWQ4NDUyMzIxNWIKYWI5MzNjMjRlMDI5NWUxMWE2NmU0OWVjZjc5MTg0ZjAKYjgwY2RkZWMyNzEzZDM1OWZhMTg2MWE5YTg1N2MxOWUKY2E4YjEzZTdlNzI1NDUwZmRlNmEzZDE4NzZjZDE3YjQKNjBjYjcyMWRjNzE5ZGUzM2JhMDhjMDY0MjJhNTY3MzMKOTdjMDJmMTNhNTQ2MmUzNmVlMjQ2MGYyODZmMzNlZTUKZDIxMmM3MzRiM2Q3NWIwMzgzODY2NmNlNjMzNzU1YjYKZGZlZWFjNTFiN2JkYzQ2N2NhOWE5ZGQwZDBkYjVkMTQKNzUzNGQwYTk4ZTgyYzQ4NjkzNTBmOTY4NzAzMTBlN2YKZTMxYjg3OWM2NDk0OGI1MjYzYWE0MDhkNDgzM2VlNTAKYmQxZGJiZmJjNWQ0MDQyMjIwMmQwMzFhY2RmNGY5MTYKZTAxZDhhZDMxYTRhMDYwYjQxNTBjNmUzYWE2NDk4MTQKNjA4ZDlhNTFkNDNlZDA3MjJlNTc5Yzk3Njg3Y2M1MzkKM2NkNDUxNDFhNGZjNTUwN2EzM2MxZWVkNDA0ODkyODQKLS0tLS1FTkQgT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KPC90bHMtYXV0aD4K",
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

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 45,
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
