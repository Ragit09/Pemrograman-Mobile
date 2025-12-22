import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class SharedPreferencesService {
  static const String _notesKey = 'student_notes';
  static const String _darkModeKey = 'is_dark_mode';

  static Future<void> saveNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = jsonEncode(notes.map((note) => note.toMap()).toList());
      await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  static Future<List<Note>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson != null && notesJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(notesJson);
        return jsonList.map((json) => Note.fromMap(json)).toList();
      }
    } catch (e) {
      print('Error loading notes: $e');
    }
    
    return [];
  }

  static Future<void> saveDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, isDark);
    } catch (e) {
      print('Error saving dark mode: $e');
    }
  }

  static Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (e) {
      print('Error loading dark mode: $e');
      return false;
    }
  }
}