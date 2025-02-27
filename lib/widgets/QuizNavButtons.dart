import 'package:flutter/material.dart';

class QuizNavButtons extends StatelessWidget {
  final String navOption;
  final VoidCallback onTap; // Callback function for tap action

  const QuizNavButtons({
    required this.navOption,
    required this.onTap, // Required function parameter
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Calls the function when tapped
      child: Container(
        height: 50,
        width: MediaQuery.of(context).size.width * 0.28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          navOption,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
