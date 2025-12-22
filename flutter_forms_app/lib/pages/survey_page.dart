import 'package:flutter/material.dart';
import '../widgets/survey/progress_indicator.dart';
import '../widgets/survey/respondent_form.dart';
import '../widgets/survey/questions_form.dart';
import '../widgets/survey/feedback_form.dart';
import '../models/survey_model.dart';
import '../services/shared_preferences_service.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  
  late Survey _survey;
  final Map<String, dynamic> _step1Data = {};
  final Map<String, dynamic> _step2Data = {};

  final GlobalKey<FormState> _step1FormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _step2FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _survey = Survey(); // Inisialisasi survey
  }

  void _goToNextStep() {
    if (_currentStep == 1) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
      }
    } else if (_currentStep == 2) {
      setState(() {
        _currentStep++;
      });
    } else if (_currentStep == 3) {
      _submitSurvey();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _updateStep1Data(Map<String, dynamic> data) {
    _step1Data.addAll(data);
    setState(() {
      _survey.respondentName = data['name'] ?? '';
      _survey.age = data['age'] ?? 0;
      _survey.occupation = data['occupation'] ?? '';
    });
  }

  void _updateStep2Data(Map<String, dynamic> data) {
    _step2Data.addAll(data);
    
    // GUNAKAN METHOD BARU UNTUK UPDATE DENGAN AMAN
    _survey.updateRadioAnswer('usage_frequency', data['radio1'] ?? '');
    
    final List<String> checkboxes = List<String>.from(data['checkboxes'] ?? []);
    _survey.updateCheckboxAnswer('preferred_features', checkboxes);
    
    // Trigger rebuild
    setState(() {});
  }

  void _updateStep3Data(String feedback) {
    setState(() {
      _survey.feedback = feedback;
    });
  }

  void _submitSurvey() async {
    try {
      // Convert survey to simple map untuk SharedPreferences
      final surveyMap = {
        'respondentName': _survey.respondentName,
        'age': _survey.age,
        'occupation': _survey.occupation,
        'feedback': _survey.feedback,
      };
      
      await SharedPreferencesService.saveUserData(surveyMap);

      _showSummaryDialog();
    } catch (e) {
      print('Error saving survey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error menyimpan survey')),
      );
    }
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Survey Selesai!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Terima kasih telah mengisi survey.'),
                const SizedBox(height: 16),
                const Text(
                  'Ringkasan Jawaban:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Nama: ${_survey.respondentName}'),
                Text('Umur: ${_survey.age}'),
                Text('Pekerjaan: ${_survey.occupation}'),
                const SizedBox(height: 8),
                Text('Frekuensi penggunaan: ${_getRadioAnswerText(_survey.radioAnswers['usage_frequency'] ?? '')}'),
                const SizedBox(height: 8),
                Text('Fitur yang disukai: ${_getCheckboxAnswerText(_survey.checkboxAnswers['preferred_features'] ?? [])}'),
                const SizedBox(height: 8),
                Text('Feedback: ${_survey.feedback.isNotEmpty ? _survey.feedback : 'Tidak ada'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  String _getRadioAnswerText(String value) {
    switch (value) {
      case 'sangat_sering':
        return 'Sangat sering';
      case 'sering':
        return 'Sering';
      case 'kadang':
        return 'Kadang-kadang';
      case 'jarang':
        return 'Jarang';
      default:
        return 'Tidak diisi';
    }
  }

  String _getCheckboxAnswerText(List<String> values) {
    if (values.isEmpty) return 'Tidak ada';
    
    List<String> texts = [];
    for (var value in values) {
      switch (value) {
        case 'ui':
          texts.add('User Interface');
          break;
        case 'speed':
          texts.add('Kecepatan akses');
          break;
        case 'features':
          texts.add('Fitur lengkap');
          break;
        case 'usability':
          texts.add('Kemudahan penggunaan');
          break;
      }
    }
    return texts.join(', ');
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Form(
          key: _step1FormKey,
          child: RespondentDataForm(
            onDataChanged: _updateStep1Data,
            initialData: _step1Data,
          ),
        );
      case 2:
        return Form(
          key: _step2FormKey,
          child: SurveyQuestionsForm(
            onDataChanged: _updateStep2Data,
            initialData: _step2Data,
          ),
        );
      case 3:
        return FeedbackForm(
          onFeedbackChanged: _updateStep3Data,
          initialFeedback: _survey.feedback,
        );
      default:
        return Container();
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 1:
      case 2:
        return 'Lanjut';
      case 3:
        return 'Selesai';
      default:
        return 'Lanjut';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SurveyProgressIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildStepContent(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 1)
                  ElevatedButton(
                    onPressed: _goToPreviousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Kembali'),
                  )
                else
                  Container(),
                ElevatedButton(
                  onPressed: _goToNextStep,
                  child: Text(_getButtonText()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}