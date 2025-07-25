import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';

class ChapterService {
  static const String _chaptersKey = 'chapters_list';

  // Get all chapters for a specific manga
  static Future<List<Chapter>> getChaptersByMangaId(String mangaId) async {
    try {
      final allChapters = await getAllChapters();
      final mangaChapters = allChapters
          .where((chapter) => chapter.mangaId == mangaId)
          .toList();
      
      // Sort by chapter number
      mangaChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
      return mangaChapters;
    } catch (e) {
      print('Error loading chapters for manga $mangaId: $e');
      return [];
    }
  }

  // Get all chapters
  static Future<List<Chapter>> getAllChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? chaptersJson = prefs.getString(_chaptersKey);
      
      if (chaptersJson == null) {
        return [];
      }

      final List<dynamic> chaptersListMap = jsonDecode(chaptersJson);
      return chaptersListMap.map((map) => Chapter.fromMap(map)).toList();
    } catch (e) {
      print('Error loading all chapters: $e');
      return [];
    }
  }

  // Save all chapters
  static Future<bool> _saveChaptersList(List<Chapter> chapters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> chaptersListMap = 
          chapters.map((chapter) => chapter.toMap()).toList();
      final String chaptersJson = jsonEncode(chaptersListMap);
      
      return await prefs.setString(_chaptersKey, chaptersJson);
    } catch (e) {
      print('Error saving chapters list: $e');
      return false;
    }
  }

  // Add new chapter
  static Future<bool> addChapter({
    required String mangaId,
    required String title,
    required String content,
  }) async {
    try {
      final allChapters = await getAllChapters();
      
      // Get next chapter number for this manga
      final mangaChapters = allChapters
          .where((chapter) => chapter.mangaId == mangaId)
          .toList();
      final nextChapterNumber = mangaChapters.isEmpty 
          ? 1 
          : mangaChapters.map((c) => c.chapterNumber).reduce((a, b) => a > b ? a : b) + 1;
      
      final now = DateTime.now();
      
      final newChapter = Chapter(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mangaId: mangaId,
        chapterNumber: nextChapterNumber,
        title: title,
        content: content,
        createdAt: now,
        lastModified: now,
        isPublished: false,
      );

      allChapters.add(newChapter);
      return await _saveChaptersList(allChapters);
    } catch (e) {
      print('Error adding chapter: $e');
      return false;
    }
  }

  // Update chapter
  static Future<bool> updateChapter(Chapter updatedChapter) async {
    try {
      final allChapters = await getAllChapters();
      final index = allChapters.indexWhere((chapter) => chapter.id == updatedChapter.id);
      
      if (index == -1) return false;

      allChapters[index] = updatedChapter.copyWith(
        lastModified: DateTime.now(),
      );
      
      return await _saveChaptersList(allChapters);
    } catch (e) {
      print('Error updating chapter: $e');
      return false;
    }
  }

  // Delete chapter
  static Future<bool> deleteChapter(String chapterId) async {
    try {
      final allChapters = await getAllChapters();
      allChapters.removeWhere((chapter) => chapter.id == chapterId);
      
      return await _saveChaptersList(allChapters);
    } catch (e) {
      print('Error deleting chapter: $e');
      return false;
    }
  }

  // Get chapter by ID
  static Future<Chapter?> getChapterById(String id) async {
    try {
      final allChapters = await getAllChapters();
      return allChapters.firstWhere(
        (chapter) => chapter.id == id,
        orElse: () => throw Exception('Chapter not found'),
      );
    } catch (e) {
      print('Error getting chapter by ID: $e');
      return null;
    }
  }

  // Publish/Unpublish chapter
  static Future<bool> toggleChapterPublish(String chapterId) async {
    try {
      final chapter = await getChapterById(chapterId);
      if (chapter == null) return false;

      final updatedChapter = chapter.copyWith(
        isPublished: !chapter.isPublished,
        lastModified: DateTime.now(),
      );

      return await updateChapter(updatedChapter);
    } catch (e) {
      print('Error toggling chapter publish status: $e');
      return false;
    }
  }

  // Get chapter statistics for a manga
  static Future<Map<String, dynamic>> getChapterStats(String mangaId) async {
    try {
      final chapters = await getChaptersByMangaId(mangaId);
      
      final totalChapters = chapters.length;
      final publishedChapters = chapters.where((c) => c.isPublished).length;
      final totalWords = chapters.fold<int>(0, (sum, chapter) => sum + chapter.wordCount);
      final averageWords = totalChapters > 0 ? (totalWords / totalChapters).round() : 0;
      
      return {
        'totalChapters': totalChapters,
        'publishedChapters': publishedChapters,
        'draftChapters': totalChapters - publishedChapters,
        'totalWords': totalWords,
        'averageWords': averageWords,
        'estimatedReadingTime': (totalWords / 200).ceil(), // 200 words per minute
      };
    } catch (e) {
      print('Error getting chapter stats: $e');
      return {
        'totalChapters': 0,
        'publishedChapters': 0,
        'draftChapters': 0,
        'totalWords': 0,
        'averageWords': 0,
        'estimatedReadingTime': 0,
      };
    }
  }

  // Search chapters within a manga
  static Future<List<Chapter>> searchChaptersInManga(String mangaId, String query) async {
    try {
      final chapters = await getChaptersByMangaId(mangaId);
      final lowercaseQuery = query.toLowerCase();
      
      return chapters.where((chapter) {
        return chapter.title.toLowerCase().contains(lowercaseQuery) ||
            chapter.content.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching chapters: $e');
      return [];
    }
  }

  // Reorder chapter numbers
  static Future<bool> reorderChapters(String mangaId, List<Chapter> reorderedChapters) async {
    try {
      final allChapters = await getAllChapters();
      
      // Update chapter numbers
      for (int i = 0; i < reorderedChapters.length; i++) {
        final chapter = reorderedChapters[i];
        final index = allChapters.indexWhere((c) => c.id == chapter.id);
        if (index != -1) {
          allChapters[index] = chapter.copyWith(
            chapterNumber: i + 1,
            lastModified: DateTime.now(),
          );
        }
      }
      
      return await _saveChaptersList(allChapters);
    } catch (e) {
      print('Error reordering chapters: $e');
      return false;
    }
  }

  // Clear all chapters for a manga
  static Future<bool> clearMangaChapters(String mangaId) async {
    try {
      final allChapters = await getAllChapters();
      allChapters.removeWhere((chapter) => chapter.mangaId == mangaId);
      
      return await _saveChaptersList(allChapters);
    } catch (e) {
      print('Error clearing manga chapters: $e');
      return false;
    }
  }

  // Clear all chapters
  static Future<bool> clearAllChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_chaptersKey);
    } catch (e) {
      print('Error clearing all chapters: $e');
      return false;
    }
  }
} 