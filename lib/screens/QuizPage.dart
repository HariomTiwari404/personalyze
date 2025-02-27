import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, String> userResponses = {};
  int questionIndex = 0;
  List<Map<String, dynamic>> questionsList = [
    {
      "question": "What describes you best?",
      "options": ["Leader", "Thinker", "Doer", "Dreamer"]
    },
    {
      "question": "How do you handle stress?",
      "options": ["Exercise", "Meditation", "Talking to friends", "Ignoring it"]
    },
    {
      "question": "What motivates you the most?",
      "options": ["Success", "Happiness", "Knowledge", "Helping others"]
    },
    {
      "question": "How do you prefer to spend your free time?",
      "options": ["Reading", "Partying", "Outdoor activities", "Gaming"]
    },
    {
      "question": "Do you consider yourself an introvert or extrovert?",
      "options": ["Introvert", "Extrovert", "Ambivert", "Depends"]
    },
    {
      "question": "What is your approach to solving problems?",
      "options": [
        "Logical analysis",
        "Creative thinking",
        "Asking for help",
        "Trial and error"
      ]
    },
    {
      "question": "How do you handle conflicts?",
      "options": [
        "Avoidance",
        "Direct confrontation",
        "Compromise",
        "Letting it go"
      ]
    },
    {
      "question": "What is your ideal vacation?",
      "options": ["Mountains", "Beach", "City exploration", "Staycation"]
    },
    {
      "question": "How do you like to learn?",
      "options": ["Visual", "Auditory", "Reading/Writing", "Hands-on"]
    },
    {
      "question": "What kind of movies do you enjoy?",
      "options": ["Action", "Drama", "Comedy", "Horror"]
    },
    {
      "question": "How do you react to unexpected changes?",
      "options": [
        "Adapt quickly",
        "Feel uneasy",
        "Take time to process",
        "Avoid change"
      ]
    },
    {
      "question": "What is your preferred way to express yourself?",
      "options": ["Writing", "Speaking", "Art", "Music"]
    },
    {
      "question": "How do you approach decision-making?",
      "options": [
        "Quick and intuitive",
        "Careful analysis",
        "Seek advice",
        "Go with the flow"
      ]
    },
    {
      "question": "What kind of books do you like to read?",
      "options": ["Fiction", "Non-fiction", "Self-help", "Fantasy"]
    },
    {
      "question": "How do you deal with failure?",
      "options": [
        "Learn from it",
        "Move on quickly",
        "Get discouraged",
        "Try again"
      ]
    },
    {
      "question": "What is your social media usage like?",
      "options": ["Very active", "Occasionally post", "Rarely use", "Never use"]
    },
    {
      "question": "What kind of job environment do you prefer?",
      "options": ["Teamwork", "Independent work", "Flexible", "Structured"]
    },
    {
      "question": "How do you feel about taking risks?",
      "options": [
        "Love it",
        "Avoid it",
        "Depends on situation",
        "Take calculated risks"
      ]
    },
    {
      "question": "How do you handle feedback?",
      "options": [
        "Appreciate it",
        "Take it personally",
        "Use it for growth",
        "Ignore it"
      ]
    },
    {
      "question": "What role do you usually take in a group?",
      "options": ["Leader", "Supporter", "Thinker", "Observer"]
    },
    {
      "question": "What is your preferred communication style?",
      "options": ["Direct", "Polite", "Detailed", "Minimal"]
    },
    {
      "question": "How do you recharge after a long day?",
      "options": [
        "Alone time",
        "Hanging out with friends",
        "Watching TV",
        "Sleeping"
      ]
    },
    {
      "question": "Do you prefer planning or spontaneity?",
      "options": [
        "Detailed planning",
        "Go with the flow",
        "Balanced approach",
        "Depends"
      ]
    },
    {
      "question": "How do you feel about competition?",
      "options": ["Love it", "Avoid it", "Healthy competition", "Indifferent"]
    },
    {
      "question": "What inspires you the most?",
      "options": [
        "Success stories",
        "Challenges",
        "Personal growth",
        "Creativity"
      ]
    },
  ];
  @override
  void initState() {
    super.initState();
    questions = List.from(questionsList); // Assign the imported list
    shuffleQuestions();
  }

  void nextPage() {
    if (questionIndex + 10 < questions.length) {
      setState(() {
        questionIndex += 10;
      });
    }
  }

  void shuffleQuestions() {
    questions.shuffle(); // Shuffles the list randomly
    setState(() {}); // Update UI with shuffled questions
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
        // If document doesn't exist, create a new one
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
      body: questions.isEmpty
          ? Center(child: CircularProgressIndicator())
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: previousPage,
                        child: Text("Previous"),
                      ),
                      ElevatedButton(
                        onPressed: uploadResponses,
                        child: Text("Submit"),
                      ),
                      ElevatedButton(
                        onPressed: nextPage,
                        child: Text("Next"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
