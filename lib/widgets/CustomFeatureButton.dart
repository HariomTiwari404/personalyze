import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomFeatureButton extends StatelessWidget {
  // final String data;
  final String imageLocation;
  final VoidCallback onTap; 

  const CustomFeatureButton({
    // required this.data,
    required this.imageLocation,
    required this.onTap, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: GestureDetector(
        onTap: onTap, 
        child: Container(
          height: MediaQuery.of(context).size.height * 0.2,
          width: MediaQuery.of(context).size.width * 0.22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            
          ),
          alignment: Alignment.center, 
          child: SvgPicture.asset(imageLocation, fit: BoxFit.contain,)
          ),
        ),
      );
    
  }
}
