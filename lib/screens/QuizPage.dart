import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:personlayze/screens/quizGen.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, String> userResponses = {};
  int questionIndex = 0;
  bool isLoading = true; // Track loading state
  final QuizGenerator quizGenerator = QuizGenerator(); // Create an instance

  @override
  void initState() {
    super.initState();
    _fetchGeneratedQuestions();
  }

  Future<void> _fetchGeneratedQuestions() async {
    List<Map<String, dynamic>> generatedQuestions =
        await quizGenerator.generateQuizQuestions();

    print("Fetched Questions: $generatedQuestions"); // Debugging log

    if (generatedQuestions.isNotEmpty) {
      setState(() {
        questions = generatedQuestions;
        isLoading = false;
      });
    } else {
      print("No questions found!"); // Debugging log
      setState(() {
        isLoading = false;
      });
    }
  }

  void nextPage() {
    if (questionIndex + 10 < questions.length) {
      setState(() {
        questionIndex += 10;
      });
    }
  }

  void previousPage() {
    if (questionIndex - 10 >= 0) {
      setState(() {
        questionIndex -= 10;
      });
    }
  }

  Future<void> uploadResponses() async {
    int totalQuestionsOnPage = (questionIndex + 10 <= questions.length)
        ? 10
        : questions.length - questionIndex;

    bool allAnswered = true;
    for (int i = 0; i < totalQuestionsOnPage; i++) {
      int actualIndex = questionIndex + i;
      if (!userResponses.containsKey(actualIndex)) {
        allAnswered = false;
        break;
      }
    }

    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please answer all questions before submitting!")),
      );
      return;
    }

    List<Map<String, dynamic>> submittedResponses =
        userResponses.entries.map((entry) {
      int index = entry.key;
      return {
        "question": questions[index]["question"],
        "selected_answer": entry.value,
      };
    }).toList();

    try {
      DocumentReference responseDoc = FirebaseFirestore.instance
          .collection('responses')
          .doc('user_responses');

      DocumentSnapshot docSnapshot = await responseDoc.get();

      if (docSnapshot.exists) {
        await responseDoc.update({
          "responses": FieldValue.arrayUnion(submittedResponses),
        });
      } else {
        await responseDoc.set({
          "responses": submittedResponses,
          "timestamp": Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Responses Submitted Successfully!")),
      );

      setState(() {
        userResponses.clear();
        questionIndex = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading responses: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Personalyse Quiz"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : questions.isEmpty
              ? Center(child: Text("No questions available."))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: (questionIndex + 10 <= questions.length)
                              ? 10
                              : questions.length - questionIndex,
                          itemBuilder: (context, index) {
                            int actualIndex = questionIndex + index;
                            var questionData = questions[actualIndex];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Q${actualIndex + 1}: ${questionData['question']}",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    ...questionData['options']
                                        .map<Widget>((option) {
                                      return RadioListTile<String>(
                                        title: Text(option),
                                        value: option,
                                        groupValue: userResponses[actualIndex],
                                        onChanged: (value) {
                                          setState(() {
                                            userResponses[actualIndex] = value!;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: uploadResponses,
                            child: Text("Submit"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
