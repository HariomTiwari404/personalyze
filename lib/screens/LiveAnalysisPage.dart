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

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraInitialized = true);

    // Start periodic image capture
    _captureTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isAnalyzing) {
        _analyzeVideoFrame();
      }
    });
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _userVoiceInput = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        localeId: 'en_US',
      );
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _analyzeVideoFrame() async {
    if (!_isCameraInitialized || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final XFile frame = await _cameraController!.takePicture();
      final File imageFile = File(frame.path);

      if (!await imageFile.exists()) {
        print('Frame capture failed');
        return;
      }

      final imageBytes = await imageFile.readAsBytes();

      final prompt = [
        Part.text(_userVoiceInput ?? 'Analyze the content of this image'),
        Part.inline(InlineData.fromUint8List(imageBytes)),
      ];

      final response = await Gemini.instance.prompt(parts: prompt);

      setState(() {
        _analysisResult = response?.output ?? 'No analysis result';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Live Analysis'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade400],
          ),
        ),
        child: Column(
          children: [
            if (_isCameraInitialized)
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color:
                                _isListening ? Colors.red : Colors.deepPurple,
                            size: 40,
                          ),
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _analyzeVideoFrame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Analyze Frame'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _analysisResult ?? 'Waiting for analysis...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
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
    );
  }
}
