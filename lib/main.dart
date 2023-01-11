import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:perle/NewUser.dart';
import 'package:perle/explore.dart';
import 'package:perle/liked.dart';
import 'login.dart';
import 'search.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/login': (_) => const LoginPage(), // Login Page
        '/explore': (_) => const ExplorePage(),
        '/search': (_) => const SearchPage(),
        '/liked': (_) => const Liked(),
        '/register': (_) => const NewUser(), // Home Page
        // '/screen1':(_) => new Screen1(), // Any View to be navigated from home
      },
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
