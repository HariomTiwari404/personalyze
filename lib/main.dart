import 'package:flutter/material.dart';
import 'package:personlayze/screens/HomePage.dart';

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
      '/home': (context) => const HomePage(),
      '/performance': (context) => const HomePage(),
      '/profile': (context) => const HomePage(),
    },
    );
  }
}
