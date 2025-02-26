import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            DetailedOutputButton(),
             DetailedOutputButton(),
              DetailedOutputButton(),
          ],
        ),
      ),
    );
  }
}