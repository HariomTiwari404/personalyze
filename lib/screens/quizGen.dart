import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class QuizGenerator {
  Future<List<Map<String, dynamic>>> fetchAnalysisHistory() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final docRef = FirebaseFirestore.instance
        .collection('personality_analysis')
        .doc('testUser');

    final docSnapshot = await docRef.get();

    print("Firestore document exists: \${docSnapshot.exists}");
    print("Firestore document data: \${docSnapshot.data()}");

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('analysis_history')) {
        List<dynamic> rawHistory = data['analysis_history'];
        print("Raw analysis history: \$rawHistory");

        return rawHistory
            .map<Map<String, dynamic>>((entry) {
              try {
                if (entry is String) {
                  String cleanedEntry = entry
                      .replaceAll("```json", "")
                      .replaceAll("```", "")
                      .trim();
                  return jsonDecode(cleanedEntry);
                } else {
                  return Map<String, dynamic>.from(entry);
                }
              } catch (e) {
                print("Error parsing JSON: \$e");
                return {};
              }
            })
            .where((entry) => entry.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> generateQuizQuestions() async {
    List<Map<String, dynamic>> analysisHistory = await fetchAnalysisHistory();

    if (analysisHistory.isEmpty) {
      print("No analysis history found.");
      return [];
    }

    List<String> speechTopics = analysisHistory
        .where((entry) => entry.containsKey("speech_topic"))
        .map((entry) => entry["speech_topic"] as String)
        .toList();

    String prompt = """
You are a personality quiz generator. Based on the user's conversation topics, create personalized questions that help understand their personality traits better.
The person frequently talks about:
${speechTopics.join(", ")}

Generate exactly 10 quiz questions. Each question should have exactly 4 answer options.
Ensure the response is strictly formatted as a JSON array like this:
[
  {
    "question": "What describes you best?",
    "options": ["Leader", "Thinker", "Doer", "Dreamer"]
  },
  {
    "question": "How do you handle stress?",
    "options": ["Exercise", "Meditation", "Talking to friends", "Ignoring it"]
  }
]
""";

    try {
      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);

      if (response == null) {
        print("Error: Gemini API returned null response.");
        return [];
      }

      print("Raw Gemini API Response: \$response");

      String extractedText = response.output ?? "";
      extractedText =
          extractedText.replaceAll("```json", "").replaceAll("```", "").trim();

      print("Extracted Content: \$extractedText");

      List<Map<String, dynamic>> generatedQuestions =
          List<Map<String, dynamic>>.from(jsonDecode(extractedText));

      return generatedQuestions;
    } catch (e) {
      print("Error calling Gemini API: \$e");
    }
    return [];
  }
}
