import 'package:flutter/material.dart';

class CustomOutputButton extends StatefulWidget {
  const CustomOutputButton({super.key});

  @override
  State<CustomOutputButton> createState() => _CustomOutputButtonState();
}

class _CustomOutputButtonState extends State<CustomOutputButton> {
  @override
  Widget build(BuildContext context) {
    return  Container(
              height: MediaQuery.of(context).size.height*0.55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(16)
              ),
            );
  }
}