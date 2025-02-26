import 'package:flutter/material.dart';
import 'package:personlayze/screens/DetailedAnalysisPage.dart';
import 'package:personlayze/widgets/CustomHeader.dart';
import 'package:personlayze/widgets/CustomOutputButton.dart';

class LiveAnalysisPage extends StatefulWidget {
  const LiveAnalysisPage({super.key});

  @override
  State<LiveAnalysisPage> createState() => _LiveAnalysisPageState();
}

class _LiveAnalysisPageState extends State<LiveAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomHeader(title: "Live A.I Analysis",),
            Container(
              height: MediaQuery.of(context).size.height*0.55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(16)
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height*0.07,
              width: MediaQuery.of(context).size.width*0.25,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(16)
              ),
            ),
            CustomOutputButton(),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>DetailedAnalysisPage()));
              },
              child: Container(
                height: MediaQuery.of(context).size.height*0.07,
                width: MediaQuery.of(context).size.width*0.25,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(16)
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}