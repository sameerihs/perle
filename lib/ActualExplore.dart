import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/material.dart';
import 'package:perle/wallpaper.dart';
import 'AnimatedDialog.dart';
import 'explore.dart';

class ActualExplore extends StatefulWidget {
  const ActualExplore({Key? key}) : super(key: key);

  @override
  State<ActualExplore> createState() => _ActualExploreState();
}

class _ActualExploreState extends State<ActualExplore> {
  final FlareControls flareControls = FlareControls();
  bool isLiked = false;
  Color bgColor = const Color.fromRGBO(24, 23, 31, 100);
  Color brightColor = const Color.fromRGBO(250, 247, 237, 100);
  List<String> photos = [];
  late OverlayEntry _popUpDialog;

  getWall() {
    photos = finalPhotos.toSet().toList();
    // photos.reversed.toList();
    photos.shuffle();
  }

  @override
  initState() {
    getWall();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        primary: true,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.only(
              top: 25.0, bottom: 8.0, right: 8.0, left: 8.0),
          child: Column(
            children: <Widget>[
              Center(
                child: Text(
                  'Explore',
                  style: TextStyle(
                      color: brightColor,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: Container(
                    color: Colors.black,
                    child: ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: 30,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: photos[2 * index],
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: GestureDetector(
                                          onLongPress: () {
                                            _popUpDialog = _createPopupDialog(
                                                photos[2 * index],
                                                2 * index,
                                                context);

                                            Overlay.of(context)
                                                ?.insert(_popUpDialog);
                                          },
                                          onLongPressEnd: (details) =>
                                              _popUpDialog.remove(),
                                          onDoubleTap: () {
                                            likedPhotos.add(photos[2 * index]);
                                          },
                                          child: Image.network(
                                            photos[2 * index],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Hero(
                                      tag: photos[2 * index + 1],
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: GestureDetector(
                                          onLongPress: () {
                                            _popUpDialog = _createPopupDialog(
                                                photos[2 * index + 1],
                                                2 * index + 1,
                                                context);

                                            Overlay.of(context)
                                                ?.insert(_popUpDialog);
                                          },
                                          onDoubleTap: () {
                                            likedPhotos
                                                .add(photos[2 * index + 1]);
                                          },
                                          onLongPressEnd: (details) =>
                                              _popUpDialog.remove(),
                                          child: Image.network(
                                            photos[2 * index + 1],
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
                        }),
                  ))
            ],
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
