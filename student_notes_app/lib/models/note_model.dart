class Note {
  int? id;
  String title;
  String description;
  DateTime createdAt;
  String category;
  bool isCompleted;

  Note({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}