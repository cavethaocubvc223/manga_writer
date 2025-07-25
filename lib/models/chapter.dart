

class Chapter {
  final String id;
  final String mangaId;
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isPublished;
  final int wordCount;

  Chapter({
    required this.id,
    required this.mangaId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.lastModified,
    this.isPublished = false,
    int? wordCount,
  }) : wordCount = wordCount ?? _calculateWordCount(content);

  static int _calculateWordCount(String content) {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mangaId': mangaId,
      'chapterNumber': chapterNumber,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'isPublished': isPublished,
      'wordCount': wordCount,
    };
  }

  // Create from Map
  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] ?? '',
      mangaId: map['mangaId'] ?? '',
      chapterNumber: map['chapterNumber'] ?? 1,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified'] ?? 0),
      isPublished: map['isPublished'] ?? false,
      wordCount: map['wordCount'] ?? 0,
    );
  }

  // Copy with new values
  Chapter copyWith({
    String? id,
    String? mangaId,
    int? chapterNumber,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isPublished,
    int? wordCount,
  }) {
    final newContent = content ?? this.content;
    return Chapter(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      content: newContent,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isPublished: isPublished ?? this.isPublished,
      wordCount: wordCount ?? _calculateWordCount(newContent),
    );
  }

  // Get reading time estimation (words per minute)
  int get estimatedReadingTime {
    const wordsPerMinute = 200; // Average reading speed
    return (wordCount / wordsPerMinute).ceil();
  }

  // Get content preview
  String get contentPreview {
    if (content.isEmpty) return 'No content yet...';
    const maxLength = 150;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  @override
  String toString() {
    return 'Chapter{id: $id, mangaId: $mangaId, chapterNumber: $chapterNumber, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 