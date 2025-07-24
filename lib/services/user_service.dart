import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _birthDateKey = 'user_birth_date';
  static const String _infoCompletedKey = 'user_info_completed';

  // Get user information
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_infoCompletedKey) ?? false;
      
      if (!isCompleted) return null;
      
      final name = prefs.getString(_nameKey);
      final email = prefs.getString(_emailKey);
      final birthDateStr = prefs.getString(_birthDateKey);
      
      DateTime? birthDate;
      if (birthDateStr != null) {
        birthDate = DateTime.tryParse(birthDateStr);
      }
      
      return {
        'name': name,
        'email': email,
        'birthDate': birthDate,
        'isCompleted': isCompleted,
      };
    } catch (e) {
      return null;
    }
  }

  // Check if user info is completed
  static Future<bool> isUserInfoCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_infoCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Save user information
  static Future<bool> saveUserInfo({
    required String name,
    required String email,
    required DateTime birthDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, name);
      await prefs.setString(_emailKey, email);
      await prefs.setString(_birthDateKey, birthDate.toIso8601String());
      await prefs.setBool(_infoCompletedKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear user information
  static Future<bool> clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_birthDateKey);
      await prefs.setBool(_infoCompletedKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user name only
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nameKey);
    } catch (e) {
      return null;
    }
  }

  // Get user email only
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      return null;
    }
  }

  // Get formatted birth date
  static Future<String?> getFormattedBirthDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final birthDateStr = prefs.getString(_birthDateKey);
      if (birthDateStr == null) return null;
      
      final birthDate = DateTime.tryParse(birthDateStr);
      if (birthDate == null) return null;
      
      return '${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';
    } catch (e) {
      return null;
    }
  }
} 