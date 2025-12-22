import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GenderDropdown extends StatefulWidget {
  final ValueChanged<String> onGenderChanged;
  final String initialValue;

  const GenderDropdown({
    Key? key,
    required this.onGenderChanged,
    this.initialValue = 'Laki-laki',
  }) : super(key: key);

  @override
  _GenderDropdownState createState() => _GenderDropdownState();
}

class _GenderDropdownState extends State<GenderDropdown> {
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Jenis Kelamin',
        border: OutlineInputBorder(),
      ),
      items: AppConstants.genders.map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue!;
        });
        widget.onGenderChanged(newValue!);
      },
    );
  }
}