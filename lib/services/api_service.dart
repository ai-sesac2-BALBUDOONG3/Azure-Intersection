import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../data/app_state.dart';

class ApiService {
  // ----------------------------------------------------
  // 공통 헤더
  // ----------------------------------------------------
  static Map<String, String> _headers({bool json = true}) {
    final token = AppState.token;
    return {
      if (json) "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ----------------------------------------------------
  // 1) 회원가입
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception("회원가입 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 2) 로그인 (JSON 방식)
  // ----------------------------------------------------
  static Future<String> login(String email, String password) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access_token"];
    } else {
      throw Exception("로그인 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 3) 내 정보 가져오기
  // ----------------------------------------------------
  static Future<User> getMyInfo() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me");
    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User(
        id: data["id"],
        name: data["name"],
        birthYear: data["birth_year"],
        region: data["region"],
        school: data["school_name"],
      );
    } else {
      throw Exception("내 정보 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 4) 추천 친구 목록
  // ----------------------------------------------------
  static Future<List<User>> getRecommendedFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/me/recommended");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;

      return list.map((data) {
        return User(
          id: data["id"],
          name: data["name"],
          birthYear: data["birth_year"],
          region: data["region"],
          school: data["school_name"],
        );
      }).toList();
    } else {
      throw Exception("추천 친구 불러오기 실패: ${response.body}");
    }
  }

  // ----------------------------------------------------
  // 5) 친구 추가
  // ----------------------------------------------------
  static Future<bool> addFriend(int targetUserId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/$targetUserId");

    final response = await http.post(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  // ----------------------------------------------------
  // 6) 친구 목록 가져오기
  // ----------------------------------------------------
  static Future<List<User>> getFriends() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/friends/me");

    final response = await http.get(
      url,
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;

      return list.map((data) {
        return User(
          id: data["id"],
          name: data["name"],
          birthYear: data["birth_year"],
          region: data["region"],
          school: data["school_name"],
        );
      }).toList();
    } else {
      throw Exception("친구 목록 불러오기 실패: ${response.body}");
    }
  }
}
