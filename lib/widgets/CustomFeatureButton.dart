import 'package:flutter/material.dart';

class CustomFeatureButton extends StatelessWidget {
  final String data;
  final VoidCallback onTap; 

  const CustomFeatureButton({
    required this.data,
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
            color: Colors.grey,
          ),
          alignment: Alignment.center, 
          child: Text(
            data,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
