import 'package:flutter/material.dart';
import 'package:personlayze/screens/QuizResultPage.dart';
import 'package:personlayze/widgets/QuestionsButton.dart';
import 'package:personlayze/widgets/QuizNavButtons.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keeping your original background color
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Personalyse",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  "Assessment",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Question Card
            QuestionsButton(
              questionNumber: 1,
              question: "Who are you?",
              options: [
                "A programming language",
                "A UI framework",
                "A database",
                "An operating system"
              ],
            ),

            const SizedBox(height: 30),

            // Navigation Buttons
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuizNavButtons(
                  navOption: "Previous",
                  onTap: () {},
                ),
                QuizNavButtons(
                  navOption: "Save Progress",
                  onTap: () {},
                ),
                QuizNavButtons(
                  navOption: "Next",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QuizResultPage()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
