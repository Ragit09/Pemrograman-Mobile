import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/shared_preferences_service.dart';
import '../utils/validators.dart';
import '../widgets/profile/date_picker_field.dart';
import '../widgets/profile/gender_dropdown.dart';
import 'survey_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user}); // CONST CONSTRUCTOR

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late User _user;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadProfileData();
  }

  void _loadProfileData() async {
    final userData = await SharedPreferencesService.getUserData();
    
    setState(() {
      _fullNameController.text = userData['fullName'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _user.gender = userData['gender'] ?? 'Laki-laki';
      
      // Handle birthDate
      if (userData['birthDate'] != null) {
        _user.birthDate = DateTime.parse(userData['birthDate']);
      }
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _user.fullName = _fullNameController.text;
      _user.phone = _phoneController.text;
      _user.bio = _bioController.text;

      await SharedPreferencesService.saveUserData(_user.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile berhasil disimpan!')), // CONST
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SurveyPage()), // CONST
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')), // CONST
      body: Padding(
        padding: const EdgeInsets.all(16.0), // CONST
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile Photo Placeholder
              const CircleAvatar( // CONST
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon( // CONST
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16), // CONST
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur upload foto belum tersedia')), // CONST
                    );
                  },
                  icon: const Icon(Icons.camera_alt), // CONST
                  label: const Text('Ubah Foto Profil'), // CONST
                ),
              ),
              const SizedBox(height: 16), // CONST
              
              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration( // CONST
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Nama lengkap'),
              ),
              const SizedBox(height: 16), // CONST
              
              // Email Field (read-only)
              TextFormField(
                initialValue: _user.email,
                decoration: const InputDecoration( // CONST
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16), // CONST
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration( // CONST
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16), // CONST
              
              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration( // CONST
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16), // CONST
              
              // Date Picker
              DatePickerField(
                initialDate: _user.birthDate,
                onDateSelected: (date) {
                  setState(() {
                    _user.birthDate = date;
                  });
                },
              ),
              const SizedBox(height: 16), // CONST
              
              // Gender Dropdown
              GenderDropdown(
                initialValue: _user.gender,
                onGenderChanged: (gender) {
                  setState(() {
                    _user.gender = gender;
                  });
                },
              ),
              const SizedBox(height: 24), // CONST
              
              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Simpan Profile'), // CONST
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // CONST
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}