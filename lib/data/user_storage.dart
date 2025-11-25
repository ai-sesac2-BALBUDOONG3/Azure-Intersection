// lib/data/user_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserStorage {
  static const String _key = "current_user";

  static Future<void> save(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(user.toJson()));
  }

  static Future<User?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      return User.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_key);
  }
}
