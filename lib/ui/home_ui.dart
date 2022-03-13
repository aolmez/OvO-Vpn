import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:vpn/ui/fragment/about_frament.dart';
import 'package:vpn/ui/fragment/home_fragment.dart';

class HomeUI extends StatefulWidget {
 const HomeUI({Key? key}) : super(key: key);

  @override
  State<HomeUI> createState() => _HomeUIState();
}

class _HomeUIState extends State<HomeUI> {
  int bottomSelectedIndex = 0;

  List<BottomNavigationBarItem> buildBottomNavBarItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(LineIcons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(LineIcons.info), label: "About")
    ];
  }

  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  void pageChanged(int index) {
    setState(() {
      bottomSelectedIndex = index;
    });
  }

  Widget buildPageView() {
    return PageView(
      pageSnapping: false,
      physics: const NeverScrollableScrollPhysics(),
      controller: pageController,
      onPageChanged: (index) {
        pageChanged(index);
      },
      children: const <Widget> [
        HomeFragment(),
        AboutFragment(),
      ],
    );
  }

  void _selectedTab(int index) {
    setState(() {
      bottomSelectedIndex = index;
    });
  }

  void bottomTapped(int index) {
    setState(() {
      bottomSelectedIndex = index;
      pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildPageView(),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0.8,
        selectedItemColor: Colors.grey[900],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: bottomSelectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          bottomTapped(index);
          _selectedTab(index);
        },
        items: buildBottomNavBarItems(),
      ),
    );
  }
}
