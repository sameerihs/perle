import 'package:flutter/material.dart';
import 'package:perle/explore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class Liked extends StatefulWidget {
  const Liked({Key? key}) : super(key: key);

  @override
  State<Liked> createState() => _LikedState();
}

class _LikedState extends State<Liked> {
  @override
  void initState() {
    // setState(() {});
    // setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
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
                  const Center(
                    child: Text(
                      'Your liked wallpapers',
                      style: TextStyle(
                          color: Colors.white,
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
                            itemCount: finalLiked.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Hero(
                                    tag: finalLiked[index],
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        finalLiked[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
