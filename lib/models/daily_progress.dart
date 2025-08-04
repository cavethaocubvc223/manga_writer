class DailyProgress {
  final String id;
  final DateTime date;
  final int pagesWritten;
  final int chaptersCompleted;
  final int charactersCreated;
  final int timeSpentMinutes;
  final String notes;
  final double goalProgress; // 0.0 to 1.0
  final DateTime createdAt;
  final DateTime lastModified;

  DailyProgress({
    required this.id,
    required this.date,
    this.pagesWritten = 0,
    this.chaptersCompleted = 0,
    this.charactersCreated = 0,
    this.timeSpentMinutes = 0,
    this.notes = '',
    this.goalProgress = 0.0,
    required this.createdAt,
    required this.lastModified,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'pagesWritten': pagesWritten,
      'chaptersCompleted': chaptersCompleted,
      'charactersCreated': charactersCreated,
      'timeSpentMinutes': timeSpentMinutes,
      'notes': notes,
      'goalProgress': goalProgress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  // Create from Map
  factory DailyProgress.fromMap(Map<String, dynamic> map) {
    return DailyProgress(
      id: map['id'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      pagesWritten: map['pagesWritten'] ?? 0,
      chaptersCompleted: map['chaptersCompleted'] ?? 0,
      charactersCreated: map['charactersCreated'] ?? 0,
      timeSpentMinutes: map['timeSpentMinutes'] ?? 0,
      notes: map['notes'] ?? '',
      goalProgress: (map['goalProgress'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified'] ?? 0),
    );
  }

  // Copy with new values
  DailyProgress copyWith({
    String? id,
    DateTime? date,
    int? pagesWritten,
    int? chaptersCompleted,
    int? charactersCreated,
    int? timeSpentMinutes,
    String? notes,
    double? goalProgress,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return DailyProgress(
      id: id ?? this.id,
      date: date ?? this.date,
      pagesWritten: pagesWritten ?? this.pagesWritten,
      chaptersCompleted: chaptersCompleted ?? this.chaptersCompleted,
      charactersCreated: charactersCreated ?? this.charactersCreated,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      notes: notes ?? this.notes,
      goalProgress: goalProgress ?? this.goalProgress,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // Get formatted date string
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Get formatted time spent
  String get formattedTimeSpent {
    final hours = timeSpentMinutes ~/ 60;
    final minutes = timeSpentMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Check if this is today's progress
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Get total activity score (for ranking days)
  int get totalActivityScore {
    return pagesWritten * 2 + 
           chaptersCompleted * 5 + 
           charactersCreated * 3 +
           (timeSpentMinutes ~/ 10); // 1 point per 10 minutes
  }

  // Get completion percentage for display
  int get goalProgressPercent {
    return (goalProgress * 100).round();
  }

  @override
  String toString() {
    return 'DailyProgress{date: $formattedDate, pages: $pagesWritten, chapters: $chaptersCompleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}