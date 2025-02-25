import 'package:flutter/material.dart';

class CustomFeatureButton extends StatelessWidget {
  // final String imageLocation;
  const CustomFeatureButton({
    // required this.imageLocation,
    super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        height: MediaQuery.of(context).size.height*0.2,
        width: MediaQuery.of(context).size.width*0.22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.grey
          
        ),
        // child: Image.asset(imageLocation),
      ),
    );
  }
}