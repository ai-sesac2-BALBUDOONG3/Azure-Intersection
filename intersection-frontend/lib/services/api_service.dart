// intersection-frontend/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../data/app_state.dart';

class ApiService {
  // ----------------------------------------------------
  // 공통 헤더
  // ----------------------------------------------------
  static Map<String, String> _headers({bool json = true}) {
    final token = AppState.token;
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------
  // 공통 URL 빌더 (baseUrl + path 정리)
  // ----------------------------------------------------
  static Uri _buildUri(String path) {
    final base = ApiConfig.baseUrl;
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  // 공통 에러 헬퍼
  static Never _throwHttpError(
      String label, http.Response response, String path) {
    throw Exception(
      '$label 실패 '
      '(status: ${response.statusCode}, path: $path, body: ${response.body})',
    );
  }

  // ----------------------------------------------------
  // 1) 회원가입
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> signup(
      Map<String, dynamic> data) async {
    const path = '/users/';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwHttpError('회원가입', response, path);
    }
  }

  // ----------------------------------------------------
  // 2) 로그인 (JSON 방식)
  // ----------------------------------------------------
  static Future<String> login(String email, String password) async {
    const path = '/token';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['access_token'] as String;
    } else {
      _throwHttpError('로그인', response, path);
    }
  }

