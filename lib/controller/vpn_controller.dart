import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/model/vpn.dart';

class VpnController extends GetxController {
  //
  Vpn? vpn;
  bool haveVpn = false;
  @override
  void onInit() {
    getVPN();
    super.onInit();
  }

  getVPN() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      var data = prefs.getString('vpnData');
      if (data != null) {
        Map<String, dynamic> vpnData = jsonDecode(prefs.getString('vpnData')!);
        vpn = Vpn.fromJson(vpnData);
        haveVpn = true;
      }
    } catch (e) {
      print(" error: $e");
    }
    print("have vpn $haveVpn");

    update();
  }
}
