import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class MoodSummaryScreen extends StatefulWidget {
  const MoodSummaryScreen({super.key});

  @override
  _MoodSummaryScreenState createState() => _MoodSummaryScreenState();
}

class _MoodSummaryScreenState extends State<MoodSummaryScreen> {
  String _summary = "Loading...";

  @override
  void initState() {
    super.initState();
    _getAnalysisHistory();
    _fetchAndSummarizeMood();
  }

  Future<List<Map<String, dynamic>>> _getAnalysisHistory() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final docRef = FirebaseFirestore.instance
        .collection('personality_analysis')
        .doc('testUser'); // Directly reference the document

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('analysis_history')) {
        List<dynamic> rawHistory = data['analysis_history'];

        // Convert string-encoded JSON into Map<String, dynamic>
        List<Map<String, dynamic>> history = rawHistory.map((entry) {
          return Map<String, dynamic>.from(
            (entry is String)
                ? jsonDecode(
                    entry.replaceAll("```json", "").replaceAll("```", ""))
                : entry,
          );
        }).toList();

        print("Fetched Data: $history");
        return history;
      }
    }

    print("No analysis history found.");
    return [];
  }

  Future<void> _fetchAndSummarizeMood() async {
    List<Map<String, dynamic>> history = await _getAnalysisHistory();
    if (history.isEmpty) {
      setState(() {
        _summary = "No analysis history available.";
      });
      return;
    }
    String inputText = history.map((entry) => entry.toString()).join("\n");
    Gemini gemini = Gemini.instance;
    var response = await gemini.text(
        "Summarize the emotional condition based on this data: $inputText");
    setState(() {
      _summary = response?.output ??
          """You are a personality and speech analyzer. Your task is twofold:
1. Analyze the input JSON.
2. Extract the speech parameters (confidence and fluency) and generate graph points for:
   - "Confidence vs Time"
   - "Fluency in English vs Time"
   - "Accuracy of gesture vs Time"
Now, process the input JSON accordingly and generate the output. , in array form""";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mood Summary")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(_summary, style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