  // ----------------------------------------------------
  // 3) 내 정보 가져오기
  // ----------------------------------------------------
  static Future<User> getMyInfo() async {
    const path = '/users/me';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User(
        id: data['id'] as int,
        name: data['name'] ?? '',
        birthYear: data['birth_year'] ?? 0,
        region: data['region'] ?? '',
        school: data['school_name'] ?? '',
      );
    } else {
      _throwHttpError('내 정보 불러오기', response, path);
    }
  }

  // ----------------------------------------------------
  // 4) 내 정보 업데이트
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> updateMyInfo(
      Map<String, dynamic> data) async {
    const path = '/users/me';
    final url = _buildUri(path);

    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwHttpError('내 정보 업데이트', response, path);
    }
  }

  // ----------------------------------------------------
  // Kakao dev login (dev-only helper)
  // ----------------------------------------------------
  static Future<String> kakaoDevLogin() async {
    const path = '/auth/kakao/dev_token';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['access_token'] as String;
    } else {
      _throwHttpError('Kakao dev login', response, path);
    }
  }

  // ----------------------------------------------------
  // 5) 추천 친구 목록
  // ----------------------------------------------------
  static Future<List<User>> getRecommendedFriends() async {
    const path = '/users/me/recommended';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;

      return list.map((raw) {
        final data = raw as Map<String, dynamic>;
        return User(
          id: data['id'] as int,
          name: data['name'] ?? '',
          birthYear: data['birth_year'] ?? 0,
          region: data['region'] ?? '',
          school: data['school_name'] ?? '',
        );
      }).toList();
    } else {
      _throwHttpError('추천 친구 불러오기', response, path);
    }
  }

  // ----------------------------------------------------
  // 6) 친구 추가 / 목록
  // ----------------------------------------------------
  static Future<bool> addFriend(int targetUserId) async {
    final path = '/friends/$targetUserId';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  static Future<List<User>> getFriends() async {
    const path = '/friends/me';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;

      return list.map((raw) {
        final data = raw as Map<String, dynamic>;
        return User(
          id: data['id'] as int,
          name: data['name'] ?? '',
          birthYear: data['birth_year'] ?? 0,
          region: data['region'] ?? '',
          school: data['school_name'] ?? '',
        );
      }).toList();
    } else {
      _throwHttpError('친구 목록 불러오기', response, path);
    }
  }

  // ----------------------------------------------------
  // Posts / Comments
  // ----------------------------------------------------
  static Future<Map<String, dynamic>> createPost(String content) async {
    const path = '/users/me/posts/';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwHttpError('게시글 작성', response, path);
    }
  }

  static Future<List<Map<String, dynamic>>> listPosts() async {
    const path = '/posts/';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return List<Map<String, dynamic>>.from(list);
    } else {
      _throwHttpError('게시물 목록 불러오기', response, path);
    }
  }

  static Future<Map<String, dynamic>> createComment(
      int postId, String content) async {
    final path = '/posts/$postId/comments';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwHttpError('댓글 작성', response, path);
    }
  }

  static Future<List<Map<String, dynamic>>> listComments(int postId) async {
    final path = '/posts/$postId/comments';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return List<Map<String, dynamic>>.from(list);
    } else {
      _throwHttpError('댓글 목록 불러오기', response, path);
    }
  }

  // ----------------------------------------------------
  // 💬 채팅 API
  // ----------------------------------------------------

  /// 채팅방 생성 또는 가져오기
  static Future<ChatRoom> createOrGetChatRoom(int friendId) async {
    const path = '/chat/rooms';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'friend_id': friendId}),
    );

    if (response.statusCode == 200) {
      return ChatRoom.fromJson(jsonDecode(response.body));
    } else {
      _throwHttpError('채팅방 생성', response, path);
    }
  }

  /// 내 채팅방 목록 가져오기
  static Future<List<ChatRoom>> getMyChatRooms() async {
    const path = '/chat/rooms';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      _throwHttpError('채팅방 목록 불러오기', response, path);
    }
  }

  /// 채팅방의 메시지 목록 가져오기
  static Future<List<ChatMessage>> getChatMessages(int roomId) async {
    final path = '/chat/rooms/$roomId/messages';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      _throwHttpError('메시지 불러오기', response, path);
    }
  }

  /// 메시지 전송 (REST API 방식)
  static Future<ChatMessage> sendChatMessage(
      int roomId, String content) async {
    final path = '/chat/rooms/$roomId/messages';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      _throwHttpError('메시지 전송', response, path);
    }
  }

  // ----------------------------------------------------
  // 🚫 차단 & 신고 API
  // ----------------------------------------------------

  /// 사용자 차단
  static Future<bool> blockUser(int userId) async {
    const path = '/moderation/block';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'blocked_user_id': userId}),
    );

    return response.statusCode == 200;
  }

  /// 사용자 차단 해제
  static Future<bool> unblockUser(int userId) async {
    final path = '/moderation/block/$userId';
    final url = _buildUri(path);

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  /// 차단 목록 조회
  static Future<List<int>> getBlockedUserIds() async {
    const path = '/moderation/blocked';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) =>
              (item as Map<String, dynamic>)['blocked_user_id'] as int)
          .toList();
    }
    return [];
  }

  /// 차단 여부 확인 (양방향)
  static Future<Map<String, dynamic>> checkIfBlocked(int userId) async {
    final path = '/moderation/is-blocked/$userId';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {
      'is_blocked': false,
      'i_blocked_them': false,
      'they_blocked_me': false,
    };
  }

  /// 사용자 신고
  static Future<bool> reportUser({
    required int userId,
    required String reason,
    String? content,
  }) async {
    const path = '/moderation/report';
    final url = _buildUri(path);

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'reported_user_id': userId,
        'reason': reason,
        'content': content,
      }),
    );

    return response.statusCode == 200;
  }

  /// 채팅방 삭제 (나가기)
  static Future<bool> deleteChatRoom(int roomId) async {
    final path = '/chat/rooms/$roomId';
    final url = _buildUri(path);

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }

  /// 내가 특정 사용자를 신고했는지 확인
  static Future<Map<String, dynamic>> checkMyReport(int userId) async {
    final path = '/moderation/my-reports/$userId';
    final url = _buildUri(path);

    final response = await http.get(url, headers: _headers(json: false));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'has_reported': false};
  }

  /// 신고 취소
  static Future<bool> cancelReport(int reportId) async {
    final path = '/moderation/report/$reportId';
    final url = _buildUri(path);

    final response = await http.delete(
      url,
      headers: _headers(json: false),
    );

    return response.statusCode == 200;
  }
}
