import 'package:flutter/material.dart';

class CustomFeatureButton extends StatelessWidget {
  final String imageLocation;
  final VoidCallback onTap;

  const CustomFeatureButton({
    required this.imageLocation,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                imageLocation,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
