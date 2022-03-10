// ignore_for_file: unused_local_variable, curly_braces_in_flow_control_structures, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn/Router/route.dart';
import 'package:vpn/configs/admod_config.dart';
import 'package:vpn/controller/update_controller.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/model/vpn.dart';

const String testDevice = 'YOUR_DEVICE_ID';
const int maxFailedLoadAttempts = 3;

class HomeUI extends StatefulWidget {
  const HomeUI({Key? key}) : super(key: key);

  @override
  State<HomeUI> createState() => _HomeUIState();
}

class _HomeUIState extends State<HomeUI> {
  UpdateController controller = Get.put(UpdateController());

  static final AdRequest request = AdRequest(
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
    if (bytes < kiloBytes)
      return bytes + " Bytes";
    // return KB if less than a MB
    else if (bytes < megaBytes) {
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

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'OvO VPN',
              style: TextStyle(color: Colors.black),
            ),
            // GestureDetector(
            //   onTap: () {
            //     FirebaseFirestore.instance.collection("vpnServer").add({
            //       "server_name": "Hong Kong - 1 (Beta)",
            //       "cod": "HK",
            //       "config":
            //           "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBUaHUgTWFyIDEwIDA5OjIyOjQxIDIwMjIgYnkgaW5zdGFuY2UtMQoKIyBEZWZhdWx0IENpcGhlcgpjaXBoZXIgQUVTLTI1Ni1DQkMKCnNldGVudiBGT1JXQVJEX0NPTVBBVElCTEUgMQpjbGllbnQKc2VydmVyLXBvbGwtdGltZW91dCA0Cm5vYmluZApyZW1vdGUgMzQuMTUwLjEyNy4yMTAgMTE5NCB1ZHAKcmVtb3RlIDM0LjE1MC4xMjcuMjEwIDExOTQgdWRwCnJlbW90ZSAzNC4xNTAuMTI3LjIxMCA0NDMgdGNwCnJlbW90ZSAzNC4xNTAuMTI3LjIxMCAxMTk0IHVkcApyZW1vdGUgMzQuMTUwLjEyNy4yMTAgMTE5NCB1ZHAKcmVtb3RlIDM0LjE1MC4xMjcuMjEwIDExOTQgdWRwCnJlbW90ZSAzNC4xNTAuMTI3LjIxMCAxMTk0IHVkcApyZW1vdGUgMzQuMTUwLjEyNy4yMTAgMTE5NCB1ZHAKZGV2IHR1bgpkZXYtdHlwZSB0dW4KbnMtY2VydC10eXBlIHNlcnZlcgpzZXRlbnYgb3B0IHRscy12ZXJzaW9uLW1pbiAxLjAgb3ItaGlnaGVzdApyZW5lZy1zZWMgNjA0ODAwCnNuZGJ1ZiAxMDAwMDAKcmN2YnVmIDEwMDAwMAojIE5PVEU6IExaTyBjb21tYW5kcyBhcmUgcHVzaGVkIGJ5IHRoZSBBY2Nlc3MgU2VydmVyIGF0IGNvbm5lY3QgdGltZS4KIyBOT1RFOiBUaGUgYmVsb3cgbGluZSBkb2Vzbid0IGRpc2FibGUgTFpPLgpjb21wLWx6byBubwp2ZXJiIDMKc2V0ZW52IFBVU0hfUEVFUl9JTkZPCgo8Y2E+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlDdURDQ0FhQ2dBd0lCQWdJRVlpbkJHREFOQmdrcWhraUc5dzBCQVFzRkFEQVZNUk13RVFZRFZRUUREQXBQCmNHVnVWbEJPSUVOQk1CNFhEVEl5TURNd016QTVNVEkxTmxvWERUTXlNRE13TnpBNU1USTFObG93RlRFVE1CRUcKQTFVRUF3d0tUM0JsYmxaUVRpQkRRVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQgpBTUN6RHVGaVdzb1J3LzNsRDB3dWtTSFpiZStac1AwQUpWTzZ4a2FydTI0MkpmODhzSEFtbnV1bXJUQWV6eXFHCjlWZVJlTXpVM0F2cHZSTVF6VXNpRitwSUxNTmxOR2FxbkROdm45ZFB1K0VzUlY5RU9WZmQ1NGVRZGVnRGtJQUIKV1VHSjBTaUJqdVViN3E2UVcrTndzMlBjUVRYdld6NG5RWXhVb05rdSt2U0Z4QWNPRGo2VjJhelVTdXJ5OXVVRAp0c0pLUHpPdVZIM0tIMjBLMXgwVUlvNkJsVzRVcVJVRVlIM1FZRU9vUEM1R0pOUDV4ZS9oeENqYXFCeW13VUJnClorV0NuS2pGaklWbHlhWGNKaVVSdlI2b2kzRWgydUhvS1dCSkljdXlIakYvN1NoV0prVHhFamV1M2pIWVEvUWQKTHh6KzhjMjZiT1dmR1J0OWE3NlMrTDBDQXdFQUFhTVFNQTR3REFZRFZSMFRCQVV3QXdFQi96QU5CZ2txaGtpRwo5dzBCQVFzRkFBT0NBUUVBcUhidnZmdUhWZ3FoM1MzQy9zZWZXYTJYeFJXby84VkpmS2JzYVBqSVBRUGVkU21JCkUzaU9EWlJjZWpHR1JxOXpWcnp2Y0kxdEQ4dFpxV0dVNkM0MzZtQXArL3F5S1h0UHN6S21zbkdEbWtRVER4V0IKczFCNVlxeENtOEFGRFJxQyt1SU1ZdEgrd0wwWEh5NHVhTlYyZnYyaURTRnQvbEI5dGhpSnJnUmxRQTZ5NjBuSQpTZGxRcUsxM1B3UlhPNHppVll4RG5SWG9GanREMEh5bXhUSjNWZE5pTGFoSGxHUjZQeHNVdWd4R2huVDBnSHVMCm8vZUtEN09aMTFBTXE5bTR3WmJVQ2YxaWM0amh0eTBIYkZQLzRNN2xuczJkY2RROFFqcHNiSlBSWGl5VTBQT0sKT1RhQmdnSktmcG5BcTZPbGtsMGlNRUh2R28wNkhUem5QUElmVWc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2E+Cgo8Y2VydD4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQXpBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwUGNHVnUKVmxCT0lFTkJNQjRYRFRJeU1ETXdNekE1TWpJek9Wb1hEVE15TURNd056QTVNakl6T1Zvd0dERVdNQlFHQTFVRQpBd3dOYjNadlgwRlZWRTlNVDBkSlRqQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCCkFNbUJXbmE3Rk5GK2NHaVJtNU9YcHplREtoUUR3OGxlYVpqQU1rVXljWU9WSHRNSXZWbE5XWHJlL0hKZ2hCN28KNFBPK2NnL01LNEZqYjJtbXh1RnV1ckVnN0FjVmZpS21kVXV2Y1NZR2hzTFdCQ0tNeWRiZGIvZ0JCM25VNm50YgpMd1VoODRPa0krVEhzRlNzZmppSzNLaFJjem5iNHNjRnFxZ0QyZjVFWFNjN1VxUXZ2ZTEyK0xtZGR2V0xpcWNuCnowbm9tM3BuTTFNM2JTMWtjMHFYUlllR213dy85Q3M0V3lMSjRjaEJJV0VlODJLRVFndFFDOVVJcStpdXM4aUMKNEVwSkJQUDk3dXFDQm5OVldDYjEyWkFjR1NBbWVtOWh1ZFgxRDduYy9LZUl6VkRxbzN3T0IyTXY3UXZNUWcrZwpLRDdORGFwdnBKbE51ZDRFaWhlY2RUa0NBd0VBQWFNZ01CNHdDUVlEVlIwVEJBSXdBREFSQmdsZ2hrZ0JodmhDCkFRRUVCQU1DQjRBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFJcTdZUWhCTGlxNWxXbFhWeUE1ODN5MXZjZWwKWWRLSXV1eURsSDdHWXp4R3VOQmlMUHJSYXRiNG1wTXZOdEV0cHMzclkvS3VrU2tLejFYc0lpeFE2MnZOby8xOAowTWxYei9BOHI5dlVFSWF3M0xhOEk1SUpEeGlWZ2lkYlYwK3BYOXpxUGVEL2d1OWlYNG5iZUx2Z0Z3TURJdVlTCjVmbzh2TmlFMlhQTzJlamdTaUZGVFQ1RDRpQ3pRb2p5dnJTeG01UWlHUjV6WHRFYXhSc2xPMmZmdW5CNUJ5aHAKTitaUE1pNXhUcDBUZUkyTlVLbUo4SzRhSUNvcUM5ZEovSXBXZ0JObHFlU3dHT2pNcG90NTJEc0FIZ2UyMjJDdgpTL09jTDlYb3BLcU5tenNpVVRNVUhndC9jL2t4NkJLN1RHVjNlMkw5cWc0VitXRU1PUnVjRUlhMnhkQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo8L2NlcnQ+Cgo8a2V5PgotLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS0KTUlJRXZRSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS2N3Z2dTakFnRUFBb0lCQVFESmdWcDJ1eFRSZm5CbwprWnVUbDZjM2d5b1VBOFBKWG1tWXdESkZNbkdEbFI3VENMMVpUVmw2M3Z4eVlJUWU2T0R6dm5JUHpDdUJZMjlwCnBzYmhicnF4SU93SEZYNGlwblZMcjNFbUJvYkMxZ1Fpak1uVzNXLzRBUWQ1MU9wN1d5OEZJZk9EcENQa3g3QlUKckg0NGl0eW9VWE01MitMSEJhcW9BOW4rUkYwbk8xS2tMNzN0ZHZpNW5YYjFpNHFuSjg5SjZKdDZaek5UTjIwdApaSE5LbDBXSGhwc01QL1FyT0ZzaXllSElRU0ZoSHZOaWhFSUxVQXZWQ0t2b3JyUElndUJLU1FUei9lN3FnZ1p6ClZWZ205ZG1RSEJrZ0pucHZZYm5WOVErNTNQeW5pTTFRNnFOOERnZGpMKzBMekVJUG9DZyt6UTJxYjZTWlRibmUKQklvWG5IVTVBZ01CQUFFQ2dnRUFUNTgxUjhVVXJOTHhSK0NCUVFpam9tUEp0SzdvSmlHUVNETnBxYjRNN0psMwozSnVQZGtJQ0lYTUsvWWIxcmVFSFFrajJlUmVMK1V4NU1aNGM1K2NCRGd5Y054QmZEd0lIUnlqRDVPcWZSVTJiCnhLc3M5aUg1cEYyRHZyaExEd013eVM1cE1wTWhPNzFNQjZsQkZzYUgrbHAwMVYvMWMvN2hPQktOaU5NcW05MDQKWjhweUJRckloUmRUMHlhWXp3R3JEa01JdGswL05iZWt0UVlwTUN4R2JHM29BL3h0blFGekVtVDgwcDVJYnRvRwpvdzFYTzdwc1kvN1lROFIxQ28rZWpCM1FTM0pYU3ZhZnhnamZXaFhLVnY0SkthK2lSc0owd2JlQlhuWDdFV1FVCmFZSGRzdWZRNmpHS0dQSE9vOTVCSmk2VUszck5IQzJ1MW5Qb2VwbDhBUUtCZ1FEOTJhdE5nak4rNGtLVjRNZDYKZ0pxUDJLSlJYR1kyNk9vUVpQQWhSdmloMytON3Y1Y1YvbG0zZDBSVFFpTkRCbnYraTZ3T2djc085c05rWkFkZgorN0tKbGxjYnJ0NEpob2hHS1JmQm9xWk0xMFJrdVJ5NHFsNE5KcDY0VHRjZkhvNHFvQUFmSWVNOUZQUkZSOHlTCkFYUEIrWW54ejRieS9GNTFGYjJpY3cvZGlRS0JnUURMTmpRbVBlWnFsRFo5cFdPeW5iV1BvczBQdlNUcVdydlMKTGRCUWh5b0Fmb3lKOTVsRnJ5SUUvSUUyK3VVMmtCTDNaaHUzd2ZoZldHMEViWU9TbW94a3FnUWk2VE43Y1VoVgp5M1hEdVh3SCtCdDZ3SG5jYi9OWklSbHFRcklaUURxTzhZdkh3OW1jVmthRzEycE1sclN4aENOTERJRjdObFZDClhtN3V4blVlTVFLQmdRQ3RDVEFVMEhqTHQrMk5mc0JiQjhqVDN1YWVNUzdYcFNMUDlBNGZrT0l3Ylk0Q0w1SU0KZ3VtaS91Q0xKRjBtOWdlVmRwM2M4YXA1MDhsUzZFQ0NzKzU2alFscHJHUmI5K0Z5ZWRaZ3ZyOC9SOG11SXVTcQpHQyt1SlRJeURrUGpTWSs5REgyb3V3L0w5am1mOUJaRlBFb3M0aTJlc0VpYjMxMS8wRWNJc2dnUmlRS0JnQWNZCkxWbm9iMUxwT2IzSk9HSFQvN0swREZTd1ZjbVl3VlhsSTVDc0oxczlEOHNCU2VpVTVLc241WnIxeDJyUVBObEcKUjFGekJDalAvWDVhRkczWjEyenNRcGkxYTRhenZjTEJCNnQ5bmtibzhveW1pNXFXamZoZW4zU0dQNUdDSElsQgpCWkJEMWlVUEhnYzNIZzd1ZEFCK2pIemlRdUw2VXArdWpGRHB2TTBCQW9HQVlNTmF5dHdQWnFFU3UxNzQxR2t5CkxoeHlCeUZycGltQktMbmFFUUM5c2cwbkJJTkRjQVZLTmNwSWd5R2JXMGZpMVM0ZDV4Y1MrcXErcFBRcy9oaDEKNUZmRGhqbS95Y0xiRUJxaUJ2ZVlQdC84Zk9PSjJ2ZWpEa0FnQUtxN2dQMHRudEN0bmdPdmZ1MmRVZDkzNTdIQgpIb25pVld2ZDB5UlZMd29aa0x6M2VCOD0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo8L2tleT4KCmtleS1kaXJlY3Rpb24gMQo8dGxzLWF1dGg+CiMKIyAyMDQ4IGJpdCBPcGVuVlBOIHN0YXRpYyBrZXkgKFNlcnZlciBBZ2VudCkKIwotLS0tLUJFR0lOIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjQyMWIyMTA1ZjU2NTlmM2YyYTY2OTU3NGY4NDg5MTRhCmQ4NDBjYmFmYzhhODIyNTkyMWJkNmJmNGU4MWQ4ZTE1CmEzYWEwNzE1MmM0NDg4YzEzY2VlNmMzNzcyYmQ3NTYxCmVjMjM2MmY1MWRhYTdhYTI3NjkxYzBlNjIyMjVhZmQ5CmU1MGZmOGVkYTQxNzhhYzJkZDdlODVmZWE5MjkwMWRlCjJjMmE5Yjg5Yjg0NzIzZDA4NGUyYWY4NzgyNDZhYjgxCmFiZDE5OTMzMGI3YTMwZTg1Y2ZmYjA2YjNjMzMwOWIwCmE3OGEwMjUwMWRkYTJhZTEyZGIyN2IyY2EyNTJjMWYzCjUxOTYzMDE2ZGFhMjFhOWJhNDk1Zjc1ZWE5NDBiNDZiCmIzNTE1YTZhYmM4NDNhNGQ4MDU0NGE3M2MyOWQxN2NkCjhjZGZlZTEzOTM1NjRiNTU3Y2I1YzQ3MGM1OWQ5ODRjCjljNjViYjEyNmE3ODkxNjQ2N2RhM2EyYWQxZmY5MjM4CmI1YTQ3YzY4Y2JjMDk5ZWZmOGE3ODU2MzJjYTAxMmNkCmFiMzZiNjQwODgzMmM0M2E1NDQwN2I0Y2Y4NzFhYjJmCmM1NDk1MGZmNzVjZGE3Y2YyMTMzZTI3MGVhZjhiOGU0CjVlMWQzMDFmMzYyYWZmOGQ2MDY5YmZjNmI0OTlkNzkyCi0tLS0tRU5EIE9wZW5WUE4gU3RhdGljIGtleSBWMS0tLS0tCjwvdGxzLWF1dGg+Cg==",
            //       "username": "ovo",
            //       "password": "123456"
            //     }).then((value) {
            //       print(value.id);
            //     });
            //   },
            //   child: const Icon(
            //     Icons.settings_sharp,
            //     color: Colors.black,
            //   ),
            // ),
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
                return Card(
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
                                      if (controller.haveVpn == true) {
                                        if (_granted == null) {
                                          engine
                                              .requestPermissionAndroid()
                                              .then((value) {
                                            setState(() {
                                              _granted = value;
                                            });
                                          });
                                        }
                                        if (stage.toString() ==
                                                VPNStage.disconnected
                                                    .toString() ||
                                            stage.toString() == "null") {
                                          initPlatformState(
                                              vpn: controller.vpn!);
                                          _showRewardedAd();
                                        } else {
                                          Get.defaultDialog(
                                            titlePadding: const EdgeInsets.only(
                                                top: 10, bottom: 10),
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    top: 10,
                                                    bottom: 10,
                                                    right: 15,
                                                    left: 15),
                                            title: "Warning:",
                                            middleText:
                                                "The connection will be disconnected.",
                                            middleTextStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16),
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
                                    },
                                    child: Container(
                                      height: 45,
                                      width: 150,
                                      padding: const EdgeInsets.all(5),
                                      margin: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
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
                                                          VPNStage.disconnected
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
                                                  fontWeight: FontWeight.w500),
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
                                                    stage.toString() == "null")
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
                );
              },
            ),
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
                  : SizedBox())
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
                    Icon(icon,color: Colors.green,),
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
              Text(
                "US Server is Down",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Get.back();
                },
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
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
    // TODO: implement dispose
    super.dispose();
    if (Platform.isAndroid) {
      _bannerAd?.dispose();
    }
  }
}
