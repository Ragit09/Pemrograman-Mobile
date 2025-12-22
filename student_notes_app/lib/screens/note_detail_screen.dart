import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../widgets/category_icon.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  
  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: note.category, size: 32),
                const SizedBox(width: 12),
                Text(
                  note.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dibuat: ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                note.isCompleted ? 'Selesai' : 'Belum Selesai',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: note.isCompleted ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  note.description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}