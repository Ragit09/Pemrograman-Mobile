import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/category_filter.dart';
import '../services/shared_preferences_service.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';
import '../utils/theme_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final loadedNotes = await SharedPreferencesService.getNotes();
    setState(() {
      notes = loadedNotes;
    });
  }

  Future<void> _saveNotes() async {
    await SharedPreferencesService.saveNotes(notes);
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(),
      ),
    );
    
    if (result != null && result is Note) {
      setState(() {
        notes.add(result);
      });
      _saveNotes();
    }
  }

  void _editNote(Note note) async {
    final index = notes.indexOf(note);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
      ),
    );
    
    if (result != null && result is Note) {
      setState(() {
        notes[index] = result;
      });
      _saveNotes();
    }
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notes.remove(note);
              });
              _saveNotes();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Note> get filteredNotes {
    if (selectedCategory == null) {
      return notes;
    }
    return notes.where((note) => note.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Tugas Mahasiswa'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: ThemeManager.isDarkMode,
              builder: (context, isDark, child) {
                return Icon(isDark ? Icons.light_mode : Icons.dark_mode);
              },
            ),
            onPressed: ThemeManager.toggleDarkMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CategoryFilter(
              selectedCategory: selectedCategory,
              onChanged: (category) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada catatan\nTekan + untuk menambahkan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailScreen(
                                note: note,
                                onEdit: () => _editNote(note),
                              ),
                            ),
                          );
                        },
                        onDelete: () => _deleteNote(note),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}