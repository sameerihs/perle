import 'package:flutter/material.dart';
import 'package:perle/AlertBox.dart';
import 'package:perle/SearchBar.dart';
import 'package:perle/wallpaper.dart';
import 'AnimatedDialog.dart';
import 'explore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'main.dart';

String pic_search =
    'https://images.pexels.com/photos/6569306/pexels-photo-6569306.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2';
List<String> photos_search = [];
List<String> finalPhotos_search = [];

int xx = 0;
List<String> photos_search_display = finalPhotos_search.toSet().toList();

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String ran = 'search';
  IconData main_icon = FluentIcons.search_16_regular;

  String q = '';

  late OverlayEntry _popUpDialogSearch;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final searchQueryController = TextEditingController();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.only(
              top: 25.0, bottom: 8.0, right: 8.0, left: 8.0),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              primary: true,
              scrollDirection: Axis.vertical,
              child: Column(children: <Widget>[
                const Center(
                  child: Text(
                    'Search for wallpapers',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromRGBO(250, 247, 237, 100)),
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: TextField(
                        onTap: () {
                          setState(() {
                            photos_search_display.clear();
                            finalPhotos_search.clear();
                            xx = 0;
                          });
                        },
                        onChanged: (ran) {},
                        cursorColor: const Color.fromRGBO(250, 247, 237, 100),
                        controller: searchQueryController,
                        decoration: const InputDecoration(
                          hintText: 'search',
                          hintStyle: TextStyle(
                              color: Color.fromRGBO(250, 247, 237, 100)),
                          border: InputBorder.none,
                        ),
                      )),
                      InkWell(
                          onTap: () async {
                            finalPhotos_search.clear();
                            photos_search_display.clear();
                            String main_query =
                                searchQueryController.text.toString();

                            if (main_query.isNotEmpty) {
                              await getCuratedPhotos_search(main_query);
                              setState(() {
                                late double x =
                                    finalPhotos_search.toSet().toList().length /
                                        2;
                                xx = x.toInt() - 1;
                                finalPhotos_search = photos_search;
                                photos_search_display =
                                    finalPhotos_search.toSet().toList();
                                print(
                                    'length of list: $finalPhotos_search.length');
                                print('COUNTT $xx');
                              });
                            } else if (main_query.isEmpty) {}
                          },
                          child: Icon(
                            main_icon,
                            color: const Color.fromRGBO(250, 247, 237, 100),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: Container(
                      color: Colors.black,
                      child: ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 15, right: 15, bottom: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: xx,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) {
                            if (photos_search_display.isNotEmpty) {
                              try {
                                return Padding(
                                  padding: const EdgeInsets.all(9.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Hero(
                                            tag: photos_search_display[
                                                2 * index],
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: GestureDetector(
                                                onLongPress: () {
                                                  _popUpDialogSearch =
                                                      _createPopupDialog(
                                                          photos_search_display[
                                                              2 * index],
                                                          2 * index,
                                                          context);

                                                  Overlay.of(context)?.insert(
                                                      _popUpDialogSearch);
                                                },
                                                onLongPressEnd: (details) =>
                                                    _popUpDialogSearch.remove(),
                                                onDoubleTap: () {
                                                  likedPhotos.add(
                                                      photos_search_display[
                                                          2 * index]);
                                                },
                                                child: Image.network(
                                                  photos_search_display[
                                                      2 * index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Hero(
                                            tag: photos_search_display[
                                                2 * index + 1],
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: GestureDetector(
                                                onLongPress: () {
                                                  _popUpDialogSearch =
                                                      _createPopupDialog(
                                                          photos_search_display[
                                                              2 * index + 1],
                                                          2 * index + 1,
                                                          context);

                                                  Overlay.of(context)?.insert(
                                                      _popUpDialogSearch);
                                                },
                                                onDoubleTap: () {
                                                  likedPhotos.add(
                                                      photos_search_display[
                                                          2 * index + 1]);
                                                },
                                                onLongPressEnd: (details) =>
                                                    _popUpDialogSearch.remove(),
                                                child: Image.network(
                                                  photos_search_display[
                                                      2 * index + 1],
                                                  // height: 210,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  finalPhotos_search.clear();
                                  photos_search_display.clear();
                                  xx = 0;
                                });
                                showAlert(context, 'Error');
                                return Container();
                              }
                            } else {
                              setState(() {
                                finalPhotos_search.clear();
                                photos_search_display.clear();
                                xx = 0;
                              });
                              // showAlert(context, 'Error');
                              return Container();
                            }
                          }),
                    ))
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

OverlayEntry _createPopupDialog(String url, int iindex, BuildContext context) {
  return OverlayEntry(
    builder: (context) => AnimatedDialog(
      child: _createPopupContent(url, iindex, context),
    ),
  );
}

Widget _createPopupContent(String url, int iindex, BuildContext context) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Hero(
              tag: 'pic$iindex',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(url, fit: BoxFit.fitWidth),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

Future getCuratedPhotos_search(String main_query) async {
  http.Response response_search = await http.get(
      Uri.parse(
          "https://api.pexels.com/v1/search?query=$main_query&per_page=70&page=1"),
      headers: {
        HttpHeaders.authorizationHeader:
            '563492ad6f91700001000001fd3fd596460d401a9dbb386b14bfec52'
      });
  var data_search = response_search.body;
  int total_available = await jsonDecode(data_search)['total_results'];
  if (total_available < 70) {
    for (int i = 0; i < total_available - 2; i++) {
      pic_search = jsonDecode(data_search)['photos'][i]['src']['portrait'];
      photos_search.add(pic_search);
    }
  } else if (total_available > 70) {
    for (int i = 0; i < 60; i++) {
      pic_search = jsonDecode(data_search)['photos'][i]['src']['portrait'];
      photos_search.add(pic_search);
    }
  }

  print('TOTALLLLLLL :$total_available');

  finalPhotos_search = photos_search;
}
