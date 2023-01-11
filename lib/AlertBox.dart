import 'package:flutter/material.dart';

void showAlert(BuildContext cx, String st) {
  ScaffoldMessenger.of(cx).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.white,
    duration: const Duration(seconds: 3),
    dismissDirection: DismissDirection.horizontal,
    content: Container(
      // color: Colors.white,
      height: 47,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(24, 23, 31, 0),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: Center(
        child: Text(
          st,
          style: const TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500),
        ),
      ),
    ),
  ));
}
