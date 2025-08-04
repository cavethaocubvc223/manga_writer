import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_progress.dart';

class ProgressService {
  static const String _progressListKey = 'daily_progress_list';
  static const String _dailyGoalKey = 'daily_goal_pages';
  static const String _weeklyGoalKey = 'weekly_goal_pages';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';

  // Default goals
  static const int defaultDailyGoal = 3; // pages per day
  static const int defaultWeeklyGoal = 20; // pages per week

  // Get all daily progress
  static Future<List<DailyProgress>> getAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? progressListJson = prefs.getString(_progressListKey);
      
      if (progressListJson == null) {
        return [];
      }

      final List<dynamic> progressListMap = jsonDecode(progressListJson);
      return progressListMap.map((map) => DailyProgress.fromMap(map)).toList();
    } catch (e) {
      print('Error loading progress: $e');
      return [];
    }
  }

  // Save all progress
  static Future<bool> _saveProgressList(List<DailyProgress> progressList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> progressListMap = 
          progressList.map((progress) => progress.toMap()).toList();
      final String progressListJson = jsonEncode(progressListMap);
      
      return await prefs.setString(_progressListKey, progressListJson);
    } catch (e) {
      print('Error saving progress list: $e');
      return false;
    }
  }

  // Get today's progress
  static Future<DailyProgress?> getTodayProgress() async {
    try {
      final progressList = await getAllProgress();
      final today = DateTime.now();
      
      return progressList.firstWhere(
        (progress) => progress.date.year == today.year &&
                     progress.date.month == today.month &&
                     progress.date.day == today.day,
        orElse: () => throw Exception('Today progress not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Create or update today's progress
  static Future<bool> updateTodayProgress({
    int? pagesWritten,
    int? chaptersCompleted,
    int? charactersCreated,
    int? timeSpentMinutes,
    String? notes,
  }) async {
    try {
      final progressList = await getAllProgress();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Find existing today's progress
      final existingIndex = progressList.indexWhere(
        (progress) => progress.date.year == today.year &&
                     progress.date.month == today.month &&
                     progress.date.day == today.day,
      );

      final dailyGoal = await getDailyGoal();
      
      if (existingIndex != -1) {
        // Update existing progress
        final existing = progressList[existingIndex];
        final updatedProgress = existing.copyWith(
          pagesWritten: pagesWritten ?? existing.pagesWritten,
          chaptersCompleted: chaptersCompleted ?? existing.chaptersCompleted,
          charactersCreated: charactersCreated ?? existing.charactersCreated,
          timeSpentMinutes: timeSpentMinutes ?? existing.timeSpentMinutes,
          notes: notes ?? existing.notes,
          goalProgress: ((pagesWritten ?? existing.pagesWritten) / dailyGoal).clamp(0.0, 1.0),
          lastModified: DateTime.now(),
        );
        progressList[existingIndex] = updatedProgress;
      } else {
        // Create new progress
        final newProgress = DailyProgress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: todayStart,
          pagesWritten: pagesWritten ?? 0,
          chaptersCompleted: chaptersCompleted ?? 0,
          charactersCreated: charactersCreated ?? 0,
          timeSpentMinutes: timeSpentMinutes ?? 0,
          notes: notes ?? '',
          goalProgress: ((pagesWritten ?? 0) / dailyGoal).clamp(0.0, 1.0),
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        progressList.add(newProgress);
      }

      return await _saveProgressList(progressList);
    } catch (e) {
      print('Error updating today progress: $e');
      return false;
    }
  }

  // Get progress for last N days
  static Future<List<DailyProgress>> getRecentProgress(int days) async {
    try {
      final progressList = await getAllProgress();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      return progressList
          .where((progress) => progress.date.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('Error getting recent progress: $e');
      return [];
    }
  }

  // Get this week's progress
  static Future<List<DailyProgress>> getThisWeekProgress() async {
    try {
      final progressList = await getAllProgress();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      return progressList
          .where((progress) => progress.date.isAfter(weekStartDate.subtract(const Duration(days: 1))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('Error getting this week progress: $e');
      return [];
    }
  }

  // Get weekly statistics
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final weekProgress = await getThisWeekProgress();
      final weeklyGoal = await getWeeklyGoal();
      
      int totalPages = 0;
      int totalChapters = 0;
      int totalCharacters = 0;
      int totalTime = 0;
      
      for (final progress in weekProgress) {
        totalPages += progress.pagesWritten;
        totalChapters += progress.chaptersCompleted;
        totalCharacters += progress.charactersCreated;
        totalTime += progress.timeSpentMinutes;
      }
      
      return {
        'totalPages': totalPages,
        'totalChapters': totalChapters,
        'totalCharacters': totalCharacters,
        'totalTimeMinutes': totalTime,
        'weeklyGoal': weeklyGoal,
        'goalProgress': (totalPages / weeklyGoal).clamp(0.0, 1.0),
        'activeDays': weekProgress.where((p) => p.totalActivityScore > 0).length,
      };
    } catch (e) {
      print('Error getting weekly stats: $e');
      return {};
    }
  }

  // Daily goal management
  static Future<int> getDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal;
    } catch (e) {
      return defaultDailyGoal;
    }
  }

  static Future<bool> setDailyGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_dailyGoalKey, goal);
    } catch (e) {
      return false;
    }
  }

  // Weekly goal management
  static Future<int> getWeeklyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_weeklyGoalKey) ?? defaultWeeklyGoal;
    } catch (e) {
      return defaultWeeklyGoal;
    }
  }

  static Future<bool> setWeeklyGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_weeklyGoalKey, goal);
    } catch (e) {
      return false;
    }
  }

  // Reminder settings
  static Future<bool> isReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reminderEnabledKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> setReminderEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_reminderEnabledKey, enabled);
    } catch (e) {
      return false;
    }
  }

  static Future<String> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_reminderTimeKey) ?? '20:00';
    } catch (e) {
      return '20:00';
    }
  }

  static Future<bool> setReminderTime(String time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_reminderTimeKey, time);
    } catch (e) {
      return false;
    }
  }

  // Check if goal was achieved today
  static Future<bool> isTodayGoalAchieved() async {
    try {
      final todayProgress = await getTodayProgress();
      if (todayProgress == null) return false;
      
      final dailyGoal = await getDailyGoal();
      return todayProgress.pagesWritten >= dailyGoal;
    } catch (e) {
      return false;
    }
  }

  // Get streak count (consecutive days with progress)
  static Future<int> getCurrentStreak() async {
    try {
      final progressList = await getAllProgress();
      progressList.sort((a, b) => b.date.compareTo(a.date)); // Sort descending
      
      int streak = 0;
      final today = DateTime.now();
      
      for (int i = 0; i < progressList.length; i++) {
        final expectedDate = today.subtract(Duration(days: i));
        final progress = progressList.firstWhere(
          (p) => p.date.year == expectedDate.year &&
                 p.date.month == expectedDate.month &&
                 p.date.day == expectedDate.day,
          orElse: () => throw Exception('No progress for date'),
        );
        
        if (progress.totalActivityScore > 0) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Get reminder message based on today's progress
  static Future<String> getTodayReminderMessage() async {
    try {
      final todayProgress = await getTodayProgress();
      final dailyGoal = await getDailyGoal();
      final now = DateTime.now();
      final hour = now.hour;
      
      if (todayProgress == null || todayProgress.pagesWritten == 0) {
        if (hour < 12) {
          return 'Chào buổi sáng! Hãy bắt đầu viết manga ngay thôi! 🌅';
        } else if (hour < 18) {
          return 'Chưa viết gì hôm nay sao? Hãy dành chút thời gian cho manga nhé! ✍️';
        } else {
          return 'Tối rồi! Đừng quên mục tiêu $dailyGoal trang mỗi ngày nhé! 🌙';
        }
      } else if (todayProgress.pagesWritten < dailyGoal) {
        final remaining = dailyGoal - todayProgress.pagesWritten;
        return 'Tuyệt vời! Còn $remaining trang nữa là đạt mục tiêu rồi! 💪';
      } else {
        return 'Hoàn thành mục tiêu rồi! Bạn thật tuyệt vời! 🎉';
      }
    } catch (e) {
      return 'Hãy tiếp tục viết manga nhé! Bạn làm được mà! 📚';
    }
  }

  // Clear all progress
  static Future<bool> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_progressListKey);
    } catch (e) {
      print('Error clearing progress: $e');
      return false;
    }
  }


}