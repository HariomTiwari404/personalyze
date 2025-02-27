import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onPressed; // ✅ Add onPressed callback
  final String? profileLocation;
  final Color textColor;

  const CustomHeader({
    required this.title,
    this.icon,
    this.onPressed, // ✅ Allow icon button action
    this.profileLocation,
    this.textColor = Colors.black,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          Row(
            children: [
              if (icon != null)
                IconButton(
                  // ✅ Use IconButton instead of Icon
                  icon: Icon(icon, color: textColor, size: 28),
                  onPressed: onPressed, // ✅ Allow clicking action
                ),
              if (profileLocation != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(
                        profileLocation!), // Assuming local asset image
                    backgroundColor: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
