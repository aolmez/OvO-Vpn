// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/model/vpn.dart';
import 'package:vpn/network/response/server.dart';

class VpnController extends GetxController {
  //
  Server? server;
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
        server = Server.fromJson(vpnData);
        haveVpn = true;
      }
    } catch (e) {
      print(" error: $e");
    }
    print("have vpn $haveVpn");

    update();
  }
}
