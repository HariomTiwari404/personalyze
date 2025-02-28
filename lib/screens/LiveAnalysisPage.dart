import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image/image.dart' as img;
import 'package:personlayze/widgets/SoundWaveWidget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({super.key});

  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  final List<double> _soundLevels = List.filled(20, 0.0);
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool? _isAnalyzing = false;
  String? _analysisResult;
  String? _userVoiceInput;
  Timer? _captureTimer;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool? _isListening = false;
  final List<XFile> _capturedFrames = [];
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSpeechRecognition();
  }

  Future<void> _initializeSpeechRecognition() async {
    await _speechToText.initialize();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );
    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _startListening() async {
    if (!_isListening!) {
      setState(() => _isListening = true);
      setState(() {
        _soundLevels.fillRange(0, _soundLevels.length, 1.0);
      });
      _capturedFrames.clear();
      _userVoiceInput = null;

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _userVoiceInput = result.recognizedWords;
          });
          _resetAnalysisTimer();
        },
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevels.removeAt(0);
            _soundLevels.add(level / 10);
          });
        },
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );

      _startCaptureTimer();
      _resetAnalysisTimer();
    }
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isListening!) {
        _captureFrame();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _captureFrame() async {
    if (_isCameraInitialized && _isListening!) {
      try {
        await _cameraController!.setFlashMode(FlashMode.off);
        final XFile frame = await _cameraController!.takePicture();

        File originalFile = File(frame.path);
        if (!await originalFile.exists()) return;

        Uint8List imageBytes = await originalFile.readAsBytes();
        img.Image? decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          img.Image resizedImage = img.copyResize(decodedImage, width: 800);

          List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 85);

          File compressedFile = File(frame.path)
            ..writeAsBytesSync(compressedBytes);

          if (compressedFile.lengthSync() <= 1024 * 1024) {
            setState(() {
              _capturedFrames.add(XFile(compressedFile.path));
            });
          } else {
            print('Compressed image is still too large.');
          }
        }
      } catch (e) {
        print('Frame capture failed: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAnalysisHistory() async {
    String userId = "testUser"; // Replace with FirebaseAuth user ID

    final docRef = FirebaseFirestore.instance
        .collection('personality_analysis')
        .doc(userId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      return (data?['analysis_history'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    return [];
  }

  void _stopListening() {
    _speechToText.stop();
    _captureTimer?.cancel();
    setState(() {
      _isListening = false;
    });
    _analyzeCollectedData();
  }

  void _resetAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer(const Duration(seconds: 5), () {
      if (_isListening!) {
        _stopListening();
      }
    });
  }

  Future<void> _analyzeCollectedData() async {
    print("Starting analysis...");
    if (!_isCameraInitialized || _isAnalyzing!) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = "Analyzing... Please wait.";
    });

    try {
      List<Part> prompt = [];
      const String defaultPrompt =
          "You are an AI analyzing a person's personality based on their speech, facial expressions, and body language. "
          "Follow these strict guidelines to ensure accuracy and minimize hallucination: "
          "1. **Speech Analysis:** Extract emotional tone, confidence level, and speaking pace, but DO NOT assume any meaning beyond detected vocal patterns. "
          "2. **Facial Expression Analysis:** Identify visible emotions such as happiness, sadness, anger, or neutrality. Avoid making subjective assumptions. "
          "3. **Attire Analysis:** Describe the base color and design of the person's attire, but DO NOT infer anything about their personality based on it. "
          "4. **Body Language:** Observe hand gestures and posture to determine engagement level (e.g., open vs. closed posture). "
          "5. **Conversation Context:** Extract a brief summary (max 20 words) of what the person is talking about, if determinable. Otherwise, state 'Cannot be determined'. "
          "6. **Personality Traits:** Provide a numerical rating (0-10) for each of the Big Five personality traits based on visible cues only: "
          "   - Openness: (0-10) "
          "   - Conscientiousness: (0-10) "
          "   - Extraversion: (0-10) "
          "   - Agreeableness: (0-10) "
          "   - Neuroticism: (0-10) "
          "7. **Speech Characteristics:** Assign numerical ratings (0-10) for: "
          "   - Confidence: (0-10) "
          "   - Fluency: (0-10) "
          "8. **Strict Output Format:** Return the following structured JSON response without adding any explanations: "
          "{ "
          "\"personality\": {\"condition\": \"sad\", \"happy\", \"angry\"}, "
          "\"speech_topic\": \"A short description of what the person is talking about, or 'Cannot be determined'\", "
          "\"posture\": \"open\" or \"closed\" or \"neutral\", "
          "\"traits\": { "
          "  \"openness\": (0-10), "
          "  \"conscientiousness\": (0-10), "
          "  \"extraversion\": (0-10), "
          "  \"agreeableness\": (0-10), "
          "  \"neuroticism\": (0-10) "
          "}, "
          "\"speech\": { "
          "  \"confidence\": (0-10), "
          "  \"fluency\": (0-10) "
          "} "
          "}";

      prompt.add(Part.text(defaultPrompt));

      if (_userVoiceInput != null && _userVoiceInput!.isNotEmpty) {
        prompt.add(Part.text(
            "Speech input (for tone analysis only): $_userVoiceInput"));
      }

      for (final frame in _capturedFrames) {
        final File imageFile = File(frame.path);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          prompt.add(Part.inline(InlineData.fromUint8List(imageBytes)));
        }
      }

      final response = await Gemini.instance.prompt(parts: prompt);

      setState(() {
        _analysisResult = response?.output ?? 'No analysis result available.';
      });

      await _storeAnalysisResult(_analysisResult!);
      print("Calling _storeAnalysisResult...");
    } catch (e) {
      setState(() {
        _analysisResult = 'Analysis failed: $e';
      });
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _storeAnalysisResult(String resultText) async {
    try {
      String userId = "testUser";
      final docRef = FirebaseFirestore.instance
          .collection('personality_analysis')
          .doc(userId);

      await docRef.set({
        'analysis_history': FieldValue.arrayUnion([resultText])
      }, SetOptions(merge: true));

      print("Analysis result stored successfully.");
    } catch (e) {
      print("Error storing analysis result: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captureTimer?.cancel();
    _speechToText.stop();
    _analysisTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Personality Analysis'),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: SingleChildScrollView(
                        child: _isAnalyzing == false && _analysisResult != null
                            ? AnalysisResultWidget(
                                analysisResult: _analysisResult!)
                            : const Text(' ',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isListening!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SoundWaveWidget(
                              soundLevels: _soundLevels,
                              color: Colors.blueAccent,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.3),
                            elevation: 8,
                          ).copyWith(
                            foregroundColor:
                                WidgetStateProperty.all(Colors.white),
                          ),
                          onPressed: (_isListening! || _isAnalyzing!)
                              ? null
                              : _startListening,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isListening!
                                    ? [Colors.redAccent, Colors.deepOrange]
                                    : [
                                        Colors.blueAccent,
                                        Colors.deepPurpleAccent
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isListening! ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isListening!
                                        ? 'Stop Listening'
                                        : (_isAnalyzing!
                                            ? 'Analyzing...'
                                            : 'Start Listening'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
    );
  }
}

class AnalysisResultWidget extends StatelessWidget {
  final String? analysisResult;

  const AnalysisResultWidget({super.key, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? result;

    if (analysisResult == null || analysisResult!.isEmpty) {
      return _buildErrorMessage('No analysis result available.');
    }

    try {
      String cleanedResult = analysisResult!.trim();
      final regex = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true);
      final match = regex.firstMatch(cleanedResult);

      if (match != null) {
        cleanedResult = match.group(1)!;
      }

      result = json.decode(cleanedResult);
    } catch (e) {
      return _buildErrorMessage('Error decoding analysis result: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCardSection(
                'Personality Condition', result?['personality']?['condition']),
            _buildCardSection('Speech Topic', result?['speech_topic']),
            _buildCardSection('Posture', result?['posture']),
            _buildExpandableTraitSection(
                context, 'Personality Traits', result?['traits']),
            _buildExpandableTraitSection(
                context, 'Speech Characteristics', result?['speech']),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCardSection(String title, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // Transparent background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5), // White border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle()),
          const SizedBox(height: 6),
          Text(value ?? 'Unknown', style: _valueStyle()),
        ],
      ),
    );
  }

  TextStyle _titleStyle() => const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent);
  TextStyle _valueStyle() =>
      const TextStyle(fontSize: 16, color: Colors.lightBlueAccent);
  Widget _buildExpandableTraitSection(
      BuildContext context, String title, Map<String, dynamic>? traits) {
    if (traits == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(title, style: _titleStyle()),
          collapsedIconColor: Colors.white70,
          iconColor: Colors.white,
          children: traits.entries
              .map((e) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child:
                        _buildTraitItem(e.key.capitalize(), e.value.toString()),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTraitItem(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: _valueStyle()),
        Text(value, style: _traitValueStyle()),
      ],
    );
  }

  TextStyle _traitValueStyle() =>
      const TextStyle(fontSize: 14, color: Colors.lightBlueAccent);
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
