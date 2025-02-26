import 'package:flutter/material.dart';

class DetailedOutputButton extends StatefulWidget {
  const DetailedOutputButton({super.key});

  @override
  State<DetailedOutputButton> createState() => _DetailedOutputButtonState();
}

class _DetailedOutputButtonState extends State<DetailedOutputButton> {
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