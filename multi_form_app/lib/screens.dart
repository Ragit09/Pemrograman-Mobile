import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets.dart';

// ========== LOGIN SCREEN ==========
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    if (!value.contains('@')) return 'Email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.setBool('rememberMe', false);
    }
    
    setState(() => _isLoading = false);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Login', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    
                    CustomTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    CustomButton(
                      text: 'Login',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                          child: const Text('Profile'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SurveyScreen())),
                          child: const Text('Survey'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== PROFILE SCREEN ==========
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _birthDateController = TextEditingController();
  String _gender = 'Laki-laki';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _emailController.text = prefs.getString('email') ?? 'user@example.com';
      _phoneController.text = prefs.getString('phone') ?? '';
      _bioController.text = prefs.getString('bio') ?? '';
      _birthDateController.text = prefs.getString('birthDate') ?? '';
      _gender = prefs.getString('gender') ?? 'Laki-laki';
    });
  }



  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('phone', _phoneController.text);
    await prefs.setString('bio', _bioController.text);
    await prefs.setString('birthDate', _birthDateController.text);
    await prefs.setString('gender', _gender);
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100],
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              
              CustomTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
              ),
              
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                enabled: false,
              ),
              
              CustomTextField(
                label: 'Nomor Telepon',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              
              CustomTextField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
              ),
              
              // Date Picker
              DatePickerField(
                controller: _birthDateController,
                label: 'Tanggal Lahir',
              ),
              
              // Gender Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jenis Kelamin', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      items: const ['Laki-laki', 'Perempuan'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              
              CustomButton(
                text: 'Simpan',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                color: Colors.green,
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: const Text('Back to Login'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SurveyScreen())),
                    child: const Text('Go to Survey'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== SURVEY SCREEN ==========
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  final _feedbackController = TextEditingController();
  List<String> _answers = List.filled(3, '');
  bool _isLoading = false;

  List<Widget> get _steps => [
    _buildStep1(),
    _buildStep2(),
    _buildStep3(),
    _buildStep4(),
  ];

  Widget _buildStep1() {
    return Column(
      children: [
        CustomTextField(
          label: 'Nama',
          controller: _nameController,
        ),
        CustomTextField(
          label: 'Umur',
          controller: _ageController,
          keyboardType: TextInputType.number,
        ),
        CustomTextField(
          label: 'Pekerjaan',
          controller: _jobController,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildQuestion(0, 'Apa hobi Anda?', const ['Membaca', 'Olahraga', 'Musik', 'Traveling']),
        const SizedBox(height: 20),
        _buildQuestion(1, 'Aplikasi favorit?', const ['WhatsApp', 'Instagram', 'TikTok', 'YouTube']),
        const SizedBox(height: 20),
        _buildQuestion(2, 'Tingkat kepuasan?', const ['Sangat Puas', 'Puas', 'Cukup', 'Kurang']),
      ],
    );
  }

  Widget _buildQuestion(int index, String question, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map((option) => RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: _answers[index],
          onChanged: (value) => setState(() => _answers[index] = value!),
        )),
      ],
    );
  }

  Widget _buildStep3() {
    return CustomTextField(
      label: 'Feedback',
      controller: _feedbackController,
      maxLines: 5,
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan Survey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text('Nama: ${_nameController.text}'),
        Text('Umur: ${_ageController.text}'),
        Text('Pekerjaan: ${_jobController.text}'),
        const SizedBox(height: 20),
        const Text('Jawaban:', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._answers.asMap().entries.map((e) => Text('${e.key + 1}. ${e.value}')),
        const SizedBox(height: 20),
        Text('Feedback: ${_feedbackController.text}'),
      ],
    );
  }

  Future<void> _saveSurvey() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('survey_name', _nameController.text);
    await prefs.setString('survey_age', _ageController.text);
    await prefs.setString('survey_job', _jobController.text);
    await prefs.setStringList('survey_answers', _answers);
    await prefs.setString('survey_feedback', _feedbackController.text);
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_step + 1} of 4'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_step + 1) / 4,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
            ),
            const SizedBox(height: 30),
            
            // Step Content
            _steps[_step],
            
            const SizedBox(height: 30),
            
            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_step > 0)
                  ElevatedButton(
                    onPressed: () => setState(() => _step--),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(width: 100),
                
                if (_step < 3)
                  ElevatedButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('Next'),
                  )
                else
                  CustomButton(
                    text: 'Submit',
                    onPressed: _saveSurvey,
                    isLoading: _isLoading,
                    color: Colors.green,
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Navigation to other screens
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                  child: const Text('Back to Login'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                  child: const Text('Go to Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}