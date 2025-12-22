import 'package:flutter/material.dart';

class DatePickerField extends StatefulWidget {
  final ValueChanged<DateTime?> onDateSelected;
  final DateTime? initialDate;

  const DatePickerField({
    Key? key,
    required this.onDateSelected,
    this.initialDate,
  }) : super(key: key);

  @override
  _DatePickerFieldState createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = _formatDate(_selectedDate!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = _formatDate(picked);
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal Lahir',
        prefixIcon: Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_month),
          onPressed: _selectDate,
        ),
        border: OutlineInputBorder(),
      ),
      onTap: _selectDate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}