// ignore_for_file: file_names

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vpn/theme/appbar_theme.dart';
import 'package:vpn/theme/card_theme.dart';

import 'Router/route.dart';
import 'Router/router.dart';

class VPNApp extends StatefulWidget {
  const VPNApp({Key? key}) : super(key: key);

  @override
  State<VPNApp> createState() => _VPNAppState();
}

class _VPNAppState extends State<VPNApp> {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FirebaseRemoteConfig controller = Get.put(FirebaseRemoteConfig.instance);
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  @override
  Widget build(BuildContext context) {
    FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(false);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // statusBarIconBrightness: Brightness.light,
      ),
    );
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      getPages: VPNRouters.routes,
      initialRoute: VPNRoute.root,
      theme: ThemeData(
        appBarTheme: appbarTheme,
        cardTheme: cardTheme,
      ),
      navigatorObservers: [
        observer,
      ],
    );
  }
}

// Admob
// app id : ca-app-pub-7738637538316189~7812476024
// banner id : ca-app-pub-7738637538316189/2692049277
// interstitial id : ca-app-pub-7738637538316189/9762538868
// video ad id : ca-app-pub-7738637538316189/3771845583
// open app id : ca-app-pub-7738637538316189/8491170865
