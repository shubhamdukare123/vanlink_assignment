import 'package:flutter/material.dart';
import 'package:vanlink_assignment/view/google_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vanlink_assignment/view/login_register/login_screen.dart';
import 'package:vanlink_assignment/view/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCoLb8cJCETqmTLXEZPjZaCrq1mmckZQgQ",
          appId: "852738485641",
          messagingSenderId: "1:852738485641:android:afe8a3f2baeabc47ca0558",
          projectId: "vanlink-assignment"));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        // home: LoginScreen(),
        home: SplashScreen());
  }
}
