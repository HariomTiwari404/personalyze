import 'package:flutter/material.dart';
import 'package:personlayze/constants/colors.dart';
import 'package:personlayze/widgets/CustomOutputButton.dart';
import 'package:personlayze/widgets/QuizNavButtons.dart';

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({super.key});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keeping your background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Personalyse",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // Profile & Result Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.black,
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/quiz.png",
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Your Primary Trait:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    "Intuitive",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You have a natural ability to understand and perceive "
                    "things deeply. Your intuitive nature allows you to make insightful "
                    "decisions and connect with people on a deeper level.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Output Buttons
            CustomOutputButton(
              title: "Detailed Insights",
              subTitle: "View a deep analysis of your personality",
              color: AppColors.btnColor,
            ),
            SizedBox(height: 15),
            CustomOutputButton(
              title: "Body Language Analysis",
              subTitle: "Understand how your gestures speak",
              color: AppColors.bodyLanguageButton,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuizNavButtons(navOption: "Retake Quiz", onTap: () {}),
                QuizNavButtons(navOption: "Share Results", onTap: () {})
              ],
            )
          ],
        ),
      ),
    );
  }
}
