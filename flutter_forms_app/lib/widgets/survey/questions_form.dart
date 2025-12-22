import 'package:flutter/material.dart';

class SurveyQuestionsForm extends StatefulWidget { // GANTI NAMA CLASS
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final Map<String, dynamic> initialData;

  const SurveyQuestionsForm({
    Key? key,
    required this.onDataChanged,
    required this.initialData,
  }) : super(key: key);

  @override
  _SurveyQuestionsFormState createState() => _SurveyQuestionsFormState();
}

class _SurveyQuestionsFormState extends State<SurveyQuestionsForm> {
  String? _selectedRadio1;
  List<String> _selectedCheckboxes = [];

  @override
  void initState() {
    super.initState();
    _selectedRadio1 = widget.initialData['radio1'];
    _selectedCheckboxes = List<String>.from(widget.initialData['checkboxes'] ?? []);
  }

  void _updateData() {
    widget.onDataChanged({
      'radio1': _selectedRadio1,
      'checkboxes': _selectedCheckboxes,
    });
  }

  void _onCheckboxChanged(String value, bool isChecked) {
    setState(() {
      if (isChecked) {
        _selectedCheckboxes.add(value);
      } else {
        _selectedCheckboxes.remove(value);
      }
    });
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pertanyaan Survey',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        // Radio Question 1
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Seberapa sering Anda menggunakan aplikasi mobile?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  children: [
                    _buildRadioOption('Sangat sering', 'sangat_sering'),
                    _buildRadioOption('Sering', 'sering'),
                    _buildRadioOption('Kadang-kadang', 'kadang'),
                    _buildRadioOption('Jarang', 'jarang'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Checkbox Question
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Fitur apa yang paling Anda sukai? (Bisa pilih lebih dari satu)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  children: [
                    _buildCheckboxOption('User Interface yang menarik', 'ui'),
                    _buildCheckboxOption('Kecepatan akses', 'speed'),
                    _buildCheckboxOption('Fitur yang lengkap', 'features'),
                    _buildCheckboxOption('Kemudahan penggunaan', 'usability'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedRadio1,
      onChanged: (String? newValue) {
        setState(() {
          _selectedRadio1 = newValue;
        });
        _updateData();
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCheckboxOption(String label, String value) {
    return CheckboxListTile(
      title: Text(label),
      value: _selectedCheckboxes.contains(value),
      onChanged: (bool? isChecked) {
        _onCheckboxChanged(value, isChecked!);
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}