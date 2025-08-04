import 'package:flutter/material.dart';

class Character {
  final String id;
  final String name;
  final String description;
  final String role; // protagonist, antagonist, supporting, etc.
  final String appearance;
  final String personality;
  final String backstory;
  final Color characterColor;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<String> mangaIds; // Mangas this character appears in

  Character({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    this.appearance = '',
    this.personality = '',
    this.backstory = '',
    this.characterColor = const Color(0xFF667eea),
    required this.createdAt,
    required this.lastModified,
    this.mangaIds = const [],
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'role': role,
      'appearance': appearance,
      'personality': personality,
      'backstory': backstory,
      'characterColor': characterColor.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'mangaIds': mangaIds,
    };
  }

  // Create from Map
  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      role: map['role'] ?? 'supporting',
      appearance: map['appearance'] ?? '',
      personality: map['personality'] ?? '',
      backstory: map['backstory'] ?? '',
      characterColor: Color(map['characterColor'] ?? 0xFF667eea),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified'] ?? 0),
      mangaIds: List<String>.from(map['mangaIds'] ?? []),
    );
  }

  // Copy with new values
  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? role,
    String? appearance,
    String? personality,
    String? backstory,
    Color? characterColor,
    DateTime? createdAt,
    DateTime? lastModified,
    List<String>? mangaIds,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      backstory: backstory ?? this.backstory,
      characterColor: characterColor ?? this.characterColor,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      mangaIds: mangaIds ?? this.mangaIds,
    );
  }

  // Get character initials for avatar
  String get initials {
    if (name.trim().isEmpty) return 'C';
    final names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return (names[0].substring(0, 1) + names[1].substring(0, 1)).toUpperCase();
  }

  // Check if character appears in specific manga
  bool appearsInManga(String mangaId) {
    return mangaIds.contains(mangaId);
  }

  @override
  String toString() {
    return 'Character{id: $id, name: $name, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Character && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Static list of available roles
  static const List<String> availableRoles = [
    'protagonist',
    'antagonist',
    'supporting',
    'comic_relief',
    'mentor',
    'love_interest',
    'villain',
    'anti_hero',
    'side_character',
  ];

  // Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'protagonist':
        return 'Nhân vật chính';
      case 'antagonist':
        return 'Phản diện';
      case 'supporting':
        return 'Nhân vật phụ';
      case 'comic_relief':
        return 'Nhân vật hài';
      case 'mentor':
        return 'Thầy/Cô';
      case 'love_interest':
        return 'Tình nhân';
      case 'villain':
        return 'Kẻ ác';
      case 'anti_hero':
        return 'Phản anh hùng';
      case 'side_character':
        return 'Nhân vật phụ';
      default:
        return 'Khác';
    }
  }
}