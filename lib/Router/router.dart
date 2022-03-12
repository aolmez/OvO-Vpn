import 'package:get/get.dart';
import 'package:vpn/ui/home_ui.dart';
import 'package:vpn/ui/server_list_ui.dart';
import 'package:vpn/ui/splash_ui.dart';
import 'route.dart';

// import 'route.dart';

class VPNRouters {
  static final routes = [
    GetPage(
      name: VPNRoute.root,
      page: () => const SplashUI(),
    ),
    GetPage(
      name: VPNRoute.home,
      page: () => HomeUI(),
    ),
    GetPage(
      name: VPNRoute.serverlist,
      page: () => const ServerListUI(),
    ),
    // GetPage(
    //   name: '/addNote',
    //   page: () => const AddNoteScreen(),
    // ),
  ];
}
