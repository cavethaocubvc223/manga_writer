import 'package:flutter/material.dart';

class Manga {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime lastModified;
  final Color color;
  final int pages;

  Manga({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.lastModified,
    required this.color,
    this.pages = 0,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'color': color.value,
      'pages': pages,
    };
  }

  // Create from Map
  factory Manga.fromMap(Map<String, dynamic> map) {
    return Manga(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified'] ?? 0),
      color: Color(map['color'] ?? 0xFFFF6B6B),
      pages: map['pages'] ?? 0,
    );
  }

  // Copy with new values
  Manga copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? lastModified,
    Color? color,
    int? pages,
  }) {
    return Manga(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      color: color ?? this.color,
      pages: pages ?? this.pages,
    );
  }

  @override
  String toString() {
    return 'Manga{id: $id, title: $title, description: $description}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manga && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 