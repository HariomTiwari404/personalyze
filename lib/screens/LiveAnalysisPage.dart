import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:personlayze/constants/colors.dart';
import 'package:personlayze/screens/DetailedAnalysisPage.dart';
import 'package:personlayze/widgets/CustomHeader.dart';
import 'package:personlayze/widgets/CustomOutputButton.dart';

class LiveAnalysisPage extends StatefulWidget {
  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0], 
      ResolutionPreset.medium,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomHeader(title: "Live A.I Analysis"),
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isCameraInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CameraPreview(_cameraController!),
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueGrey.shade500,
                    elevation: 4,
                  ),
                  child: Text(
                    "ICons",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                CustomOutputButton(
                  color: AppColors.outputButton,
                  title: 'Output',
                  subTitle: 'Lorem ipsum (/ˌlɔː.rəm ˈɪp.səm/ LOR-əm IP-səm) is a dummy or placeholder text commonly used in graphic design, publishing, t',
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DetailedAnalysisPage()),
                    );
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: AppColors.btnColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "View Detailed Analysis",
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
