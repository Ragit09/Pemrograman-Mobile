import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/todo.dart';
import 'services/storage_service.dart';
import 'widgets/todo_item.dart';
import 'widgets/filter_chip.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  TodoFilter _currentFilter = TodoFilter.all;
  Todo? _editingTodo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadTodos();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _storageService.loadTodos();
      // Sort by updatedAt descending (yang terbaru di atas)
      todos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _todos = todos;
        _applyFilter();
      });
    } catch (e) {
      print('Error loading todos: $e');
      _showErrorSnackBar('Error loading todos: $e');
    }
  }

  Future<void> _saveTodos() async {
    try {
      final success = await _storageService.saveTodos(_todos);
      if (!success) {
        _showErrorSnackBar('Failed to save todos');
      }
    } catch (e) {
      print('Error saving todos: $e');
      _showErrorSnackBar('Error saving todos: $e');
    }
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case TodoFilter.all:
        _filteredTodos = List.from(_todos);
        break;
      case TodoFilter.completed:
        _filteredTodos = _todos.where((todo) => todo.isCompleted).toList();
        break;
      case TodoFilter.pending:
        _filteredTodos = _todos.where((todo) => !todo.isCompleted).toList();
        break;
    }
  }

  void _addTodo() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorSnackBar('Judul todo tidak boleh kosong');
      return;
    }

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _todos.insert(0, newTodo);
      _applyFilter();
    });

    _saveTodos();
    _clearForm();
    Navigator.of(context).pop();
    _showSuccessSnackBar('Todo berhasil ditambahkan');
  }

  void _updateTodo() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _editingTodo == null) {
      _showErrorSnackBar('Judul todo tidak boleh kosong');
      return;
    }

    setState(() {
      _todos = _todos.map((todo) {
        if (todo.id == _editingTodo!.id) {
          return todo.copyWith(
            title: title,
            description: _descriptionController.text.trim(),
            updatedAt: DateTime.now(),
          );
        }
        return todo;
      }).toList();
      _applyFilter();
    });

    _saveTodos();
    _clearForm();
    Navigator.of(context).pop();
    _showSuccessSnackBar('Todo berhasil diupdate');
  }

  void _toggleTodo(String id) {
    setState(() {
      _todos = _todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(
            isCompleted: !todo.isCompleted,
            updatedAt: DateTime.now(),
          );
        }
        return todo;
      }).toList();
      _applyFilter();
    });
    _saveTodos();
  }

  void _deleteTodo(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Todo'),
        content: const Text('Apakah Anda yakin ingin menghapus todo ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _todos.removeWhere((todo) => todo.id == id);
                _applyFilter();
              });
              _saveTodos();
              Navigator.of(context).pop();
              _showSuccessSnackBar('Todo berhasil dihapus');
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog() {
    final isEditing = _editingTodo != null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Todo' : 'Tambah Todo Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Todo *',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan judul todo',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan deskripsi todo',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearForm();
                  Navigator.of(context).pop();
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isEditing ? _updateTodo : _addTodo,
                child: Text(isEditing ? 'Update' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editTodo(Todo todo) {
    setState(() {
      _editingTodo = todo;
      _titleController.text = todo.title;
      _descriptionController.text = todo.description;
    });
    _showAddEditDialog();
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _editingTodo = null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada todo',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + untuk menambahkan todo baru',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat todo...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_todos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Semua'),
                    content: const Text('Hapus semua todo? Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _todos.clear();
                            _applyFilter();
                          });
                          _saveTodos();
                          Navigator.of(context).pop();
                          _showSuccessSnackBar('Semua todo berhasil dihapus');
                        },
                        child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Hapus Semua Todo',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilterChipWidget(
                    currentFilter: _currentFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _currentFilter = filter;
                        _applyFilter();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredTodos.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = _filteredTodos[index];
                            return TodoItem(
                              todo: todo,
                              onToggle: () => _toggleTodo(todo.id),
                              onEdit: () => _editTodo(todo),
                              onDelete: () => _deleteTodo(todo.id),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showAddEditDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Todo Baru',
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}