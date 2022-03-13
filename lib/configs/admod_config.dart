class AdmobConfig {
  //
  static const String appId = "ca-app-pub-7738637538316189~7812476024";

  static const bool isTest = true;
  static const String bannerIdAndroid = isTest
      ? "ca-app-pub-3940256099942544/6300978111"
      : "ca-app-pub-7738637538316189/2692049277";
  static const String interstitialVideoIdIAndroid = isTest
      ? "ca-app-pub-3940256099942544/5354046379"
      : "ca-app-pub-7738637538316189/9762538868";
  static const String videoAdIdIAndroid = isTest
      ? "ca-app-pub-3940256099942544/5224354917"
      : "ca-app-pub-7738637538316189/3771845583";
  static const String openAppAdIdIAndroid = isTest
      ? "ca-app-pub-3940256099942544/3419835294"
      : "ca-app-pub-7738637538316189/8491170865";

  static const String testDevice = 'B3EEABB8EE11C2BE770B684D95219ECB';
  static const int maxFailedLoadAttempts = 3;
}
