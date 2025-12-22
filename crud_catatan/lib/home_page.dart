import 'package:flutter/material.dart';
import 'add_edit_page.dart';
import 'note.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> notes = [];
  String selectedCategory = 'Semua';
  final List<String> categories = [
    'Semua',
    'Kuliah',
    'Organisasi',
    'Pribadi',
    'Lain-lain'
  ];

  @override
  void initState() {
    super.initState();
    // Data dummy untuk testing
    notes = [
      Note(
        id: '1',
        title: 'Tugas Matematika',
        description: 'Mengerjakan soal kalkulus bab integral',
        category: 'Kuliah',
        createdDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Note(
        id: '2',
        title: 'Rapat Organisasi',
        description: 'Rapat persiapan acara tahunan',
        category: 'Organisasi',
        createdDate: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Note> filteredNotes = selectedCategory == 'Semua'
        ? notes
        : notes.where((note) => note.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Catatan Tugas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              _showCategoryFilter();
            },
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Kategori',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: selectedCategory == category 
                            ? Colors.blue[700] 
                            : Colors.grey[700],
                        fontWeight: selectedCategory == category 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // List Catatan
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada catatan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tekan tombol + untuk menambahkan catatan baru',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return _buildNoteCard(note);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPage(),
            ),
          );
          if (result != null && result is Note) {
            setState(() {
              notes.add(result);
              notes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
            });
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Catatan Baru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditPage(note: note),
              ),
            );
            if (result != null && result is Note) {
              setState(() {
                final index = notes.indexWhere((n) => n.id == note.id);
                if (index != -1) {
                  notes[index] = result;
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: note.categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        note.categoryIcon,
                        color: note.categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                note.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: note.categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                note.formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showDeleteDialog(note.id);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.grey[500],
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map((category) {
                return ListTile(
                  leading: Icon(
                    category == 'Semua' 
                        ? Icons.all_inclusive 
                        : Note(
                            id: '',
                            title: '',
                            description: '',
                            category: category,
                            createdDate: DateTime.now(),
                          ).categoryIcon,
                    color: category == 'Semua'
                        ? Colors.blue
                        : Note(
                            id: '',
                            title: '',
                            description: '',
                            category: category,
                            createdDate: DateTime.now(),
                          ).categoryColor,
                  ),
                  title: Text(category),
                  trailing: selectedCategory == category
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                notes.removeWhere((note) => note.id == id);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}