import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info/package_info.dart';
import 'package:vpn/model/remote_update.dart';

class UpdateController extends GetxController {
  //
  RemoteUpdate? remoteUpdate;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String get appVersion => _appVersion;

  late String _appVersion;

  @override
  void onInit() {
    initRemoteConfig();
    super.onInit();
  }

  initRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      checkRemoteVersion();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  checkRemoteVersion() async {
    await _remoteConfig.fetchAndActivate();
    var version = _remoteConfig.getString("force_update_current_version");
    Map<String, dynamic> vpnData = jsonDecode(version);
    remoteUpdate = RemoteUpdate.fromJson(vpnData);
    update();
  }

  checkUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var currentVersionRaw = packageInfo.version;
    _appVersion = packageInfo.version;
    double enforceVersion =
        double.parse(remoteUpdate!.version!.trim().replaceAll(".", ""));
    double currentVersion =
        double.parse(currentVersionRaw.trim().replaceAll(".", ""));
    if (enforceVersion > currentVersion && remoteUpdate!.isForce == true) {
      Get.defaultDialog(
        title: remoteUpdate!.version!,
        middleText: remoteUpdate!.releaseNsote!,
        textConfirm: "Confirm",
        textCancel: "Cancel",
        onConfirm: () {
          //
        },
        onCancel: () {
          //
          Get.back();
        },
      );
    } else {
      //
    }
    update();
  }
}
