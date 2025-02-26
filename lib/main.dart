import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:personlayze/screens/HomePage.dart';
import 'package:personlayze/screens/SplacsScreen.dart';

void main() {
  const apiKey = 'AIzaSyAv1SPDJs6-MnFOZjScR_x5j4KECvwsDAE';
  Gemini.init(apiKey: apiKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => SplashScreen(),
        '/performance': (context) => HomePage(),
        '/profile': (context) => HomePage(),
      },
    );
  }
}
