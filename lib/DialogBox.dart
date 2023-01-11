import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertBox2 extends StatefulWidget {
  const AlertBox2({Key? key}) : super(key: key);

  @override
  State<AlertBox2> createState() => _AlertBox2State();
}

class _AlertBox2State extends State<AlertBox2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Padding(
          padding:
              const EdgeInsets.only(top: 40, bottom: 40, left: 20, right: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black,
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  FluentIcons.arrow_exit_20_regular,
                  size: 200,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oh no! You\'re leaving',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w500),
                ),
                const Text(
                  'Are you sure?',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 50),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/explore');
                  },
                  child: const Text(
                    'Nah, keep me in',
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(20.0),
                      fixedSize: const Size(300, 70),
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color.fromRGBO(250, 247, 237, 100)),
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(100)))),
                ),
                const SizedBox(height: 25),
                OutlinedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text(
                    'Yea, log me out',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(20.0),
                      fixedSize: const Size(300, 70),
                      backgroundColor: Colors.black,
                      side: const BorderSide(
                          color: Color.fromRGBO(250, 247, 237, 100)),
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(100)))),
                ),

                // AlertDialog(
                //   backgroundColor: Colors.black,
                //   title: Text('Do you want to exit this application?'),
                //   content: Text('We hate to see you leave...'),
                //   actions: <Widget>[
                //     OutlinedButton(
                //       onPressed: () {
                //         Navigator.of(context).pushReplacementNamed("/explore");
                //       },
                //       child: const Text(
                //         'No',
                //         style: TextStyle(
                //             color: Colors.white,
                //             fontFamily: 'Poppins',
                //             fontSize: 15,
                //             fontWeight: FontWeight.w500),
                //       ),
                //     ),
                //     OutlinedButton(
                //       onPressed: () {
                //         Navigator.of(context).pushReplacementNamed("/login");
                //       },
                //       child: const Text(
                //         'Yes',
                //         style: TextStyle(
                //             color: Colors.white,
                //             fontFamily: 'Poppins',
                //             fontSize: 15,
                //             fontWeight: FontWeight.w500),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
