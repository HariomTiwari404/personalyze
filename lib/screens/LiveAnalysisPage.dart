import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:personlayze/constants/colors.dart';
import 'package:personlayze/screens/DetailedAnalysisPage.dart';
import 'package:personlayze/widgets/CustomHeader.dart';
import 'package:personlayze/widgets/CustomOutputButton.dart';

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({super.key});

  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMicEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() => _isCameraInitialized = false);
    }
  }

  void _toggleCamera() {
    if (_isCameraInitialized) {
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
        _cameraController = null;
      });
    } else {
      _initializeCamera();
    }
  }

  void _toggleMicrophone() {
    setState(() => _isMicEnabled = !_isMicEnabled);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CustomHeader(title: "Live A.I Analysis"),
              const SizedBox(height: 16),
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: _isCameraInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _isCameraInitialized
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    child: IconButton(
                      icon: Icon(
                        _isCameraInitialized
                            ? Icons.videocam_off
                            : Icons.videocam,
                        color: Colors.white,
                      ),
                      onPressed: _toggleCamera,
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _isMicEnabled
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    child: IconButton(
                      icon: Icon(
                        _isMicEnabled ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMicrophone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomOutputButton(
                color: AppColors.outputButton,
                title: 'AI Analysis Output',
                subTitle:
                    "This is a placeholder text for AI analysis results. Detailed results will be displayed here.",
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetailedAnalysisPage()),
                  );
                },
                child: Container(
                  height: 55,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: AppColors.btnColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(2, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "View Detailed Analysis",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
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
