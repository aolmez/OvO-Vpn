import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:vpn/vpnApp.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(const VPNApp());
  }, (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
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