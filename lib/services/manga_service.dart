import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga.dart';

class MangaService {
  static const String _mangaListKey = 'manga_list';
  static const List<Color> _defaultColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF667eea),
    Color(0xFFFFE66D),
    Color(0xFF44A08D),
    Color(0xFF764ba2),
    Color(0xFFFF8E53),
    Color(0xFF6C5CE7),
  ];

  // Get all manga
  static Future<List<Manga>> getAllManga() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? mangaListJson = prefs.getString(_mangaListKey);
      
      if (mangaListJson == null) {
        return [];
      }

      final List<dynamic> mangaListMap = jsonDecode(mangaListJson);
      return mangaListMap.map((map) => Manga.fromMap(map)).toList();
    } catch (e) {
      print('Error loading manga: $e');
      return [];
    }
  }

  // Save all manga
  static Future<bool> _saveMangaList(List<Manga> mangaList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> mangaListMap = 
          mangaList.map((manga) => manga.toMap()).toList();
      final String mangaListJson = jsonEncode(mangaListMap);
      
      return await prefs.setString(_mangaListKey, mangaListJson);
    } catch (e) {
      print('Error saving manga list: $e');
      return false;
    }
  }

  // Add new manga
  static Future<bool> addManga({
    required String title,
    required String description,
    Color? color,
  }) async {
    try {
      final mangaList = await getAllManga();
      final now = DateTime.now();
      
      final newManga = Manga(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        createdAt: now,
        lastModified: now,
        color: color ?? _getRandomColor(),
        pages: 0,
      );

      mangaList.add(newManga);
      return await _saveMangaList(mangaList);
    } catch (e) {
      print('Error adding manga: $e');
      return false;
    }
  }

  // Update manga
  static Future<bool> updateManga(Manga updatedManga) async {
    try {
      final mangaList = await getAllManga();
      final index = mangaList.indexWhere((manga) => manga.id == updatedManga.id);
      
      if (index == -1) return false;

      mangaList[index] = updatedManga.copyWith(
        lastModified: DateTime.now(),
      );
      
      return await _saveMangaList(mangaList);
    } catch (e) {
      print('Error updating manga: $e');
      return false;
    }
  }

  // Delete manga
  static Future<bool> deleteManga(String mangaId) async {
    try {
      final mangaList = await getAllManga();
      mangaList.removeWhere((manga) => manga.id == mangaId);
      
      return await _saveMangaList(mangaList);
    } catch (e) {
      print('Error deleting manga: $e');
      return false;
    }
  }

  // Get manga by ID
  static Future<Manga?> getMangaById(String id) async {
    try {
      final mangaList = await getAllManga();
      return mangaList.firstWhere(
        (manga) => manga.id == id,
        orElse: () => throw Exception('Manga not found'),
      );
    } catch (e) {
      print('Error getting manga by ID: $e');
      return null;
    }
  }

  // Search manga
  static Future<List<Manga>> searchManga(String query) async {
    try {
      final mangaList = await getAllManga();
      final lowercaseQuery = query.toLowerCase();
      
      return mangaList.where((manga) {
        return manga.title.toLowerCase().contains(lowercaseQuery) ||
            manga.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching manga: $e');
      return [];
    }
  }

  // Clear all manga
  static Future<bool> clearAllManga() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_mangaListKey);
    } catch (e) {
      print('Error clearing manga: $e');
      return false;
    }
  }

  // Update manga page count based on chapters
  static Future<bool> updateMangaPageCount(String mangaId, int pageCount) async {
    try {
      final mangaList = await getAllManga();
      final index = mangaList.indexWhere((manga) => manga.id == mangaId);
      
      if (index == -1) return false;

      mangaList[index] = mangaList[index].copyWith(
        pages: pageCount,
        lastModified: DateTime.now(),
      );
      
      return await _saveMangaList(mangaList);
    } catch (e) {
      print('Error updating manga page count: $e');
      return false;
    }
  }

  // Get manga with updated chapter count
  static Future<Manga?> getMangaWithChapterCount(String mangaId) async {
    try {
      final manga = await getMangaById(mangaId);
      if (manga == null) return null;

      // This would require importing ChapterService, but to avoid circular dependency,
      // we'll handle this in the UI layer instead
      return manga;
    } catch (e) {
      print('Error getting manga with chapter count: $e');
      return null;
    }
  }

  // Get random color for new manga
  static Color _getRandomColor() {
    final random = DateTime.now().millisecondsSinceEpoch % _defaultColors.length;
    return _defaultColors[random];
  }

  // Get available colors for selection
  static List<Color> getAvailableColors() {
    return List.from(_defaultColors);
  }


} 