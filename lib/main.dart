// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vpn/vpnApp.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      MobileAds.instance.initialize();
      RequestConfiguration(testDeviceIds: ["64A17126E86385C49F5365F1FB0E3508"]);
       await Firebase.initializeApp();
      await checkPlayServices();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      runApp(
        const VPNApp(),
      );
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    },
  );
}

Future<void> checkPlayServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  GooglePlayServicesAvailability playStoreAvailability;
  try {
    playStoreAvailability = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();
    if (playStoreAvailability == GooglePlayServicesAvailability.success) {
      print("Google Play Services is available.");
      await _startFirebase();
    }
  } on PlatformException {
    playStoreAvailability = GooglePlayServicesAvailability.unknown;
  }
}

Future<void> _startFirebase() async {
  await Firebase.initializeApp();
  FirebaseMessaging.instance.requestPermission();
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
            channelGroupKey: 'ovo_vpn_group',
            channelKey: 'ovo_vpn_group',
            channelName: 'OvO VPN',
            channelDescription: 'Hey My Friend',
            defaultColor: const Color(0xFF2861FF),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupkey: 'ovo_vpn_group', channelGroupName: 'Vpn group')
      ],
      debug: true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  if (!AwesomeStringUtils.isNullOrEmpty(message.notification?.title,
          considerWhiteSpaceAsEmpty: true) ||
      !AwesomeStringUtils.isNullOrEmpty(message.notification?.body,
          considerWhiteSpaceAsEmpty: true)) {
    print('message also contained a notification: ${message.notification}');

    String? imageUrl;
    imageUrl ??= message.notification!.android?.imageUrl;
    imageUrl ??= message.notification!.apple?.imageUrl;

    Map<String, dynamic> notificationAdapter = {
      NOTIFICATION_CHANNEL_KEY: 'ovo_vpn_group',
      NOTIFICATION_ID: message.data[NOTIFICATION_CONTENT]?[NOTIFICATION_ID] ??
          message.messageId ??
          Random().nextInt(2147483647),
      NOTIFICATION_TITLE: message.data[NOTIFICATION_CONTENT]
              ?[NOTIFICATION_TITLE] ??
          message.notification?.title,
      NOTIFICATION_BODY: message.data[NOTIFICATION_CONTENT]
              ?[NOTIFICATION_BODY] ??
          message.notification?.body,
      NOTIFICATION_LAYOUT:
          AwesomeStringUtils.isNullOrEmpty(imageUrl) ? 'Default' : 'BigPicture',
      NOTIFICATION_BIG_PICTURE: imageUrl
    };

    AwesomeNotifications().createNotificationFromJsonData(notificationAdapter);
  } else {
    AwesomeNotifications().createNotificationFromJsonData(message.data);
  }
}

// fvm flutter run | grep -v "Error retrieving thread information"
// Fvm build runner gen
// flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
// fvm flutter pub get && fvm flutter pub run build_runner build --delete-conflicting-outputs
// fvm flutter pub run flutter_launcher_icons:main
// pod deintegrate --verbose
// arch -x86_64 pod install
// pod install --verbose
// 09791321680
// sudo arch -x86_64 gem install ffi