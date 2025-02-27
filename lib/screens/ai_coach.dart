import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class AICoachSection extends StatefulWidget {
  const AICoachSection({super.key});

  @override
  _AICoachSectionState createState() => _AICoachSectionState();
}

class _AICoachSectionState extends State<AICoachSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final String _response = '';
  bool _isLoading = false;
  bool _isChatExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final List<ChatMessage> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    fetchAnalysisHistory();
    fetchResponses();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchAnalysisHistory() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final docRef = FirebaseFirestore.instance
        .collection('personality_analysis')
        .doc('testUser');

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('analysis_history')) {
        List<dynamic> rawHistory = data['analysis_history'];

        return rawHistory
            .map<Map<String, dynamic>>((entry) {
              try {
                if (entry is String) {
                  String cleanedEntry =
                      entry.replaceAll("json", "").replaceAll("", "").trim();
                  return jsonDecode(cleanedEntry);
                } else {
                  return Map<String, dynamic>.from(entry);
                }
              } catch (e) {
                return {};
              }
            })
            .where((entry) => entry.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchResponses() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .doc('user_responses')
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> responses = data['responses'] ?? [];
        return List<Map<String, dynamic>>.from(responses);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void _toggleChatExpansion() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
      if (_isChatExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<String> fetchGeminiResponse(String message) async {
    const apiKey = 'AIzaSyBLeNZPjRcR4u2osIfqJ2wHN1-jgQw-kRU';

    final analysisHistory = await fetchAnalysisHistory();
    final quizResponses = await fetchResponses();

    String systemContext = '''
You are an AI coach trained to provide personalized guidance based on the user's personality analysis and previous responses. 

User Profile:
${analysisHistory.isNotEmpty ? """
- Emotional State: ${analysisHistory.last['personality']['condition']}
- Recent Topic: ${analysisHistory.last['speech_topic']}
- Posture: ${analysisHistory.last['posture']}
- Personality Traits:
  * Openness: ${analysisHistory.last['traits']['openness']}/10
  * Conscientiousness: ${analysisHistory.last['traits']['conscientiousness']}/10
  * Extraversion: ${analysisHistory.last['traits']['extraversion']}/10
  * Agreeableness: ${analysisHistory.last['traits']['agreeableness']}/10
  * Neuroticism: ${analysisHistory.last['traits']['neuroticism']}/10
- Communication Style:
  * Confidence: ${analysisHistory.last['speech']['confidence']}/10
  * Fluency: ${analysisHistory.last['speech']['fluency']}/10
""" : "No personality analysis available."}

User's Work Style (Based on Quiz):
${quizResponses.map((response) => "- ${response['question']}: ${response['selected_answer']}").join('\n')}

Based on this profile, provide personalized advice for the following user query in 100 words only in html formating do not say anthing else pure html response only   :
$message
''';

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': systemContext}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'No valid response from AI';
    } else {
      try {
        final error = jsonDecode(response.body);
        return 'Error: ${error['error']['message']}';
      } catch (e) {
        return 'Error: Unable to process response';
      }
    }
  }

  Future<List<String>> fetchYouTubeVideos() async {
    const apiKey = 'AIzaSyCa2l1LdRh58HO71nuCkIvgEF-N14ZvS4Q';

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=5&q=AI&type=video&key=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['items'] as List)
            .map((item) => item['snippet']['title'] as String)
            .toList();
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text;
    if (userInput.isEmpty) return;

    setState(() {
      _chatHistory.add(ChatMessage(
        text: userInput,
        isUser: true,
      ));
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response =
          await fetchGeminiResponse('Personality and confidence: $userInput');

      setState(() {
        _chatHistory.add(ChatMessage(
          text: response,
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage(
          text: 'Error: Unable to fetch response. ${e.toString()}',
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrowthAI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(child: _buildChatHistory()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) => _buildChatBubble(_chatHistory[index]),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          _isLoading
              ? Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.send, color: Colors.indigo[700], size: 28),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.indigo[100]
              : (message.isError ? Colors.red[100]! : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Html(
          data: cleanHtmlResponse(
              message.text), // Clean HTML response before rendering
          style: {
            "body": Style(
              fontSize: FontSize(16),
              color: message.isError ? Colors.red[900] : Colors.black87,
            ),
          },
        ),
      ),
    );
  }

  String cleanHtmlResponse(String text) {
    return text.replaceAll(RegExp(r'```html\n?|\n?```'), '').trim();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
