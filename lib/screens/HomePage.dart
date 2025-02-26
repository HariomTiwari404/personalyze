import 'package:flutter/material.dart';
import 'package:personlayze/screens/CustomizationPage.dart';
import 'package:personlayze/screens/LiveAnalysisPage.dart';
import 'package:personlayze/screens/SpeechAndFluencyPage.dart';
import 'package:personlayze/widgets/BottomNavBar.dart';
import 'package:personlayze/widgets/CustomFeatureButton.dart';
import 'package:personlayze/widgets/CustomHeader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/performance');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Prevents UI overlap
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Header
              const CustomHeader(title: "Personalyze", icon: Icons.person),
              const SizedBox(height: 16),

              // Welcome Text
              const Text(
                "Hi User",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Search or enter command",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.2),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feature Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final featureData = [
                      {
                        "image": "assets/images/ai.jpg",
                        "onTap": () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LiveAnalysisPage())),
                      },
                      {
                        "image": "assets/images/customization.jpg",
                        "onTap": () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SpeechAndFluencyPage())),
                      },
                      {
                        "image": "assets/images/14.jpg",
                        "onTap": () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomizationPage())),
                      },
                      {
                        "image": "assets/images/speech.jpg",
                        "onTap": () {},
                      },
                    ];

                    return CustomFeatureButton(
                      imageLocation: featureData[index]["image"] as String,
                      onTap: featureData[index]["onTap"] as VoidCallback,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
