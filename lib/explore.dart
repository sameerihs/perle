import 'package:perle/liked.dart';
import 'package:perle/login.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'ActualExplore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:perle/AlertBox.dart';
import 'DialogBox.dart';
import 'search.dart';

Set<String> likedPhotos = {};
List<String> finalLiked = likedPhotos.toList();
int makeIntA(int x) {
  return 2 * x;
}

int makeIntB(int y) {
  return 2 * y + 1;
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int selectedIndex = 0;
  int badge = 0;
  PageController controller = PageController();

  IconData home = FluentIcons.home_16_regular;
  IconData search = FluentIcons.search_16_regular;
  IconData like = FluentIcons.heart_48_regular;
  IconData exit = FluentIcons.arrow_exit_20_regular;
  IconData homeOn = FluentIcons.home_16_filled;
  IconData homeOff = FluentIcons.home_16_regular;
  IconData searchOn = FluentIcons.search_16_filled;
  IconData searchOff = FluentIcons.search_16_regular;
  IconData likeOn = FluentIcons.heart_48_filled;
  IconData likeOff = FluentIcons.heart_48_regular;
  IconData exitOn = FluentIcons.arrow_exit_20_filled;
  IconData exitOff = FluentIcons.arrow_exit_20_regular;

  final List<Widget> pages = [
    const ActualExplore(),
    const SearchPage(),
    const Liked(),
    const AlertBox2(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black,
          body: PageView.builder(
            onPageChanged: (page) {
              setState(() {
                selectedIndex = page;
                badge = badge + 1;
              });
            },
            controller: controller,
            itemBuilder: (context, position) {
              return pages[position];
            },
            itemCount: 4,
          ),
          bottomNavigationBar: Container(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              child: GNav(
                style: GnavStyle.google,
                textStyle: const TextStyle(
                    color: Color.fromRGBO(250, 247, 237, 100),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500),
                backgroundColor: Colors.black,
                color: const Color.fromRGBO(250, 247, 237, 100),
                activeColor: const Color.fromRGBO(250, 247, 237, 100),
                tabActiveBorder: const Border(
                  bottom: BorderSide(color: Color.fromRGBO(250, 247, 237, 100)),
                  left: BorderSide(color: Color.fromRGBO(250, 247, 237, 100)),
                  right: BorderSide(color: Color.fromRGBO(250, 247, 237, 100)),
                  top: BorderSide(color: Color.fromRGBO(250, 247, 237, 100)),
                ),
                gap: 15,
                tabBorderRadius: 500,
                // padding: const EdgeInsets.all(16),
                tabs: [
                  GButton(
                      padding: const EdgeInsets.all(15),
                      icon: home,
                      iconSize: 25,
                      // iconActiveColor: Colors.white,
                      text: 'Home',
                      onPressed: () {}),
                  GButton(
                    padding: const EdgeInsets.all(15),
                    icon: search,
                    iconSize: 25,
                    // iconActiveColor: Colors.white,
                    text: 'Search',
                    onPressed: () {},
                  ),
                  GButton(
                    padding: const EdgeInsets.all(15),
                    icon: like,
                    iconSize: 25,
                    // iconActiveColor: Colors.white,
                    text: 'Likes',
                    onPressed: () {
                      setState(() {
                        finalLiked = likedPhotos.toList();
                      });
                    },
                  ),
                  GButton(
                    padding: const EdgeInsets.all(15),
                    icon: exit,
                    iconSize: 25,
                    text: 'Log Out',
                  ),
                ],
                selectedIndex: selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    selectedIndex = index;
                    if (selectedIndex == 0) {
                      home = homeOn;
                      like = likeOff;
                      exit = exitOff;
                      search = searchOff;
                    } else if (selectedIndex == 1) {
                      home = homeOff;
                      like = likeOff;
                      exit = exitOff;
                      search = searchOn;
                      photos_search_display.clear();
                      finalPhotos_search.clear();
                      xx = 0;
                    } else if (selectedIndex == 2) {
                      home = homeOff;
                      like = likeOn;
                      exit = exitOff;
                      search = searchOff;
                    } else if (selectedIndex == 3) {
                      home = homeOff;
                      like = likeOff;
                      exit = exitOn;
                      search = searchOff;
                    }
                  });

                  controller.jumpToPage(index);
                },
              ),
            ),
          )),
    );
  }
}
