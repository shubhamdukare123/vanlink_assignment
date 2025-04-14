// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:vanlink_assignment/view/driver_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanlink_assignment/view/login_register/login_screen.dart';
import 'package:vanlink_assignment/controller/session_data.dart';
import 'package:vanlink_assignment/view/parents_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 5), () async {
      await SessionData.getSessionData();

      if ((SessionData.isLogin != null) && SessionData.isLogin!) {
        if (SessionData.role == "Parent") {
        
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
        
            return const ParentsHomeScreen();
          }));
        } else {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
          
            return const DriverHomeScreen();
          }));
        }
      } else {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) {
      
          return const LoginScreen();
        }));
      }
    });

    return Scaffold(
      body: Column(
        children: [
          const Spacer(),
          Center(
            child: CircleAvatar(
              radius: 100,
              child: Image.asset("assets/vanlink_logo.jpg"),
            ),
          ),
          const Spacer(),
          Text(
            "Vanlink",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 60,
          )
        ],
      ),
    );
  }
}
