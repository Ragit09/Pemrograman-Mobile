import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class RespondentDataForm extends StatefulWidget { // GANTI NAMA CLASS
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final Map<String, dynamic> initialData;

  const RespondentDataForm({
    Key? key,
    required this.onDataChanged,
    required this.initialData,
  }) : super(key: key);

  @override
  _RespondentDataFormState createState() => _RespondentDataFormState();
}

class _RespondentDataFormState extends State<RespondentDataForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedOccupation = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialData['name'] ?? '';
    _ageController.text = widget.initialData['age']?.toString() ?? '';
    _selectedOccupation = widget.initialData['occupation'] ?? '';
  }

  void _updateData() {
    widget.onDataChanged({
      'name': _nameController.text,
      'age': _ageController.text.isNotEmpty ? int.parse(_ageController.text) : 0,
      'occupation': _selectedOccupation,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Responden',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nama Lengkap',
            border: OutlineInputBorder(),
          ),
          validator: (value) => Validators.validateRequired(value, 'Nama lengkap'),
          onChanged: (value) => _updateData(),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: 'Umur',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Umur harus diisi';
            }
            if (int.tryParse(value) == null) {
              return 'Umur harus berupa angka';
            }
            return null;
          },
          onChanged: (value) => _updateData(),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedOccupation.isNotEmpty ? _selectedOccupation : null,
          decoration: InputDecoration(
            labelText: 'Pekerjaan',
            border: OutlineInputBorder(),
          ),
          items: [
            'Pelajar/Mahasiswa',
            'Pegawai Swasta',
            'PNS',
            'Wiraswasta',
            'Lainnya',
          ].map((String occupation) {
            return DropdownMenuItem<String>(
              value: occupation,
              child: Text(occupation),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedOccupation = newValue!;
            });
            _updateData();
          },
          validator: (value) => value == null ? 'Pekerjaan harus dipilih' : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}