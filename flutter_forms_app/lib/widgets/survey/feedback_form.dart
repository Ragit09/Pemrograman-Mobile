import 'package:flutter/material.dart';

class FeedbackForm extends StatefulWidget {
  final ValueChanged<String> onFeedbackChanged;
  final String initialFeedback;

  const FeedbackForm({
    Key? key,
    required this.onFeedbackChanged,
    required this.initialFeedback,
  }) : super(key: key);

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _feedbackController.text = widget.initialFeedback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback dan Saran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          'Silakan berikan feedback dan saran untuk pengembangan aplikasi ini:',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _feedbackController,
          decoration: InputDecoration(
            hintText: 'Tulis feedback Anda di sini...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          textAlignVertical: TextAlignVertical.top,
          onChanged: widget.onFeedbackChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}