import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // Animation controller for expanding/collapsing chat
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Store chat history
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
      print("Error fetching responses: $e");
      return [];
    }
  }

  // Toggle chat expansion
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

    // Fetch both analysis history and quiz responses
    final analysisHistory = await fetchAnalysisHistory();
    final quizResponses = await fetchResponses();

    // Construct the system context
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

Based on this profile, provide personalized advice for the following user query:
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
    // In a production app, move this API key to a secure location
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

  void _showVideos(List<String> videos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Suggestions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: videos
                .map((title) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(title),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Send message to AI
  Future<void> _sendMessage() async {
    final userInput = _controller.text;
    if (userInput.isEmpty) return;

    // Add user message to chat
    setState(() {
      _chatHistory.add(ChatMessage(
        text: userInput,
        isUser: true,
      ));
      _isLoading = true;
    });

    // Clear input field
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
        title: const Text(
          'GrowthAI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.purple.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: _toggleChatExpansion,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Chat',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            RotationTransition(
                              turns: Tween(begin: 0.0, end: 0.5)
                                  .animate(_expandAnimation),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              // Chat history
                              if (_chatHistory.isNotEmpty)
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 300),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: _chatHistory
                                          .map((message) =>
                                              _buildChatBubble(message))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              if (_chatHistory.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Start a conversation with the AI coach...",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Chat input field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border:
                                      Border.all(color: Colors.purple.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Type your message',
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          border: InputBorder.none,
                                        ),
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    _isLoading
                                        ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.purple[400],
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              Icons.send_rounded,
                                              color: Colors.purple[700],
                                            ),
                                            onPressed: _sendMessage,
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // AI Talk Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_none_outlined,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Talk',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Tap the microphone to start a conversation',
                              style: TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              child: IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: Colors.blue[700],
                                  size: 32,
                                ),
                                onPressed: () {
                                  // Microphone logic
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Video Suggestions Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Video Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.amber.shade50
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              final videos = await fetchYouTubeVideos();
                              setState(() {
                                _isLoading = false;
                              });
                              _showVideos(videos);
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error: Unable to fetch videos. ${e.toString()}'),
                                    backgroundColor: Colors.red.shade400,
                                  ),
                                );
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.orange[700],
                                      ),
                                    )
                                  : Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.orange[700],
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                'Get Video Suggestions',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom chat bubble widget
  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              radius: 16,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 16,
                color: Colors.purple[700],
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.purple[100]
                    : (message.isError ? Colors.red.shade100 : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isError ? Colors.red.shade900 : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Colors.purple[700],
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
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
