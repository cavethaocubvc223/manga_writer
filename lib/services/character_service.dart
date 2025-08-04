import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

class CharacterService {
  static const String _characterListKey = 'character_list';
  static const List<Color> _defaultColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF667eea),
    Color(0xFFFFE66D),
    Color(0xFF44A08D),
    Color(0xFF764ba2),
    Color(0xFFFF8E53),
    Color(0xFF6C5CE7),
    Color(0xFFA8E6CF),
    Color(0xFFFFB6C1),
  ];

  // Get all characters
  static Future<List<Character>> getAllCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? characterListJson = prefs.getString(_characterListKey);
      
      if (characterListJson == null) {
        return _getDefaultCharacters();
      }

      final List<dynamic> characterListMap = jsonDecode(characterListJson);
      return characterListMap.map((map) => Character.fromMap(map)).toList();
    } catch (e) {
      print('Error loading characters: $e');
      return _getDefaultCharacters();
    }
  }

  // Save all characters
  static Future<bool> _saveCharacterList(List<Character> characterList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> characterListMap = 
          characterList.map((character) => character.toMap()).toList();
      final String characterListJson = jsonEncode(characterListMap);
      
      return await prefs.setString(_characterListKey, characterListJson);
    } catch (e) {
      print('Error saving character list: $e');
      return false;
    }
  }

  // Add new character
  static Future<bool> addCharacter({
    required String name,
    required String description,
    required String role,
    String appearance = '',
    String personality = '',
    String backstory = '',
    Color? characterColor,
    List<String>? mangaIds,
  }) async {
    try {
      final characterList = await getAllCharacters();
      final now = DateTime.now();
      
      final newCharacter = Character(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        role: role,
        appearance: appearance,
        personality: personality,
        backstory: backstory,
        characterColor: characterColor ?? _getRandomColor(),
        createdAt: now,
        lastModified: now,
        mangaIds: mangaIds ?? [],
      );

      characterList.add(newCharacter);
      return await _saveCharacterList(characterList);
    } catch (e) {
      print('Error adding character: $e');
      return false;
    }
  }

  // Update character
  static Future<bool> updateCharacter(Character updatedCharacter) async {
    try {
      final characterList = await getAllCharacters();
      final index = characterList.indexWhere((character) => character.id == updatedCharacter.id);
      
      if (index == -1) return false;

      characterList[index] = updatedCharacter.copyWith(
        lastModified: DateTime.now(),
      );
      
      return await _saveCharacterList(characterList);
    } catch (e) {
      print('Error updating character: $e');
      return false;
    }
  }

  // Delete character
  static Future<bool> deleteCharacter(String characterId) async {
    try {
      final characterList = await getAllCharacters();
      characterList.removeWhere((character) => character.id == characterId);
      
      return await _saveCharacterList(characterList);
    } catch (e) {
      print('Error deleting character: $e');
      return false;
    }
  }

  // Get character by ID
  static Future<Character?> getCharacterById(String id) async {
    try {
      final characterList = await getAllCharacters();
      return characterList.firstWhere(
        (character) => character.id == id,
        orElse: () => throw Exception('Character not found'),
      );
    } catch (e) {
      print('Error getting character by ID: $e');
      return null;
    }
  }

  // Get characters by manga ID
  static Future<List<Character>> getCharactersByMangaId(String mangaId) async {
    try {
      final characterList = await getAllCharacters();
      return characterList.where((character) => 
          character.appearsInManga(mangaId)).toList();
    } catch (e) {
      print('Error getting characters by manga ID: $e');
      return [];
    }
  }

  // Get characters by role
  static Future<List<Character>> getCharactersByRole(String role) async {
    try {
      final characterList = await getAllCharacters();
      return characterList.where((character) => 
          character.role == role).toList();
    } catch (e) {
      print('Error getting characters by role: $e');
      return [];
    }
  }

  // Search characters
  static Future<List<Character>> searchCharacters(String query) async {
    try {
      final characterList = await getAllCharacters();
      final lowercaseQuery = query.toLowerCase();
      
      return characterList.where((character) {
        return character.name.toLowerCase().contains(lowercaseQuery) ||
            character.description.toLowerCase().contains(lowercaseQuery) ||
            character.role.toLowerCase().contains(lowercaseQuery) ||
            character.personality.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching characters: $e');
      return [];
    }
  }

  // Add character to manga
  static Future<bool> addCharacterToManga(String characterId, String mangaId) async {
    try {
      final character = await getCharacterById(characterId);
      if (character == null) return false;

      final updatedMangaIds = List<String>.from(character.mangaIds);
      if (!updatedMangaIds.contains(mangaId)) {
        updatedMangaIds.add(mangaId);
      }

      return await updateCharacter(character.copyWith(mangaIds: updatedMangaIds));
    } catch (e) {
      print('Error adding character to manga: $e');
      return false;
    }
  }

  // Remove character from manga
  static Future<bool> removeCharacterFromManga(String characterId, String mangaId) async {
    try {
      final character = await getCharacterById(characterId);
      if (character == null) return false;

      final updatedMangaIds = List<String>.from(character.mangaIds);
      updatedMangaIds.remove(mangaId);

      return await updateCharacter(character.copyWith(mangaIds: updatedMangaIds));
    } catch (e) {
      print('Error removing character from manga: $e');
      return false;
    }
  }

  // Clear all characters
  static Future<bool> clearAllCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_characterListKey);
    } catch (e) {
      print('Error clearing characters: $e');
      return false;
    }
  }

  // Get character count by role
  static Future<Map<String, int>> getCharacterCountByRole() async {
    try {
      final characterList = await getAllCharacters();
      final Map<String, int> roleCounts = {};
      
      for (final role in Character.availableRoles) {
        roleCounts[role] = 0;
      }
      
      for (final character in characterList) {
        roleCounts[character.role] = (roleCounts[character.role] ?? 0) + 1;
      }
      
      return roleCounts;
    } catch (e) {
      print('Error getting character count by role: $e');
      return {};
    }
  }

  // Get random color for new character
  static Color _getRandomColor() {
    final random = DateTime.now().millisecondsSinceEpoch % _defaultColors.length;
    return _defaultColors[random];
  }

  // Get available colors for selection
  static List<Color> getAvailableColors() {
    return List.from(_defaultColors);
  }

  // Get default characters data
  static List<Character> _getDefaultCharacters() {
    final now = DateTime.now();
    return [
      Character(
        id: '1',
        name: 'Akira Tanaka',
        description: 'Nhân vật chính với khả năng đặc biệt',
        role: 'protagonist',
        appearance: 'Tóc đen, mắt xanh, cao 170cm',
        personality: 'Dũng cảm, tốt bụng, có chút bướng bỉnh',
        backstory: 'Một học sinh bình thường cho đến khi khám phá ra sức mạnh ẩn giấu',
        characterColor: const Color(0xFFFF6B6B),
        createdAt: now.subtract(const Duration(days: 1)),
        lastModified: now.subtract(const Duration(days: 1)),
        mangaIds: ['1'],
      ),
      Character(
        id: '2',
        name: 'Yuki Sato',
        description: 'Bạn thân của nhân vật chính',
        role: 'supporting',
        appearance: 'Tóc nâu, mắt nâu, thấp hơn Akira',
        personality: 'Thông minh, tính cách điềm tĩnh, luôn hỗ trợ bạn bè',
        backstory: 'Đến từ gia đình trí thức, am hiểu về ma thuật cổ',
        characterColor: const Color(0xFF4ECDC4),
        createdAt: now.subtract(const Duration(days: 2)),
        lastModified: now.subtract(const Duration(days: 2)),
        mangaIds: ['1'],
      ),
      Character(
        id: '3',
        name: 'Kage no Senshi',
        description: 'Kẻ thù bí ẩn của nhân vật chính',
        role: 'antagonist',
        appearance: 'Luôn che mặt bằng mặt nạ đen',
        personality: 'Lạnh lùng, tính toán, có mục đích riêng',
        backstory: 'Quá khứ bí ẩn, có mối liên hệ với gia đình Akira',
        characterColor: const Color(0xFF667eea),
        createdAt: now.subtract(const Duration(days: 3)),
        lastModified: now.subtract(const Duration(days: 3)),
        mangaIds: ['1', '2'],
      ),
    ];
  }
}