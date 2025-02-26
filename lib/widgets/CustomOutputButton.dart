import 'package:flutter/material.dart';

class CustomOutputButton extends StatefulWidget {
  final Color color;
  final String title;
  final String subTitle;

  const CustomOutputButton({
    required this.title,
    required this.subTitle,
    required this.color,
    super.key,
  });

  @override
  State<CustomOutputButton> createState() => _CustomOutputButtonState();
}

class _CustomOutputButtonState extends State<CustomOutputButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16), 
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.subTitle,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
