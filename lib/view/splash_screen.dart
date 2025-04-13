import 'dart:async';

import 'package:vanlink_assignment/view/google_map.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    Timer(Duration(seconds: 5), () {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) {
        return DriverHomeScreen();
      }));
    });

    return Scaffold(
      body: Column(
        children: [
          Spacer(),
          Center(
            child: CircleAvatar(
              radius: 100,
              child: Image.asset("assets/vanlink_logo_splash_screen.jpg"),
            ),
          ),
          Spacer(),
          Text(
            "Vanlink",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 60,
          )
        ],
      ),
    );
  }
}
