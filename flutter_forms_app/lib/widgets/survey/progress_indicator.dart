import 'package:flutter/material.dart';

class SurveyProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SurveyProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          'Step $currentStep dari $totalSteps',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}