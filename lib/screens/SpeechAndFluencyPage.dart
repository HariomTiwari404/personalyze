import 'package:flutter/material.dart';
import 'package:personlayze/constants/colors.dart';
import 'package:personlayze/widgets/CustomHeader.dart';
import 'package:personlayze/widgets/CustomOutputButton.dart';

class SpeechAndFluencyPage extends StatefulWidget {
  const SpeechAndFluencyPage({super.key});

  @override
  State<SpeechAndFluencyPage> createState() => _SpeechAndFluencyPageState();
}

class _SpeechAndFluencyPageState extends State<SpeechAndFluencyPage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomHeader(title: 'Speech and Fluency',),
            Container(
              height: MediaQuery.of(context).size.height*0.25,
        
            ),
            CustomOutputButton(title: "Input", subTitle: "Input will be diaplayed here", color: AppColors.inputButton),
            SizedBox(height: MediaQuery.of(context).size.height*0.05,),
            CustomOutputButton(title: "Output", subTitle: "Output will be diaplayed here", color: AppColors.outputButton)
          ],
        ),
      ),
    );
  }
}