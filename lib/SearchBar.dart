// import 'package:fluentui_system_icons/fluentui_system_icons.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:perle/search.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'main.dart';
//
// String pic_search =
//     'https://images.pexels.com/photos/6569306/pexels-photo-6569306.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2';
// List<String> photos_search = [];
// List<String> finalPhotos_search = [];
//
// class SearchBar extends StatefulWidget {
//   const SearchBar({Key? key}) : super(key: key);
//
//   @override
//   State<SearchBar> createState() => _SearchBarState();
// }
//
// class _SearchBarState extends State<SearchBar> {
//   String ran = 'search';
//   IconData main_icon = FluentIcons.search_16_regular;
//
//   @override
//   void initState() {
//     setState(() {
//       ran = 'search';
//     });
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // if (searchQueryController.text.isNotEmpty) {
//     //   ran = searchQueryController.text;
//     // }
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color.fromRGBO(250, 247, 237, 100)),
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       margin: const EdgeInsets.symmetric(horizontal: 24),
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Row(
//         children: <Widget>[
//           Expanded(
//               child: TextField(
//             onChanged: (ran) {},
//             cursorColor: const Color.fromRGBO(250, 247, 237, 100),
//             controller: searchQueryController,
//             decoration: const InputDecoration(
//               hintText: 'search',
//               hintStyle: TextStyle(color: Color.fromRGBO(250, 247, 237, 100)),
//               border: InputBorder.none,
//             ),
//           )),
//           InkWell(
//               onTap: () async {
//                 finalPhotos_search.clear();
//                 String main_query = searchQueryController.text.toString();
//
//                 if (main_query.isNotEmpty) {
//                   await getCuratedPhotos_search(main_query);
//                   searchQueryController.clear();
//                 }
//                 if (main_query.isEmpty) {
//                   finalPhotos_search.clear();
//                 } else {
//                   Navigator.of(context).pushNamed("/search");
//                   searchQueryController.clear();
//                 }
//               },
//               child: Icon(
//                 main_icon,
//                 color: const Color.fromRGBO(250, 247, 237, 100),
//               )),
//         ],
//       ),
//     );
//   }
// }
//
// Future getCuratedPhotos_search(String main_query) async {
//   http.Response response_search = await http.get(
//       Uri.parse(
//           "https://api.pexels.com/v1/search?query=$main_query&per_page=70&page=1"),
//       headers: {
//         HttpHeaders.authorizationHeader:
//             '563492ad6f91700001000001fd3fd596460d401a9dbb386b14bfec52'
//       });
//   var data_search = response_search.body;
//   int total_available = await jsonDecode(data_search)['total_results'];
//   if (total_available < 70) {
//     for (int i = 0; i < total_available - 2; i++) {
//       pic_search = jsonDecode(data_search)['photos'][i]['src']['portrait'];
//       photos_search.add(pic_search);
//     }
//   } else if (total_available > 70) {
//     for (int i = 0; i < 60; i++) {
//       pic_search = jsonDecode(data_search)['photos'][i]['src']['portrait'];
//       photos_search.add(pic_search);
//     }
//   }
//
//   print(total_available);
//
//   finalPhotos_search = photos_search;
// }

// const SizedBox(height: 30),
// OutlinedButton(
// onLongPress: () {
// ScaffoldMessenger.of(context).showSnackBar(SnackBar(
// behavior: SnackBarBehavior.floating,
// backgroundColor: Colors.black,
// duration: const Duration(seconds: 3),
// dismissDirection: DismissDirection.horizontal,
// content: Container(
// // color: Colors.white,
// height: 47,
// decoration: const BoxDecoration(
// // color: Color.fromRGBO(24, 23, 31, 0),
// borderRadius: BorderRadius.all(Radius.circular(25)),
// ),
// child: const Center(
// child: Text(
// 'Download',
// style: TextStyle(
// color: Colors.white,
// fontFamily: 'Poppins',
// fontSize: 15,
// fontWeight: FontWeight.w500),
// ),
// ),
// ),
// ));
// },
// onPressed: () {},
// child: const Text(
// 'Download',
// style: TextStyle(
// color: Colors.white,
// fontFamily: 'Poppins',
// fontSize: 15,
// fontWeight: FontWeight.w500),
// ),
// style: OutlinedButton.styleFrom(
// fixedSize: const Size(150, 50),
// backgroundColor: Colors.black,
// side: const BorderSide(
// color: Color.fromRGBO(250, 247, 237, 100)),
// shape: const RoundedRectangleBorder(
// borderRadius: BorderRadius.all(Radius.circular(100)))),
// ),
