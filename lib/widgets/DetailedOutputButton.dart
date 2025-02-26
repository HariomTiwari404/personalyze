import 'package:flutter/material.dart';

class DetailedOutputButton extends StatefulWidget {
  final String title;
  final String subTitle;
  final Color color;
  const DetailedOutputButton({
    required this.color,
    required this.title,
    required this.subTitle,
    super.key});

  @override
  State<DetailedOutputButton> createState() => _DetailedOutputButtonState();
}

class _DetailedOutputButtonState extends State<DetailedOutputButton> {
  @override
  Widget build(BuildContext context) {
    return  Container(
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