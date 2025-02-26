import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image/image.dart' as img; // Import the image package
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({super.key});

  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  final bool _isCapturing = false; // Add this flag

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _userVoiceInput;
  Timer? _captureTimer;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _hasSentDefaultPrompt = false;
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
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
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
          _resetAnalysisTimer();
        },
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );

      _startCaptureTimer(); // Start the timer to capture frames every 2 secs
      _resetAnalysisTimer();
    }
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel(); // Cancel previous timer if any
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isListening) {
        _captureFrame();
      } else {
        timer.cancel(); // Stop capturing when listening stops
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

        // Read image bytes
        Uint8List imageBytes = await originalFile.readAsBytes();
        img.Image? decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          // Resize image (adjust resolution to reduce size)
          img.Image resizedImage = img.copyResize(decodedImage,
              width: 800); // Adjust width to control size

          // Compress image to JPEG with lower quality
          List<int> compressedBytes = img.encodeJpg(resizedImage,
              quality: 85); // Adjust quality (lower = smaller size)

          // Save the compressed image to a temporary file
          File compressedFile = File(frame.path)
            ..writeAsBytesSync(compressedBytes);

          if (compressedFile.lengthSync() <= 1024 * 1024) {
            // Ensure it's under 1MB
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
    _captureTimer?.cancel(); // Stop capturing when listening stops
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
          "You are an AI model designed to predict a person's personality based on their facial expressions and speech patterns. "
          "Your task is to analyze their gestures, emotions, and tone of voice to determine their personality traits. "
          "Focus only on how they appear and behave, regardless of what they are saying. "
          "Identify if they seem happy, nervous, confident, sad, or any other emotional state. "
          "Additionally, infer any potential psychological or emotional trends they might experience in the near future based on their behavior. "
          "You must provide exactly five key personality traits that best describe the person in a concise response of no more than five lines.";

      if (!_hasSentDefaultPrompt) {
        prompt.add(Part.text(defaultPrompt));
        _hasSentDefaultPrompt = true;
      }

      if (_userVoiceInput != null && _userVoiceInput!.isNotEmpty) {
        prompt.add(Part.text("Speech input: $_userVoiceInput"));
      }

      for (final frame in _capturedFrames) {
        final File imageFile = File(frame.path);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          prompt.add(Part.inline(InlineData.fromUint8List(imageBytes)));
        } else {
          print('Frame file not found: ${frame.path}');
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
      // You can remove or customize the AppBar if you prefer a full-screen camera
      appBar: AppBar(
        title: const Text('AI Personality Analysis'),
        backgroundColor: Colors.deepPurple,
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
                // Camera preview as the full-screen background
                CameraPreview(_cameraController!),
                // Bottom overlay for analysis response and the control button
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
                            backgroundColor: _isListening
                                ? Colors.redAccent
                                : Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: Colors.deepPurpleAccent,
                          ),
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isListening
                                    ? 'Stop Listening'
                                    : 'Start Listening',
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
    );
  }
}
