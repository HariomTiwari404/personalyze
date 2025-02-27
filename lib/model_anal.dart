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
  List<BarChartGroupData> _fluencyData = [];
  List<RadarDataSet> _radarData = [];
  Map<String, double> _latestTraits = {};

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
        List<BarChartGroupData> fluencyData = [];
        Map<String, double> latestTraits = {};

        for (int i = 0; i < history.length; i++) {
          double confidence =
              (history[i]['speech']['confidence'] as num).toDouble();
          double fluency = (history[i]['speech']['fluency'] as num).toDouble();
          confidenceData.add(BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: confidence, color: Colors.blue, width: 16)
          ]));
          fluencyData.add(BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: fluency, color: Colors.green, width: 16)
          ]));

          latestTraits = (history[i]['traits'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, (value as num).toDouble()));
        }

        List<RadarDataSet> radarData = [
          RadarDataSet(
            dataEntries: latestTraits.entries
                .map((e) => RadarEntry(value: e.value))
                .toList(),
            borderColor: Colors.purple,
            fillColor: Colors.purple.withOpacity(0.4),
          )
        ];

        setState(() {
          _confidenceData = confidenceData;
          _fluencyData = fluencyData;
          _radarData = radarData;
          _latestTraits = latestTraits;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mood Summary")),
      body: SingleChildScrollView(
        child: Padding(
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
              SizedBox(height: 32),
              Text("Fluency vs Time",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _fluencyData.isEmpty
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
                          barGroups: _fluencyData,
                        ),
                      ),
              ),
              SizedBox(height: 32),
              Text("Personality Traits",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _radarData.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : RadarChart(
                        RadarChartData(
                          dataSets: _radarData,
                          radarBackgroundColor: Colors.transparent,
                          borderData: FlBorderData(show: false),
                          titlePositionPercentageOffset: 0.15,
                          getTitle: (index, angle) {
                            return RadarChartTitle(
                              text: _latestTraits.keys.elementAt(index),
                              angle: angle,
                              positionPercentageOffset: 0.1,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
