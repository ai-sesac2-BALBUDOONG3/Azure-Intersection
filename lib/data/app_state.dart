import 'package:intersection/models/user.dart';
import 'package:intersection/models/post.dart';

class AppState {
  /// 현재 로그인한 유저
  static User? currentUser;

  /// JWT 토큰
  static String? token;

  /// 🔥 DB에서 불러온 친구 목록 (mutable)
  static List<User> friends = [];

  /// 🔥 커뮤니티 포스트 (추후 API로 대체)
  static List<Post> communityPosts = [];

  /// ----------------------------------------------------
  /// 친구 추가 (로컬 반영)
  /// ----------------------------------------------------
  static void follow(User user) {
    if (!friends.any((f) => f.id == user.id)) {
      friends.add(user);
    }
  }

  /// ----------------------------------------------------
  /// 친구 제거
  /// ----------------------------------------------------
  static void unfollow(User user) {
    friends.removeWhere((f) => f.id == user.id);
  }

  /// ----------------------------------------------------
  /// 로그인
  /// ----------------------------------------------------
  static void login(String newToken, User user) {
    token = newToken;
    currentUser = user;
  }

  /// ----------------------------------------------------
  /// 로그아웃
  /// ----------------------------------------------------
  static void logout() {
    token = null;
    currentUser = null;
    friends = [];
    communityPosts = [];
  }
}
