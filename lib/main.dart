import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vpn/vpnApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const VPNApp());
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