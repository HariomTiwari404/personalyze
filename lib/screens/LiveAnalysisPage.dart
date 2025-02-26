import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({super.key});

  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
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
      _capturedFrames.clear();
      _userVoiceInput = null;
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _userVoiceInput = result.recognizedWords;
            _captureFrame();
            _resetAnalysisTimer();
          });
        },
        onSoundLevelChange: (level) {
          _resetAnalysisTimer();
        },
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
      _resetAnalysisTimer();
    }
  }

  void _resetAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer(const Duration(seconds: 5), () {
      if (_isListening) {
        _stopListening();
      }
    });
  }

  Future<void> _captureFrame() async {
    if (_isCameraInitialized && _isListening) {
      try {
        // Capture without triggering UI effects
        await _cameraController!
            .setFlashMode(FlashMode.off); // Ensure flash is off
        final frame = await _cameraController!.takePicture();

        _capturedFrames.add(frame);
      } catch (e) {
        print('Frame capture failed: $e');
      }
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _analyzeCollectedData();
  }

  Future<void> _analyzeCollectedData() async {
    if (!_isCameraInitialized || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      List<Part> prompt = [];

      const String defaultPrompt =
          "You are analyzing a person's personality based on their gestures and speech patterns."
          "Identify key personality traits such as confidence, nervousness, extroversion, introversion, "
          "and mood based on their facial expressions and speech content. Provide a concise analysis.";

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
      backgroundColor: Colors.deepPurple.shade400,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isCameraInitialized
                    ? SizedBox(
                        child: CameraPreview(_cameraController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isListening ? Colors.redAccent : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      shadowColor: Colors.deepPurple.shade700,
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isListening ? 'Stop Listening' : 'Start Listening',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analysis Result:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _analysisResult ?? 'Waiting for analysis...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
