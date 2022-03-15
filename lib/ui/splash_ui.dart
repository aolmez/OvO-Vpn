// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn/Router/route.dart';
import 'package:vpn/main.dart';

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
    checkPlayServices();
    super.initState();
  }

  void checkPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.notification,
    ].request();
    noti();
  }

  Future<void> checkPlayServices() async {
    WidgetsFlutterBinding.ensureInitialized();
    GooglePlayServicesAvailability playStoreAvailability;
    try {
      playStoreAvailability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      if (playStoreAvailability == GooglePlayServicesAvailability.success) {
        print("Google Play Services is available.");
        checkPermission();
      } else {
        nextPage();
      }
    } on PlatformException {
      //
    }
  }

  void noti() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    nextPage();
  }

  void nextPage() {
    Timer(const Duration(seconds: 2), () {
      Get.offAllNamed(VPNRoute.home);
    });
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
