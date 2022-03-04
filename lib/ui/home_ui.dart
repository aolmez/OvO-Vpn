import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn/Router/route.dart';

class HomeUI extends StatefulWidget {
  const HomeUI({Key? key}) : super(key: key);

  @override
  State<HomeUI> createState() => _HomeUIState();
}

class _HomeUIState extends State<HomeUI> {
  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;
  bool _granted = false;

  @override
  void initState() {
    // TODO: implement initState
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
  }

  Future<void> initPlatformState() async {
    engine.connect(config, "USA",
        username: defaultVpnUsername, password: defaultVpnPassword);
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OvO VPN',
              style: TextStyle(color: Colors.black),
            ),
            GestureDetector(
              onTap: () {
                // FirebaseFirestore.instance.collection("vpnServer").add({
                //   "server_name": "USA",
                //   "cod": "US",
                //   "config": "ZGV2IHR1biAKcHJvdG8gdGNwIApyZW1vdGUgcHVibGljLXZwbi0xNzMub3Blbmd3Lm5ldCA0NDMgCjtodHRwLXByb3h5LXJldHJ5CjtodHRwLXByb3h5IFtwcm94eSBzZXJ2ZXJdIFtwcm94eSBwb3J0XSAKY2lwaGVyIEFFUy0xMjgtQ0JDCmF1dGggU0hBMSAKcmVzb2x2LXJldHJ5IGluZmluaXRlCm5vYmluZApwZXJzaXN0LWtleQpwZXJzaXN0LXR1bgpjbGllbnQKdmVyYiAzIAo8Y2E+Ci0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQpNSUlGM2pDQ0E4YWdBd0lCQWdJUUFmMXRNUHlqeWxHb0c3eGtEalVETFRBTkJna3Foa2lHOXcwQkFRd0ZBRENCCmlERUxNQWtHQTFVRUJoTUNWVk14RXpBUkJnTlZCQWdUQ2s1bGR5QktaWEp6WlhreEZEQVNCZ05WQkFjVEMwcGwKY25ObGVTQkRhWFI1TVI0d0hBWURWUVFLRXhWVWFHVWdWVk5GVWxSU1ZWTlVJRTVsZEhkdmNtc3hMakFzQmdOVgpCQU1USlZWVFJWSlVjblZ6ZENCU1UwRWdRMlZ5ZEdsbWFXTmhkR2x2YmlCQmRYUm9iM0pwZEhrd0hoY05NVEF3Ck1qQXhNREF3TURBd1doY05Nemd3TVRFNE1qTTFPVFU1V2pDQmlERUxNQWtHQTFVRUJoTUNWVk14RXpBUkJnTlYKQkFnVENrNWxkeUJLWlhKelpYa3hGREFTQmdOVkJBY1RDMHBsY25ObGVTQkRhWFI1TVI0d0hBWURWUVFLRXhWVQphR1VnVlZORlVsUlNWVk5VSUU1bGRIZHZjbXN4TGpBc0JnTlZCQU1USlZWVFJWSlVjblZ6ZENCU1UwRWdRMlZ5CmRHbG1hV05oZEdsdmJpQkJkWFJvYjNKcGRIa3dnZ0lpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUsKQW9JQ0FRQ0FFbVVYTmc3RDJ3aXowS3hYRFhidHpTZlRUSzFRZzJIaXFpQk5DUzFrQ2R6T2laL01QYW5zOXMvQgozUEhUc2RaN055Z1JLMGZhT2NhOE9obTBYNmE5ZloyalkwSzJkdktwT3l1UitPSnYwT3dXSUpBSlB1TG9kTWtZCnRKSFVZbVRiZjZNRzhZZ1lhcEFpUEx6K0UvQ0hGSHYyNUIrTzFPUlJ4aEZuUmdoUnk0WVVWRCs4TS81K2JKei8KRnAwWXZWR09OYWFuWnNoeVo5c2hackhVbTNnRHdGQTY2TXp3M0x5ZVRQNnZCWlkxSDFkYXQvL08rVDIzTExiMgpWTjNJNXhJNlRhNU1pcmRjbXJTM0lEM0tmeUkwcm40N2FHWUJST2NCVGtaVG16Tmc5NVMrVXplUWMwUHpNc05UCjc5dXEvblJPYWNkcmpHQ1Qzc1RIRE4vaE1xN01renRSZUpWbmkrNDlWdjRNMEdrUEd3L3pKU1pyTTIzM2JrZjYKYzBQbGZnNmxackVwZkRLRVkxV0p4QTNCazFRd0dST3MwMzAzcCt0ZE9tdzFYTnRCMXhMYXFVa0wzOWlBaWdtVApZbzYxWnM4bGlNMkV1TEUvcERrUDJRS2U2eEpNbFh6emF3V3BYaGFEekxobjR1Z1RuY3hiZ3ROTXMrMWIvOTdsCmM2d2pPeTBBdnpWVmRBbEoyRWxZR24rU051WlJrZzd6Sm4wY1RSZTh5ZXhESnRDL1FWOUFxVVJFOUpublY0ZWUKVUI5WFZLZysvWFJqTDdGUVpRbm1XRUl1UXhwTXRQQWxSMW42QkI2VDFDWkdTbENCc3Q2K2VMZjhaeFhoeVZlRQpIZzlqMXVsaXV0WmZWUzdxWE1Zb0NBUWxPYmdPSzZueVRKY2NCejhOVXZYdDd5K0NEd0lEQVFBQm8wSXdRREFkCkJnTlZIUTRFRmdRVVUzbS9XcW9yU3M5VWdPSFltOENkOHJJRFpzc3dEZ1lEVlIwUEFRSC9CQVFEQWdFR01BOEcKQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVNQlFBRGdnSUJBRnpVZkEzUDl3RjlRWmxsREhQRgpVcC9MK00rWkJuOGIya01WbjU0Q1ZWZVdGUEZTUENlSGxDanRIem9CTjZKMi9GTlF3SVNieG10T3Vvd2hUNktPClZXS1I4MmtWMkx5STQ4U3FDLzN2cU9sTFZTb0dJRzFWZUNrWjdsOHdYRXNrRVZYL0pKcHVYaW9yN2d0Tm4zLzMKQVRpVUZKVkRCd243WUtudUhLc1NqS0NhWHFlWWFsbHRpejhJKzhqUlJhOFlGV1NRRWc5ektDN0Y0aVJPL0Zqcwo4UFJGL2lLejZ5K08wdGxGWVFYQmwyK29kbktQaTR3MnI3OE5CYzV4amVhbWJ4OXNwbkZpeGRqUWczSU04V2NSCmlReWNFMHh5Tk4rODFYSGZxbkhkNGJsc2pEd1NYV1hhdlZjU3RrTnIvK1hlVFdZUlVjK1pydXdYdHVoeGtZemUKU2Y3ZE5YR2lGU2VVSE05aDR5YTdiNk5uSlNGZDV0MGRDeTVvR3p1Q3IreURaNFhVbUZGMHNibVpnSW4vZjNnWgpYSGxLWUM2U1FLNU1OeW9zeWNkaXlBNWQ5elpieXVBbEpRRzAzUm9IbkhjQVA5RGMxZXc5MVBxN1A4eUYxbTkvCnFTM2Z1UUwzOVplYXRUWGF3MmV3aDBxcEtKNGpqdjljSjJ2aHNFL3pCKzRBTHRSWmg4dFNRWlhxOUVmWDdtUkIKVlh5TldRS1YzV0tkd3JudVdpaDBoS1didDVESERBZmY5WWsyZERMV0tNR3dzQXZnbkV6REhOYjg0Mm0xUjBhQgpMNktDcTlOalJIREVqZjh0TTdxdGozdTFjSWl1UGhuUFFDalkvTWlRdTEyWkl2VlM1bGpGSDRneFErNklIZGZHCmpqeERhaDJuR041OVBSYnhZdm5La0tqOQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCgo8L2NhPgogCjxjZXJ0PgotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJQ3hqQ0NBYTRDQVFBd0RRWUpLb1pJaHZjTkFRRUZCUUF3S1RFYU1CZ0dBMVVFQXhNUlZsQk9SMkYwWlVOcwphV1Z1ZEVObGNuUXhDekFKQmdOVkJBWVRBa3BRTUI0WERURXpNREl4TVRBek5EazBPVm9YRFRNM01ERXhPVEF6Ck1UUXdOMW93S1RFYU1CZ0dBMVVFQXhNUlZsQk9SMkYwWlVOc2FXVnVkRU5sY25ReEN6QUpCZ05WQkFZVEFrcFEKTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE1aDJsZ1FRWVVqd29LWUpielZaQQo1VmNJR2Q1b3RQYy9xWlJNdDBLSXRDRkEwczlSd1JlTlZhOWZEUkZMUkJoY0lUT2x2M0ZCY1czRThoMVVzN1JECjRXOEdtSmU4emFwSm5Mc0QzOU9TTVJDelpKbmN6VzRPQ0gxUFpSWldLcUR0amxOY2E5QUY4YTY1alRtbER4Q1EKQ2pudExJV2s1T0xMVmtGdDkvdFNjYzFHRHRjaTU1b2ZoYU5BWU1QaUg3VjgrMWc2NnBHSFhBb1dLNkFRVkg2NwpYQ0tKbkdCNW5sUStIc01ZUFYvTzQ5TGQ5MVpOLzJ0SGtjYUxMeU50eXd4VlBSU3NSaDQ4MGpqdTBmY0NzdjZoCnAvMHlYblRCLy9tV3V0QkdwZFVsSWJ3aUlUYkFtcnNiWW5qaWdSdm5QcVgxUk5KVWJpOUZwNkMyYy9ISUZKR0QKeXdJREFRQUJNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0SUJBUUNoTzVoZ2N3LzRvV2ZvRUZMdTlrQmExQi8va3hIOApoUWtDaFZObjhCUkM3WTBVUlFpdFBsM0RLRWVkOVVSQkRkZzJLT0F6NzdiYjZFTlBpbGlEK2EzOFVKSElSTXFlClVCSGhsbE9ISXp2RGhIRmJhb3ZBTEJRY2VlQnpka1F4c0tRRVNLbVFtUjgzMjk1MFVDb3ZveVJCNjFVeUFWN2gKK21aaFlQR1JLWEtTSkk2czBFZ2cvQ3JpK0N3azRiakpmcmI1aFZzZTExeWg0RDlNSGh3U2ZDT0grMHo0aFBVVApGa3U3ZEdhdlVSTzVTVnhNbi9zTDZFbjVEK29TZVhrYWRIcERzK0FpcnltMllIaDE1aDAralBTT29SNnlpVnAvCjZ6WmVaa3JONDNrdVM3M0twS0RGamZGUGg4dDRyMWdPSWp0dGtOY1FxQmNjdXNucGxRN0hKcHNrCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KCjwvY2VydD4KCjxrZXk+Ci0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KTUlJRXBBSUJBQUtDQVFFQTVoMmxnUVFZVWp3b0tZSmJ6VlpBNVZjSUdkNW90UGMvcVpSTXQwS0l0Q0ZBMHM5Ugp3UmVOVmE5ZkRSRkxSQmhjSVRPbHYzRkJjVzNFOGgxVXM3UkQ0VzhHbUplOHphcEpuTHNEMzlPU01SQ3paSm5jCnpXNE9DSDFQWlJaV0txRHRqbE5jYTlBRjhhNjVqVG1sRHhDUUNqbnRMSVdrNU9MTFZrRnQ5L3RTY2MxR0R0Y2kKNTVvZmhhTkFZTVBpSDdWOCsxZzY2cEdIWEFvV0s2QVFWSDY3WENLSm5HQjVubFErSHNNWVBWL080OUxkOTFaTgovMnRIa2NhTEx5TnR5d3hWUFJTc1JoNDgwamp1MGZjQ3N2NmhwLzB5WG5UQi8vbVd1dEJHcGRVbElid2lJVGJBCm1yc2JZbmppZ1J2blBxWDFSTkpVYmk5RnA2QzJjL0hJRkpHRHl3SURBUUFCQW9JQkFFUlY3WDVBdnhBOHVSaUsKazhTSXBzRDBkWDFwSk9NSXdha1VWeXZjNEVmTjBEaEtSTmI0cllvU2lFR1RMeXpMcHlCYy9BMjhEbGttNWVPWQpmanpYZllrR3RZaS9GdHhrZzNPOXZjck1RNCs2aSt1R0hhSUwyckwrczRNcmZPOHYxeHY2K1dreTMzRUVHQ291ClFpd1ZHUkZRWG5Sb1E2Mk5CQ0ZiVU5MaG1Yd2RqMWFrWnpMVTRwNVI0ekEzUWhkeHdFSWF0Vkx0MCs3b3dMUTMKbFA4c2ZYaHBwUE9YalRxTUQ0UWtZd3pQQWE4L3pGN2FjbjRrcnlyVVA3UTZQQWZkMHpFVnFOeTlaQ1o5ZmZobwp6WGVkRmo0ODZJRm9jNWduVHAyTjZqc25WajRMQ0dJaGxWSGxZR296S0tGcUpjUVZHc0hDcXExb3oyempXNkxTCm9SWUlIZ0VDZ1lFQTh6WnJrQ3dOWVNYSnVPREozbS9oT0xWeGN4Z0p1d1hvaUVyV2QwRTQydlBhbmpqVk1obnQKS1k1bDhxR01KNkZoSzlMWXgycUNyZi9FMFh0VUFaMndWcTNPUlR5R25zTVdyZTl0TFlzNTVYK1pOMTBUYzc1ego0aGFjYlUwaHFLTjFIaURtc01SWTMvMk5hWkhveTdNS253SkpCYUc0OGw5Q0NUbFZ3TUhvY0lFQ2dZRUE4amJ5CmRHanhUSCs2WEhXTml6YjVTUmJaeEFueUVlSmVSd1RNaDBnR3p3R1BwSC9zWllHenl1MFN5U1hXQ25aaDNSZ3EKNXVMbE54dHJYcmxqWmx5aTJuUWRRZ3NxMllyV1VzMCt6Z1UrMjJ1UXNacFNBZnRtaFZydHZldDZNalZqYkJ5WQpEQURjaUVWVWRKWUlYaytxbkZVSnllcm9MSWtUajdXWUtaNlJqa3NDZ1lCb0NGSXdSRGVnNDJvSzg5UkZtbk9yCkx5bU5BcTQrMm9NaHNXbFZiNGVqV0lXZUFrOW5jK0dYVWZyWHN6UmhTMDFtVW5VNXI1eWdVdlJjYXJWL1QzVTcKVG5NWitJN1k0RGdXUklEZDUxem5oeElCdFlWNWovQy90ODVIanFPa0grOGI2UlRrYmNoYVgzbWF1N2ZwVWZkcwpGcTBuaElxNDJmaEVPOHNyZllZd2dRS0JnUUN5aGkxTi84dGFSd3BrKzMvSURFelF3amJmZHpVa1dXU0RrOVhzCkgvcGt1UkhXZlRNUDNmbFdxRVlnVy9MVzQwcGVXMkhEcTVpbWRWOCtBZ1p4ZS9YTWJhamk5TGd3ZjFSWTAwNW4KS3hhWlF6N3lxSHVwV2xMR0Y2OERQSHhrWlZWU2FnRG5WL3N6dFdYNlNGc0NxRlZueElYaWZYR0M0Y1c1Tm05Zwp2YThxNFFLQmdRQ0VoTFZlVWZkd0t2a1o5NGcvR0Z6NzMxWjJocmRWaGdNWmFVL3U2dDBWOTUrWWV6UE5DUVpCCndtRTlNbWxicTFlbURlUk9pdmpDZm9HaFIza1pYVzFwVEtsTGg2Wk1VUVVPcHB0ZFh2YThYeGZvcVF3YTNlbkEKTTdtdUJiRjBYTjdWTzgwaUpQditQbUlaZEVJQWtwd0tmaTIwMVlCK0JhZkNJdUd4SUY1MFZnPT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0KCjwva2V5PgoK",
                //   "username":"",
                //   "password":""
                // }).then((value) {
                //   print(value.id);
                // });
              },
              child: const Icon(
                Icons.settings_sharp,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(children: [
        //
        Card(
          child: SizedBox(
            height: 160,
            child: Stack(
              children: [
                //
                Positioned(
                  left: 20,
                  top: 5,
                  bottom: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        padding: const EdgeInsets.all(5.0),
                        height: 80,
                        child: Image.asset(
                          (stage.toString() == VPNStage.connected.toString())
                              ? "assets/icon/vpn.png"
                              : "assets/icon/vpn_off.png",
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.north_sharp,
                                size: 15,
                              ),
                              Text(
                                  "Up     : ${status!.byteOut.toString()} bytes"),
                            ],
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.south_sharp,
                                size: 15,
                              ),
                              Text("Down: ${status!.byteIn.toString()} bytes"),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 10,
                  bottom: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset("assets/flag/US.png", height: 35),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                                (stage.toString() ==
                                            VPNStage.disconnected.toString() ||
                                        stage.toString() == "null")
                                    ? "Disconnected"
                                    : stage!.name.toString(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            // color: (stage?.toString() == VPNStage.disconnected.toString())
                            //     ? Colors.red
                            //     : Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_granted == null) {
                              engine.requestPermissionAndroid().then((value) {
                                setState(() {
                                  _granted = value;
                                });
                              });
                            }
                            if (stage.toString() ==
                                VPNStage.connected.toString()) {
                              engine.disconnect();
                            } else {
                              initPlatformState();
                            }
                          },
                          child: Container(
                            height: 38,
                            width: 140,
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: (stage.toString() ==
                                          VPNStage.disconnected.toString() ||
                                      stage.toString() == "null")
                                  ? Colors.grey.shade400
                                  : Colors.green.shade400,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (stage.toString() ==
                                              VPNStage.disconnected
                                                  .toString() ||
                                          stage.toString() == "null")
                                      ? "Connect Now"
                                      : stage!.name.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: (stage.toString() ==
                                              VPNStage.disconnected
                                                  .toString() ||
                                          stage.toString() == "null")
                                      ? Colors.grey.shade800
                                      : Colors.green.shade800,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.toNamed(VPNRoute.serverlist);
          },
          child: Card(
            child: SizedBox(
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.location_on),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Pick Your Server",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        // if (Platform.isAndroid)
        //   TextButton(
        //     child: Text(_granted ? "Granted" : "Request Permission"),
        //     onPressed: () {
        //       engine.requestPermissionAndroid().then((value) {
        //         setState(() {
        //           _granted = value;
        //         });
        //       });
        //     },
        //   ),
      ]),
    );
  }
}

const String defaultVpnUsername = "";
const String defaultVpnPassword = "";

String config = """ 
dev tun 
proto tcp 
remote public-vpn-173.opengw.net 443 
;http-proxy-retry
;http-proxy [proxy server] [proxy port] 
cipher AES-128-CBC
auth SHA1 
resolv-retry infinite
nobind
persist-key
persist-tun
client
verb 3 
<ca>
-----BEGIN CERTIFICATE-----
MIIF3jCCA8agAwIBAgIQAf1tMPyjylGoG7xkDjUDLTANBgkqhkiG9w0BAQwFADCB
iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0pl
cnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNV
BAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTAw
MjAxMDAwMDAwWhcNMzgwMTE4MjM1OTU5WjCBiDELMAkGA1UEBhMCVVMxEzARBgNV
BAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2Vy
dGlmaWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
AoICAQCAEmUXNg7D2wiz0KxXDXbtzSfTTK1Qg2HiqiBNCS1kCdzOiZ/MPans9s/B
3PHTsdZ7NygRK0faOca8Ohm0X6a9fZ2jY0K2dvKpOyuR+OJv0OwWIJAJPuLodMkY
tJHUYmTbf6MG8YgYapAiPLz+E/CHFHv25B+O1ORRxhFnRghRy4YUVD+8M/5+bJz/
Fp0YvVGONaanZshyZ9shZrHUm3gDwFA66Mzw3LyeTP6vBZY1H1dat//O+T23LLb2
VN3I5xI6Ta5MirdcmrS3ID3KfyI0rn47aGYBROcBTkZTmzNg95S+UzeQc0PzMsNT
79uq/nROacdrjGCT3sTHDN/hMq7MkztReJVni+49Vv4M0GkPGw/zJSZrM233bkf6
c0Plfg6lZrEpfDKEY1WJxA3Bk1QwGROs0303p+tdOmw1XNtB1xLaqUkL39iAigmT
Yo61Zs8liM2EuLE/pDkP2QKe6xJMlXzzawWpXhaDzLhn4ugTncxbgtNMs+1b/97l
c6wjOy0AvzVVdAlJ2ElYGn+SNuZRkg7zJn0cTRe8yexDJtC/QV9AqURE9JnnV4ee
UB9XVKg+/XRjL7FQZQnmWEIuQxpMtPAlR1n6BB6T1CZGSlCBst6+eLf8ZxXhyVeE
Hg9j1uliutZfVS7qXMYoCAQlObgOK6nyTJccBz8NUvXt7y+CDwIDAQABo0IwQDAd
BgNVHQ4EFgQUU3m/WqorSs9UgOHYm8Cd8rIDZsswDgYDVR0PAQH/BAQDAgEGMA8G
A1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEMBQADggIBAFzUfA3P9wF9QZllDHPF
Up/L+M+ZBn8b2kMVn54CVVeWFPFSPCeHlCjtHzoBN6J2/FNQwISbxmtOuowhT6KO
VWKR82kV2LyI48SqC/3vqOlLVSoGIG1VeCkZ7l8wXEskEVX/JJpuXior7gtNn3/3
ATiUFJVDBwn7YKnuHKsSjKCaXqeYalltiz8I+8jRRa8YFWSQEg9zKC7F4iRO/Fjs
8PRF/iKz6y+O0tlFYQXBl2+odnKPi4w2r78NBc5xjeambx9spnFixdjQg3IM8WcR
iQycE0xyNN+81XHfqnHd4blsjDwSXWXavVcStkNr/+XeTWYRUc+ZruwXtuhxkYze
Sf7dNXGiFSeUHM9h4ya7b6NnJSFd5t0dCy5oGzuCr+yDZ4XUmFF0sbmZgIn/f3gZ
XHlKYC6SQK5MNyosycdiyA5d9zZbyuAlJQG03RoHnHcAP9Dc1ew91Pq7P8yF1m9/
qS3fuQL39ZeatTXaw2ewh0qpKJ4jjv9cJ2vhsE/zB+4ALtRZh8tSQZXq9EfX7mRB
VXyNWQKV3WKdwrnuWih0hKWbt5DHDAff9Yk2dDLWKMGwsAvgnEzDHNb842m1R0aB
L6KCq9NjRHDEjf8tM7qtj3u1cIiuPhnPQCjY/MiQu12ZIvVS5ljFH4gxQ+6IHdfG
jjxDah2nGN59PRbxYvnKkKj9
-----END CERTIFICATE-----

</ca>
 
<cert>
-----BEGIN CERTIFICATE-----
MIICxjCCAa4CAQAwDQYJKoZIhvcNAQEFBQAwKTEaMBgGA1UEAxMRVlBOR2F0ZUNs
aWVudENlcnQxCzAJBgNVBAYTAkpQMB4XDTEzMDIxMTAzNDk0OVoXDTM3MDExOTAz
MTQwN1owKTEaMBgGA1UEAxMRVlBOR2F0ZUNsaWVudENlcnQxCzAJBgNVBAYTAkpQ
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5h2lgQQYUjwoKYJbzVZA
5VcIGd5otPc/qZRMt0KItCFA0s9RwReNVa9fDRFLRBhcITOlv3FBcW3E8h1Us7RD
4W8GmJe8zapJnLsD39OSMRCzZJnczW4OCH1PZRZWKqDtjlNca9AF8a65jTmlDxCQ
CjntLIWk5OLLVkFt9/tScc1GDtci55ofhaNAYMPiH7V8+1g66pGHXAoWK6AQVH67
XCKJnGB5nlQ+HsMYPV/O49Ld91ZN/2tHkcaLLyNtywxVPRSsRh480jju0fcCsv6h
p/0yXnTB//mWutBGpdUlIbwiITbAmrsbYnjigRvnPqX1RNJUbi9Fp6C2c/HIFJGD
ywIDAQABMA0GCSqGSIb3DQEBBQUAA4IBAQChO5hgcw/4oWfoEFLu9kBa1B//kxH8
hQkChVNn8BRC7Y0URQitPl3DKEed9URBDdg2KOAz77bb6ENPiliD+a38UJHIRMqe
UBHhllOHIzvDhHFbaovALBQceeBzdkQxsKQESKmQmR832950UCovoyRB61UyAV7h
+mZhYPGRKXKSJI6s0Egg/Cri+Cwk4bjJfrb5hVse11yh4D9MHhwSfCOH+0z4hPUT
Fku7dGavURO5SVxMn/sL6En5D+oSeXkadHpDs+Airym2YHh15h0+jPSOoR6yiVp/
6zZeZkrN43kuS73KpKDFjfFPh8t4r1gOIjttkNcQqBccusnplQ7HJpsk
-----END CERTIFICATE-----

</cert>

<key>
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA5h2lgQQYUjwoKYJbzVZA5VcIGd5otPc/qZRMt0KItCFA0s9R
wReNVa9fDRFLRBhcITOlv3FBcW3E8h1Us7RD4W8GmJe8zapJnLsD39OSMRCzZJnc
zW4OCH1PZRZWKqDtjlNca9AF8a65jTmlDxCQCjntLIWk5OLLVkFt9/tScc1GDtci
55ofhaNAYMPiH7V8+1g66pGHXAoWK6AQVH67XCKJnGB5nlQ+HsMYPV/O49Ld91ZN
/2tHkcaLLyNtywxVPRSsRh480jju0fcCsv6hp/0yXnTB//mWutBGpdUlIbwiITbA
mrsbYnjigRvnPqX1RNJUbi9Fp6C2c/HIFJGDywIDAQABAoIBAERV7X5AvxA8uRiK
k8SIpsD0dX1pJOMIwakUVyvc4EfN0DhKRNb4rYoSiEGTLyzLpyBc/A28Dlkm5eOY
fjzXfYkGtYi/Ftxkg3O9vcrMQ4+6i+uGHaIL2rL+s4MrfO8v1xv6+Wky33EEGCou
QiwVGRFQXnRoQ62NBCFbUNLhmXwdj1akZzLU4p5R4zA3QhdxwEIatVLt0+7owLQ3
lP8sfXhppPOXjTqMD4QkYwzPAa8/zF7acn4kryrUP7Q6PAfd0zEVqNy9ZCZ9ffho
zXedFj486IFoc5gnTp2N6jsnVj4LCGIhlVHlYGozKKFqJcQVGsHCqq1oz2zjW6LS
oRYIHgECgYEA8zZrkCwNYSXJuODJ3m/hOLVxcxgJuwXoiErWd0E42vPanjjVMhnt
KY5l8qGMJ6FhK9LYx2qCrf/E0XtUAZ2wVq3ORTyGnsMWre9tLYs55X+ZN10Tc75z
4hacbU0hqKN1HiDmsMRY3/2NaZHoy7MKnwJJBaG48l9CCTlVwMHocIECgYEA8jby
dGjxTH+6XHWNizb5SRbZxAnyEeJeRwTMh0gGzwGPpH/sZYGzyu0SySXWCnZh3Rgq
5uLlNxtrXrljZlyi2nQdQgsq2YrWUs0+zgU+22uQsZpSAftmhVrtvet6MjVjbByY
DADciEVUdJYIXk+qnFUJyeroLIkTj7WYKZ6RjksCgYBoCFIwRDeg42oK89RFmnOr
LymNAq4+2oMhsWlVb4ejWIWeAk9nc+GXUfrXszRhS01mUnU5r5ygUvRcarV/T3U7
TnMZ+I7Y4DgWRIDd51znhxIBtYV5j/C/t85HjqOkH+8b6RTkbchaX3mau7fpUfds
Fq0nhIq42fhEO8srfYYwgQKBgQCyhi1N/8taRwpk+3/IDEzQwjbfdzUkWWSDk9Xs
H/pkuRHWfTMP3flWqEYgW/LW40peW2HDq5imdV8+AgZxe/XMbaji9Lgwf1RY005n
KxaZQz7yqHupWlLGF68DPHxkZVVSagDnV/sztWX6SFsCqFVnxIXifXGC4cW5Nm9g
va8q4QKBgQCEhLVeUfdwKvkZ94g/GFz731Z2hrdVhgMZaU/u6t0V95+YezPNCQZB
wmE9Mmlbq1emDeROivjCfoGhR3kZXW1pTKlLh6ZMUQUOpptdXva8XxfoqQwa3enA
M7muBbF0XN7VO80iJPv+PmIZdEIAkpwKfi201YB+BafCIuGxIF50Vg==
-----END RSA PRIVATE KEY-----

</key>


""";
