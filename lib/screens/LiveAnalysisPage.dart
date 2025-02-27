import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image/image.dart' as img; // Import the image package
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
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _userVoiceInput;
  Timer? _captureTimer;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
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
    if (!_isListening) {
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
      if (_isListening) {
        _captureFrame();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _captureFrame() async {
    if (_isCameraInitialized && _isListening) {
      try {
        await _cameraController!.setFlashMode(FlashMode.off);
        final XFile frame = await _cameraController!.takePicture();

        File originalFile = File(frame.path);
        if (!await originalFile.exists()) return;

        Uint8List imageBytes = await originalFile.readAsBytes();
        img.Image? decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          img.Image resizedImage = img.copyResize(decodedImage,
              width: 800); // Adjust width to control size

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
      if (_isListening) {
        _stopListening();
      }
    });
  }

  Future<void> _analyzeCollectedData() async {
    if (!_isCameraInitialized || _isAnalyzing) return;

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
    } catch (e) {
      setState(() {
        _analysisResult = 'Analysis failed: $e';
      });
    } finally {
      setState(() => _isAnalyzing = false);
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(
                      maxHeight: 250, // Limits height but allows scrolling
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add the sound wave widget when listening
                        if (_isListening)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SoundWaveWidget(
                              soundLevels: _soundLevels,
                              color: Colors.blueAccent,
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _analysisResult ?? 'Waiting for analysis...',
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontFamily: 'inter',
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
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
                          onPressed: (_isListening || _isAnalyzing)
                              ? null
                              : _startListening, // Disable when analyzing
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isListening
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
                                    _isListening ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isListening
                                        ? 'Stop Listening'
                                        : (_isAnalyzing
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
