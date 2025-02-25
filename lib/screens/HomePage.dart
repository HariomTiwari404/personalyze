import 'package:flutter/material.dart';
import 'package:personlayze/widgets/BottomNavBar.dart';
import 'package:personlayze/widgets/CustomFeatureButton.dart';
import 'package:personlayze/widgets/CustomHeader.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
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
     
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
             CustomHeader(
              title: "Personalyze",
              
              icon: Icons.person,
             
            ),
             SizedBox(height: 16),
           
             Text(
               "Hi User",
               style: TextStyle(
                 fontSize: 24,
                 fontWeight: FontWeight.bold,
                 color: Colors.black87,
               ),
             ),
            const SizedBox(height: 8),
            
            TextField(
              decoration: InputDecoration(
                hintText: "Search or enter command",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.transparent.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
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
             SizedBox(height: 16),
          
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, 
                crossAxisSpacing: 16, 
                mainAxisSpacing: 16, 
                children: const [
                  CustomFeatureButton(
                   
                  ),
                  CustomFeatureButton(
                    
                  ),
                  CustomFeatureButton(
                   
                  ),
                  CustomFeatureButton(
                    
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
     
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
