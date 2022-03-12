import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  HomeFragment({Key? key}) : super(key: key);

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OvO VPN',
              style: TextStyle(color: Colors.black),
            ),
            // GestureDetector(
            //   onTap: () {
            //     // FirebaseFirestore.instance.collection("vpnServer").add({
            //     //   "server_name": "Hong Kong - 4 (Beta)",
            //     //   "cod": "HK",
            //     //   "config":
            //     //       "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBTYXQgTWFyIDEyIDAzOjA2OjU1IDIwMjIgYnkgaW5zdGFuY2UtNAoKIyBEZWZhdWx0IENpcGhlcgpjaXBoZXIgQUVTLTI1Ni1DQkMKIyBOb3RlOiB0aGlzIGNvbmZpZyBmaWxlIGNvbnRhaW5zIGlubGluZSBwcml2YXRlIGtleXMKIyAgICAgICBhbmQgdGhlcmVmb3JlIHNob3VsZCBiZSBrZXB0IGNvbmZpZGVudGlhbCEKIyBOb3RlOiB0aGlzIGNvbmZpZ3VyYXRpb24gaXMgdXNlci1sb2NrZWQgdG8gdGhlIHVzZXJuYW1lIGJlbG93CiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1VTRVJOQU1FPW9wZW52cG4KIyBEZWZpbmUgdGhlIHByb2ZpbGUgbmFtZSBvZiB0aGlzIHBhcnRpY3VsYXIgY29uZmlndXJhdGlvbiBmaWxlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1BST0ZJTEU9b3BlbnZwbkAzNC45Mi4yNDIuMjQ3L0FVVE9MT0dJTgojIE9WUE5fQUNDRVNTX1NFUlZFUl9BVVRPTE9HSU49MQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9BTExPV19XRUJfSU1QT1JUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfQkFTSUNfQ0xJRU5UPUZhbHNlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0VOQUJMRV9DT05ORUNUPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfRU5BQkxFX1hEX1BST1hZPVRydWUKIyBPVlBOX0FDQ0VTU19TRVJWRVJfV1NIT1NUPTM0LjkyLjI0Mi4yNDc6NDQzCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1dFQl9DQV9CVU5ETEVfU1RBUlQKIyAtLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KIyBNSUlEQmpDQ0FlNmdBd0lCQWdJRVlpd05hREFOQmdrcWhraUc5dzBCQVFzRkFEQThNVG93T0FZRFZRUUREREZQCiMgY0dWdVZsQk9JRmRsWWlCRFFTQXlNREl5TGpBekxqRXlJREF6T2pBek9qQTBJRlZVUXlCcGJuTjBZVzVqWlMwMAojIE1CNFhEVEl5TURNd05UQXpNRE13TlZvWERUTXlNRE13T1RBek1ETXdOVm93UERFNk1EZ0dBMVVFQXd3eFQzQmwKIyBibFpRVGlCWFpXSWdRMEVnTWpBeU1pNHdNeTR4TWlBd016b3dNem93TkNCVlZFTWdhVzV6ZEdGdVkyVXRORENDCiMgQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFMWXJDRlRrYWlYOWpwc2cwU3ozYnJsQgojIGpPOWxSRUMvRjVJQTFBWWF4TEdCemttZndpVGpoVWlZT3Vndy93Zk1nOGZBS3NaS0o2Ylp5TGg1d2RSbURrTlQKIyBXQ3RoaUZDcWgvVTZsNWNKWk9YWENiR1F2bEhRdGRSRjk3WStqejNQaUtucVhQTGV3cVYrbVVMZW5XdzNqd0R3CiMgdjM5WGYrMTB5RjN2Q3hGT1h6N3Uxd2V2RXgweWZUWUsvTHFaWFBCYWxZNGprVGQ4UTBwUE1xeFFET2tWV1BRcwojIHozTXY1R3BrSmxhdUM3c1JnM2ZBYUF0ZU51QUJEejEwTjBQY1hhRFBVcWFnV2xzWHE5RkgvZTh4ZzNVRHg3eTkKIyBEMlJ5TFE2OFlQbksrRG1ZODlEbVZpNXFKZWRPZ3Z5RjF6R1hMcWRNZitQZThRZkEwbFRwWW9Xb1hueDc3NEVDCiMgQXdFQUFhTVFNQTR3REFZRFZSMFRCQVV3QXdFQi96QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFhakdUbG1MeQojIHlLWUUyV0NBbkRmamJoaWFwQjZZVmRlTG85ZjQ4eUJCaXI4b2ZnckN3aVd6SElGekhyQ21WVGZrZlhlYVJqNFUKIyBvMjNJcElCY0VnUXFJeWxGZS9LQjRuWTJIRWgxVW9oMmowNmMrb2RGZ3dkeDhvL0hXVWdTZnYzbitNMk93a1RiCiMgSUpoNFV1Y2VDTGtqbXd1TTZQd2xVTlB0NXJobk9iRWQ3Tm1jd1ZXVU5taHo0Nk1JNWtxTExWQ3J6RWVVMHBqVwojIG5PZ3dDOGdsVkNodXFFcmhqcGwzMzdnRVJUNUl0KyttYVBDUkM3aFh5bFNmakY1TjV5Um1CWkxINURhUUxabVoKIyB4a0I0dHdaV1BibDZMRWJEN2h0RkR5aGJpRDdza3lsZmtnS3YyYXViYk1zcjUyN0lyd3pHM0psWXpOV2Q4VzBXCiMgcDBwVXhxNzUweHo4Zmc9PQojIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KIyBPVlBOX0FDQ0VTU19TRVJWRVJfV0VCX0NBX0JVTkRMRV9TVE9QCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0lTX09QRU5WUE5fV0VCX0NBPTEKIyBPVlBOX0FDQ0VTU19TRVJWRVJfT1JHQU5JWkFUSU9OPU9wZW5WUE4sIEluYy4Kc2V0ZW52IEZPUldBUkRfQ09NUEFUSUJMRSAxCmNsaWVudApzZXJ2ZXItcG9sbC10aW1lb3V0IDQKbm9iaW5kCnJlbW90ZSAzNC45Mi4yNDIuMjQ3IDExOTQgdWRwCnJlbW90ZSAzNC45Mi4yNDIuMjQ3IDExOTQgdWRwCnJlbW90ZSAzNC45Mi4yNDIuMjQ3IDQ0MyB0Y3AKcmVtb3RlIDM0LjkyLjI0Mi4yNDcgMTE5NCB1ZHAKcmVtb3RlIDM0LjkyLjI0Mi4yNDcgMTE5NCB1ZHAKcmVtb3RlIDM0LjkyLjI0Mi4yNDcgMTE5NCB1ZHAKcmVtb3RlIDM0LjkyLjI0Mi4yNDcgMTE5NCB1ZHAKcmVtb3RlIDM0LjkyLjI0Mi4yNDcgMTE5NCB1ZHAKZGV2IHR1bgpkZXYtdHlwZSB0dW4KbnMtY2VydC10eXBlIHNlcnZlcgpzZXRlbnYgb3B0IHRscy12ZXJzaW9uLW1pbiAxLjAgb3ItaGlnaGVzdApyZW5lZy1zZWMgNjA0ODAwCnNuZGJ1ZiAxMDAwMDAKcmN2YnVmIDEwMDAwMAojIE5PVEU6IExaTyBjb21tYW5kcyBhcmUgcHVzaGVkIGJ5IHRoZSBBY2Nlc3MgU2VydmVyIGF0IGNvbm5lY3QgdGltZS4KIyBOT1RFOiBUaGUgYmVsb3cgbGluZSBkb2Vzbid0IGRpc2FibGUgTFpPLgpjb21wLWx6byBubwp2ZXJiIDMKc2V0ZW52IFBVU0hfUEVFUl9JTkZPCgo8Y2E+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlDdURDQ0FhQ2dBd0lCQWdJRVlpd05aekFOQmdrcWhraUc5dzBCQVFzRkFEQVZNUk13RVFZRFZRUUREQXBQCmNHVnVWbEJPSUVOQk1CNFhEVEl5TURNd05UQXpNRE13TTFvWERUTXlNRE13T1RBek1ETXdNMW93RlRFVE1CRUcKQTFVRUF3d0tUM0JsYmxaUVRpQkRRVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQgpBTExWNFVacEF5NHhXSlltWVlCalVHV1hxY0RSWGZJSmhONnZ5Rm81WXptVWRkWEF4ck1nd0VldnJuQm4rbk9GCitmTTdQbVduc0xRdWh4NjAzNmljaHZVd2lPTGZLMDNPNm5jNnllcXlxVUdHaytuaTVWY1BaU0x2Y2RKanJndDEKd3hIV3lXVjE5dG52d3JMWHdrSnRKRkpXWFIyanZxOVltdU1TWmlnT3pVSW9GVDEveURtelR1eExKRUVraU9TSApMbFlBSkpsTWRsNHE2d0hUZXhkS2N6dHh5UWZKZy9EcnlqZVhiMW0yS0JVNVRtWHhDWVFrWUUySmFYT3RZOGdGCkJBRGI4SnordkxCVWhKNHoyeXRuNk50aU1Idms1WnFlaGk4N1R5YVFTbDVLaGtKUDdtbmx4OC81MjZpcTVyZ0gKdHVzWUVkemRpWitUVlRiYm54SDdKY3NDQXdFQUFhTVFNQTR3REFZRFZSMFRCQVV3QXdFQi96QU5CZ2txaGtpRwo5dzBCQVFzRkFBT0NBUUVBb1dZQXZnMWN1aGJHZ2NLdWoxcDV6NytvMW1aS1hGd21IWklkSEc0VzRMK3owQTYrCkVOL3c4czBSYTZjNVN0VFBuWVRiTllvM2xJYU1lSFpKNkErRWRSMzlTVDFCaEVJRytwSDFQRmNGZUE4eG5WU2UKc2FGK2kwWWd0NUtMUG9hM2dsSUlsN3ZQZ3V6UkU2VEF3WjhNeDVuU2hubVN0MFhqZERxRFFOUmhEbGxkcEpHYgpiU09FeDRZSElSZEJVZ2lYYm5xY0V0S2FIWUNUR0orU3g0Rmg2SS9aVGtUMWVDOUxTdDJ0dldGZ0lIS3Z4SUJqCnFOck9SWndVSEQ2MzIwMG45V3lEMkFTZ21yUldjdHFWTUxNbUdEZCtSL0NRRWxmRml5aXp6dTRTTTRISWU2dFIKeGVQeDZaLzZZdUpFdzdzN1Z3Ky9mdVhJQ3NwZ1czYWl5endsV1E9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2E+Cgo8Y2VydD4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN6RENDQWJTZ0F3SUJBZ0lCQXpBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwUGNHVnUKVmxCT0lFTkJNQjRYRFRJeU1ETXdOVEF6TURZMU0xb1hEVE15TURNd09UQXpNRFkxTTFvd0hERWFNQmdHQTFVRQpBd3dSYjNCbGJuWndibDlCVlZSUFRFOUhTVTR3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURJWEQyKzhBelBYaTZVSFN3V3IzaU9uY1VNdmRqT1A1cW9nOC9HS0F3d1NpUi94K0diVmJkY2dKUzkKclRxdXpkcTFrbG9nZlAzRzdQeGZqa2haRU1FMXpHdHlQbGhCcnlXVzlaazlQdGFHSVV3OWV4TTh3aHU1ZXFZRwplM0MyM3VmWTAyQW9YYTFUTlVpWEI5d3czQlpTRFdIOGE5UmlNRG1iSG1jVkpjNkFCdXdpYzBRaUtzY2R5UGNWCmNvR2ZPQmJla3NOV2JMQ1RGRUxQaVBiQ1JEVmhDS3JITnBzT3NLd29BUGlpNnZaYUprSlFwdDZ0aFBwN1ZVTHoKY1czNTV4Sm5HelEvbG5pV25odXgwRDJMK1Z1Q1BEeDFvRmFxaEdDNWJCZmd3T01iZHYxWjFTN25FdkZ2Ri9qSAovaTJkSXc2N2IrSHpDbjZLOW9pU25tOHpiOGxaQWdNQkFBR2pJREFlTUFrR0ExVWRFd1FDTUFBd0VRWUpZSVpJCkFZYjRRZ0VCQkFRREFnZUFNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNaUmxzQ3JCOFFRTlVXbFBPY0ptS2YKdE1iTUJFK01xMk0yaDJBckd4WHJDb0hLUGd5OVV4aVZLNURvcGdYNmtmNFR5OTlYSTdodkxKTVFjZlh0SWhKQwptVndwWU53ZllZV05RUG11RmpaNUlaL2lhT1BOeDRhelo1VDAyejNlVng4QnhZMEUzRGlOejloUDNXMnFZUmt5ClhRN2lybmc0ZmV3RFdYWDM2cm1JdDdVOEt1dDdzeW9UMkZzT29YZ2h1MmkxNmJFaHg2STRCWUZqbXJGZ2dBSnoKTWkxRHhnaW10c3c4YmNEaXJpNmFXWWcxSndKTGhNQXppQmhHWUVDSHdzR2MzdGJuZHEwZjZNcC80TlZyUGpYVQo1Y29jQ2FtUkxyRmdjWFZ3MFZKRlRnTjdncHRaaFU4cFNINUpCK084Wi9JbktZWHBnNTArbTlPWlU4VmkzTmdHCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KPC9jZXJ0PgoKPGtleT4KLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2Z0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU2tBZ0VBQW9JQkFRRElYRDIrOEF6UFhpNlUKSFN3V3IzaU9uY1VNdmRqT1A1cW9nOC9HS0F3d1NpUi94K0diVmJkY2dKUzlyVHF1emRxMWtsb2dmUDNHN1B4Zgpqa2haRU1FMXpHdHlQbGhCcnlXVzlaazlQdGFHSVV3OWV4TTh3aHU1ZXFZR2UzQzIzdWZZMDJBb1hhMVROVWlYCkI5d3czQlpTRFdIOGE5UmlNRG1iSG1jVkpjNkFCdXdpYzBRaUtzY2R5UGNWY29HZk9CYmVrc05XYkxDVEZFTFAKaVBiQ1JEVmhDS3JITnBzT3NLd29BUGlpNnZaYUprSlFwdDZ0aFBwN1ZVTHpjVzM1NXhKbkd6US9sbmlXbmh1eAowRDJMK1Z1Q1BEeDFvRmFxaEdDNWJCZmd3T01iZHYxWjFTN25FdkZ2Ri9qSC9pMmRJdzY3YitIekNuNks5b2lTCm5tOHpiOGxaQWdNQkFBRUNnZ0VBT0huUHFjZHVSUEZ1UGErdllzR1pRTkgxM2k2Uk15bTRoWEdLR25mbFg2TTIKZ0pJdDVLUVhxRXBTSXRqMlpwbDk0WnBjTHpZc0xtdFVnL2JPSzlUT01VVHFzR3drWW5kbEtCVVlXYXdodWZNZQowMkdpdllpVldnWFpVSkJ3NkFzUzNRcFAyM0QwVHpVQXZobW9GbG1qTFFPNnIvVVJDNUErWEp3SVFHekV0VTgrCmdidjBVbUhUTWM4Ty9pdlNycmtOcExuTkpwOEtTRDRqMlRRTnM1U0lKRWZMbTc5YVBoT1FJWXQzQU05WGMxeDYKWm5PeTljN2Y0VHJvZU1MMnFtc3JlQ2VpL203NFdhbFlLZ2hsbVdaTHpxaVY4Um45UnJNQmRmdzJOWHduY0lJaApQQzVxN1FyZkg2ODh5Rm9Sd0ZTNnRzWWVPR0lFejZOcG9pWS9DL25vVVFLQmdRRG5SVXY3b1hSSUg3UFF1U09QCmRoM1RRcjRFNmM3cGVIZFBCSU1PckJGeDdXK0RjUXhhenpramM1TTRpWXM5RzZMRzBpY2dhOExlNW92MzBEZDUKNmdrSmdEdHh1cnVSQlhNSTNSUTF6RWtZb2FJVEZrOEE5M2Z5elo4M3B0dkxjcWxrSWs5VlJxQzNTRXRLRm1uMQpMcFBwNTBnVFZyRUtPcG96T2tlaVZIemM3UUtCZ1FEZHlORTVUMGQxRDdUaGNQV2ViN29aRVVrcXlkbkkxUkZHCmtBREFzWDBQZHpQRkJSd2FIbEkyRy9mSWNCZklaU29ycFJzdThaQmNrdlhCR2gyWUJubE5WQmFHWERJdmhmS00KaHZ1azFTOFBSVUwvKzQzeDE2OTBFdjdVM2VMY3dPRnJTWFhDYUhudUVDYUVpd3F4REFIL3RibTdpUHlFL1dyRgpEQkRpTlkvOG5RS0JnRFcvZmlReDVyTm9Zc0xzZEI1QVJqZzE5N0Z1b1Q3VFYyOE96bUtYak1wY2N5RXFJY1B0CkN3dDVMY3JpOUhBMFB3VlVDL0hWK1lrU0xZOWZYYlZBdGU3MlZWcGVHbjllczlob2dPenIyRVVZTTNHYUtxdy8KMXltZnJoUWgvRXp4RGZzT21qOW9WYXVpNnBTQ1Z3ZTdWbmJ5NEdaV0xIa0RHNWt5UHptenh2MFZBb0dCQUx6YgpaNGFVd3ZXazlWTlAvR2Y1SGhDQWpyeVgvQk12bExGd3FLTnR3Ri91RXJCLzVHazlUcVp5OUhIRE9nMVVVQyt3ClBkQ2d0VnlQYkNRT1dBci80RVdBQ0ZwTG9oU2p6R0hzQTlkZURkL0VEQVN0TWpjeGdsK21XVWZzMW1WQy9mRjkKTVlEbHRJYUxUREZyc1NRSVpKOWFJUm5YMGFoeG4zekNCSktNSjl0bEFvR0JBSzYyOTNCN1cvNkU0M1FndENYbwo5eVRReWpTdytMaVZTaW9jWVpOeWRaZ1d6NXk4U0U5WFZzU082TkRqbkVzekhZRU1yTHlSY0xrUlBFVnR1VDVWCkRKWFIvTkFhaFZ6SEJ0eUxUbFRuOEovaEdNOERFR2RXRUFQNnF5djI0blBhMmRqVDIzeVpiZDFORXo0NE1iT3cKci96WlZVK1l6QnBTdnZOdUFpL1NJQ2RwCi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0KPC9rZXk+CgprZXktZGlyZWN0aW9uIDEKPHRscy1hdXRoPgojCiMgMjA0OCBiaXQgT3BlblZQTiBzdGF0aWMga2V5IChTZXJ2ZXIgQWdlbnQpCiMKLS0tLS1CRUdJTiBPcGVuVlBOIFN0YXRpYyBrZXkgVjEtLS0tLQo0NmU1YjU3ZDA3YWMyMTE0YWY3YWEwNTVjOWUzNTE5MQoyYzNiYjM0MTUwZjQwNDAxZWY4ZGMyZGZiZTE4NGNkOQpkMDc5NDQ3NWNmYjFhMDgxNDY2ZTdhY2VlNmRmOTE3Nwo3OTVlM2YyOTI5MjMxMTQ0ZTVkMTFkODM2NTYzMTFhNgo2ZTRkYTI1MTMyNjk5YTVkNGFmYWJlZTE2NjJmOGFjYwpkZDE3YjE3ZTgzYjdlYzQ1MGI5NzBmMTcwMzNlOTYxOQpiNmEyZGJhZGNkYWViNDNlYzEzNzA1OGQ3MzI5ZjI2YgpkMmFkOTM0OTRjNzhlZjdiMmRhOTI4ZjgyYjJjMzE0NwowMmE0MzM5YmNjMzEzNTNmYTRjZTUxMDZiZjc4ODEzNQpmYjdmODBjNTI4YzYwODljYmRhMDY0ZTg1ZTU2OTUxOApiYjQ4MGI3ZDA5YjA4NWFkODBhN2EwNTc5ZThlYjBlMApjODMyYjQ1ZDkwMGUyNzFkYWQ4MzY5NDBhMmQ1MWU3OApjY2FlMGEwOTMxNjdiZWY5NzJiYzYxZmU1NDEzMTQyYgo1ZWUyZDM5YjZiY2I0MWM1ZjY4YmYxNGMzYTI5NTdjMgplNTNhNzczYWNmNGVkMmU4MzllYjE2MGFjODE3OTM2MApjMmUxNGY1ZDc3OWNmMDliMmRmNjg1N2NhYzUzZTY2YgotLS0tLUVORCBPcGVuVlBOIFN0YXRpYyBrZXkgVjEtLS0tLQo8L3Rscy1hdXRoPgo=",
            //     //   "username": "ovo",
            //     //   "password": "123456"
            //     // }).then((value) {
            //     //   print(value.id);
            //     // });
            //   },
            //   child: const Icon(
            //     LineIcons.videoAlt,
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
                      margin: EdgeInsets.all(5),
                      padding:
                          EdgeInsets.only(top: 8, bottom: 8, left: 5, right: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LineIcons.adversal,color: Colors.green,),
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
                : SizedBox(),

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
