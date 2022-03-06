import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
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
