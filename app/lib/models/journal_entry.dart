// journal_entry.dart
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final List<String> imagePaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePaths': imagePaths,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imagePaths: List<String>.from(json['imagePaths']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }

  // Copy with method for updates
  JournalEntry copyWith({
    String? title,
    String? content,
    List<String>? imagePaths,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}