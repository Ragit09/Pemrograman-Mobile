import 'package:flutter/material.dart';
import 'models/feedback_model.dart';
import 'result_page.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final FeedbackModel _feedback = FeedbackModel();

  final List<String> _prodiList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Teknik Elektro',
    'Teknik Mesin',
    'Manajemen',
    'Akuntansi',
    'Hukum',
    'Kedokteran',
    'Psikologi',
    'Lainnya'
  ];

  int _kepuasanUmum = 0;
  int _kepuasanPerpustakaan = 0;
  int _kepuasanLaboratorium = 0;
  int _kepuasanKantin = 0;
  int _kepuasanAdministrasi = 0;

  final Map<int, String> _ratingLabels = {
    1: 'Sangat Tidak Puas',
    2: 'Tidak Puas',
    3: 'Cukup Puas',
    4: 'Puas',
    5: 'Sangat Puas',
  };

  final Map<int, Color> _ratingColors = {
    1: Colors.red,
    2: Colors.orange,
    3: Colors.yellow,
    4: Colors.lightGreen,
    5: Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuesioner Kepuasan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Bantuan',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 20),
                    _buildRatingSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Isi semua bagian untuk melanjutkan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 20, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Diri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nama Mahasiswa (opsional)',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'Masukkan nama Anda',
              ),
              onSaved: (value) => _feedback.nama = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Program Studi *',
                prefixIcon: Icon(Icons.school_outlined),
                hintText: 'Pilih program studi Anda',
              ),
              items: _prodiList.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _feedback.prodi = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harap pilih program studi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_outline, size: 20, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Penilaian Kepuasan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Berikan penilaian Anda dengan skala 1-5:',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 5),
            const Text(
              '1 = Sangat Tidak Puas, 5 = Sangat Puas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildRatingQuestion(
              'Kepuasan Umum terhadap Kampus',
              Icons.account_balance_outlined,
              _kepuasanUmum,
              (value) => setState(() => _kepuasanUmum = value),
            ),
            _buildRatingQuestion(
              'Fasilitas Perpustakaan',
              Icons.library_books_outlined,
              _kepuasanPerpustakaan,
              (value) => setState(() => _kepuasanPerpustakaan = value),
            ),
            _buildRatingQuestion(
              'Fasilitas Laboratorium',
              Icons.science_outlined,
              _kepuasanLaboratorium,
              (value) => setState(() => _kepuasanLaboratorium = value),
            ),
            _buildRatingQuestion(
              'Fasilitas Kantin',
              Icons.restaurant_outlined,
              _kepuasanKantin,
              (value) => setState(() => _kepuasanKantin = value),
            ),
            _buildRatingQuestion(
              'Layanan Administrasi',
              Icons.assignment_outlined,
              _kepuasanAdministrasi,
              (value) => setState(() => _kepuasanAdministrasi = value),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Saran dan Komentar (opsional)',
                prefixIcon: Icon(Icons.chat_outlined),
                alignLabelWithHint: true,
                hintText: 'Masukkan saran atau kritik konstruktif...',
              ),
              maxLines: 4,
              onSaved: (value) => _feedback.saran = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingQuestion(
    String question,
    IconData icon,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildRatingButton(rating, currentRating, onRatingChanged),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          if (currentRating > 0)
            Text(
              _ratingLabels[currentRating]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ratingColors[currentRating],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(int rating, int currentRating, Function(int) onRatingChanged) {
    final isSelected = currentRating == rating;
    return GestureDetector(
      onTap: () => onRatingChanged(rating),
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? _ratingColors[rating] : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _ratingColors[rating]! : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              rating.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            Icon(
              Icons.circle,
              size: 6,
              color: isSelected ? Colors.white : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final isFormValid = _kepuasanUmum > 0 &&
        _kepuasanPerpustakaan > 0 &&
        _kepuasanLaboratorium > 0 &&
        _kepuasanKantin > 0 &&
        _kepuasanAdministrasi > 0 &&
        _feedback.prodi != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'KEMBALI',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFormValid ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: isFormValid ? _submitForm : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SELESAI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      _feedback.kepuasanUmum = _kepuasanUmum;
      _feedback.kepuasanPerpustakaan = _kepuasanPerpustakaan;
      _feedback.kepuasanLaboratorium = _kepuasanLaboratorium;
      _feedback.kepuasanKantin = _kepuasanKantin;
      _feedback.kepuasanAdministrasi = _kepuasanAdministrasi;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(feedback: _feedback),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Bantuan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Petunjuk Pengisian:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Pilih program studi Anda'),
            Text('• Beri rating 1-5 untuk setiap aspek'),
            Text('• 1 = Sangat Tidak Puas'),
            Text('• 5 = Sangat Puas'),
            Text('• Saran bersifat opsional'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MENGERTI'),
          ),
        ],
      ),
    );
  }
}