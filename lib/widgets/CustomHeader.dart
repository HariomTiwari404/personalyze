import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final String? profileLocation;
  final Color textColor;

  const CustomHeader({
    this.profileLocation,
    this.title,
    this.icon,
    this.textColor=Colors.black,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title ?? "Default Title" , style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold , color: textColor),), 
          Icon(icon ?? Icons.error), 
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
