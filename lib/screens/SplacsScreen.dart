import 'package:flutter/material.dart';
import 'dart:async';

import 'package:personlayze/screens/HomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  String fullText = "Personalize";
  List<AnimationController> controllers = [];
  List<Animation<double>> animations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    for (int i = 0; i < fullText.length; i++) {
      controllers.add(AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      ));

      animations.add(Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: controllers[i],
        curve: Curves.easeIn,
      )));
    }

    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 200)); // Delay between letters
      controllers[i].forward();
    }

    // Navigate to next screen after animation
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(fullText.length, (index) {
            return FadeTransition(
              opacity: animations[index],
              child: Text(
                fullText[index],
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}


