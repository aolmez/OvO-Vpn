import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpn/controller/update_controller.dart';

class AboutFragment extends StatefulWidget {
  AboutFragment({Key? key}) : super(key: key);

  @override
  State<AboutFragment> createState() => _AboutFragmentState();
}

class _AboutFragmentState extends State<AboutFragment> {
  String version = "";

  final String _fburl = 'https://www.facebook.com/ovovpngod/';
  final String _weurl = 'https://vpn.ovo-god.com';
  final String _termurl = 'https://vpn.ovo-god.com/termsconditions/';
  final String _priurl = 'https://vpn.ovo-god.com/privacypolicy/';
  @override
  void initState() {
    // TODO: implement initState
    checkVersion();
    super.initState();
  }

  void checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //
          Card(
            child: Column(
              children: [
                //
                GestureDetector(
                  onTap: () async {
                    if (!await launch(_fburl)) {
                      throw 'Could not launch $_fburl';
                    }
                  },
                  child: const ListTile(
                    leading: Icon(LineIcons.facebook),
                    title: Text('Facebook Page'),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!await launch(_weurl)) {
                      throw 'Could not launch $_weurl';
                    }
                  },
                  child: const ListTile(
                    leading: Icon(LineIcons.safari),
                    title: Text('Visit Website'),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!await launch(_termurl)) {
                      throw 'Could not launch $_termurl';
                    }
                  },
                  child: const ListTile(
                    leading: Icon(LineIcons.safari),
                    title: Text('Terms of Service'),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!await launch(_priurl)) {
                      throw 'Could not launch $_priurl';
                    }
                  },
                  child: const ListTile(
                    leading: Icon(LineIcons.safari),
                    title: Text('Privacy Policy'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "V $version",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      // body: GetBuilder<UpdateController>(
      //     init: UpdateController(),
      //     builder: (controller) {
      //       return Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: [
      //           //
      //           Card(
      //             child: Column(
      //               children: const [
      //                 //
      //                 ListTile(
      //                   leading: Icon(LineIcons.facebook),
      //                   title: Text('Facebook Page'),
      //                 ),
      //                 ListTile(
      //                   leading: Icon(LineIcons.safari),
      //                   title: Text('Visit Website'),
      //                 ),
      //                 ListTile(
      //                   leading: Icon(LineIcons.safari),
      //                   title: Text('Terms of Service'),
      //                 ),
      //                 ListTile(
      //                   leading: Icon(LineIcons.safari),
      //                   title: Text('Privacy Policy'),
      //                 ),
      //               ],
      //             ),
      //           ),
      //           Row(
      //             children: [
      //               Icon(LineIcons.infoCircle),
      //               Text(controller.appVersion),
      //             ],
      //           ),
      //         ],
      //       );
      //     }),
    );
  }
}
