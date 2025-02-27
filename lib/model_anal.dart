import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MoodSummaryScreen extends StatefulWidget {
  const MoodSummaryScreen({super.key});

  @override
  _MoodSummaryScreenState createState() => _MoodSummaryScreenState();
}

class _MoodSummaryScreenState extends State<MoodSummaryScreen> {
  List<BarChartGroupData> _confidenceData = [];

  @override
  void initState() {
    super.initState();
    _getAnalysisHistory();
  }

  Future<void> _getAnalysisHistory() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final docRef = FirebaseFirestore.instance
        .collection('personality_analysis')
        .doc('testUser');

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('analysis_history')) {
        List<dynamic> rawHistory = data['analysis_history'];

        List<Map<String, dynamic>> history = rawHistory.map((entry) {
          return Map<String, dynamic>.from(
            (entry is String)
                ? jsonDecode(
                    entry.replaceAll("```json", "").replaceAll("```", ""))
                : entry,
          );
        }).toList();

        List<BarChartGroupData> confidenceData = [];
        for (int i = 0; i < history.length; i++) {
          double confidence =
              (history[i]['speech']['confidence'] as num).toDouble();
          confidenceData.add(BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: confidence, color: Colors.blue, width: 16)
          ]));
        }

        setState(() {
          _confidenceData = confidenceData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mood Summary")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Confidence vs Time",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _confidenceData.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text(value.toInt().toString());
                              }
                              return Container();
                            },
                          )),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString());
                            },
                          )),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: _confidenceData,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
