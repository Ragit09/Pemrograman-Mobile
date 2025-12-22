import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import di sini saja
import '../models/todo.dart';

class StorageService {
  static const String _todosKey = 'todos';

  Future<List<Todo>> loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosString = prefs.getString(_todosKey);
      
      if (todosString == null || todosString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(todosString);
      final List<Todo> todos = [];
      
      for (var item in jsonList) {
        try {
          if (item is Map<String, dynamic>) {
            final todo = Todo.fromJson(item);
            todos.add(todo);
          }
        } catch (e) {
          print('Error parsing todo item: $e');
          continue;
        }
      }
      
      return todos;
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }

  Future<bool> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = 
          todos.map((todo) => todo.toJson()).toList();
      final String encodedData = json.encode(jsonList);
      return await prefs.setString(_todosKey, encodedData);
    } catch (e) {
      print('Error saving todos: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_todosKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Method untuk mendapatkan jumlah todo
  Future<int> getTodoCount() async {
    final todos = await loadTodos();
    return todos.length;
  }

  // Method untuk testing
  Future<void> testStorage() async {
    final testTodo = Todo(
      id: 'test-1',
      title: 'Test Todo',
      description: 'This is a test todo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await saveTodos([testTodo]);
    final loadedTodos = await loadTodos();
    
    print('Storage Test: ${loadedTodos.length} todos loaded');
    if (loadedTodos.isNotEmpty) {
      print('First todo: ${loadedTodos.first.title}');
    }
  }
}