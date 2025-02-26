import 'package:flutter/material.dart';
import 'package:personlayze/constants/colors.dart';
import 'package:personlayze/widgets/CustomHeader.dart';
import 'package:personlayze/widgets/DetailedOutputButton.dart';

class DetailedAnalysisPage extends StatefulWidget {
  const DetailedAnalysisPage({super.key});

  @override
  State<DetailedAnalysisPage> createState() => _DetailedAnalysisPageState();
}

class _DetailedAnalysisPageState extends State<DetailedAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              CustomHeader(
                title: "Detailed Analysis",
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.05,),
              DetailedOutputButton(
                color: AppColors.bodyLanguageButton,
                title: "Body Lannguage",
                subTitle: "Your posture is slightly sloughed. Try to sit up straight",
          
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.05,),
               DetailedOutputButton(
                color: AppColors.speechButton,
                title:" Speech and Fluency",
                subTitle: "Your posture is slightly sloughed. Try to sit up straight",
               ),
               SizedBox(height: MediaQuery.of(context).size.height*0.05,),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DetailedOutputButton(
                    color: AppColors.gesturesButton,
                    title: "Gestures",
                    subTitle: "Your posture is slightly sloughed. Try to sit up straight",
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}