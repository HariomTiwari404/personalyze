import 'package:flutter/material.dart';
import 'package:personlayze/screens/HomePage.dart';
import 'package:personlayze/screens/SplacsScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
     initialRoute: '/home',
    routes: {
      '/home': (context) =>  SplashScreen(),
      '/performance': (context) =>  HomePage(),
      '/profile': (context) =>  HomePage(),
    },
    );
  }
}
