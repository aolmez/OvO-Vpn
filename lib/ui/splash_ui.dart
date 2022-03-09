import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vpn/Router/route.dart';

class SplashUI extends StatefulWidget {
  const SplashUI({Key? key}) : super(key: key);

  @override
  State<SplashUI> createState() => _SplashUIState();
}

class _SplashUIState extends State<SplashUI> {
  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    Timer(const Duration(seconds: 2), () {
      // Get.toNamed(VPNRoute.home);
      Get.offAllNamed(VPNRoute.home);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              "assets/icon/logo.png",
              width: 200,
            ),
          )
        ],
      ),
    );
  }
}
