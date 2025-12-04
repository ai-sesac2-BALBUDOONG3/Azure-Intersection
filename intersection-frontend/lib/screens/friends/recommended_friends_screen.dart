// lib/screens/friends/recommended_friends_screen.dart

import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/screens/friends/friend_profile_screen.dart';
import 'package:intersection/services/api_service.dart';

class RecommendedFriendsScreen extends StatefulWidget {
  const RecommendedFriendsScreen({super.key});

  @override
  State<RecommendedFriendsScreen> createState() =>
      _RecommendedFriendsScreenState();
}

class _RecommendedFriendsScreenState extends State<RecommendedFriendsScreen> {
  bool _isLoading = true;

  /// 백엔드에서 내려오는 원본 리스트
  /// - AI 추천 API 결과가 Map 형태일 수도, User 형태일 수도 있어서 dynamic으로 둔다.
  List<dynamic> _rawRecommended = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadRecommended();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 백엔드에서 AI 추천 친구 목록을 불러옴
  Future<void> _loadRecommended() async {
    // 로그인하지 않은 경우 API 호출하지 않음
    if (AppState.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ApiService.getFriendRecommendationsAI()가
      // List<dynamic> 또는 List<Map<String, dynamic>> 를 반환한다고 가정
      final list = await ApiService.getFriendRecommendationsAI();

      setState(() {
        _rawRecommended = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("추천친구 불러오기 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 백엔드에서 내려온 item 하나를 화면에서 쓰는 User 모델로 변환
  User _mapToUser(dynamic item) {
    // 이미 User 타입이면 그대로 사용
    if (item is User) {
      return item;
    }

    // Map 형태일 경우 (예: { user: {...}, score: ..., reason: ... })
    if (item is Map<String, dynamic>) {
      // item['user'] 안에 실제 사용자 정보가 있다고 가정
      final userJson = Map<String, dynamic>.from(
        (item['user'] ?? item) as Map<String, dynamic>,
      );

      return User(
        id: userJson['id'] as int,
        name: (userJson['name'] ?? '') as String,
        birthYear: (userJson['birth_year'] ?? 0) as int,
        region: (userJson['region'] ?? '') as String,
        school: (userJson['school_name'] ?? '') as String,
        profileImageUrl: userJson['profile_image'] as String?,
        backgroundImageUrl: userJson['background_image'] as String?,
      );
    }

    throw ArgumentError('지원하지 않는 추천 데이터 형식: ${item.runtimeType}');
  }

  /// 친구 추가
  Future<void> _addFriend(User user) async {
    try {
      final success = await ApiService.addFriend(user.id);

      if (success) {
        setState(() {
          // 원본 리스트(_rawRecommended)에서 해당 유저 제거
          _rawRecommended.removeWhere((m) {
            try {
              if (m is User) {
                return m.id == user.id;
              }
              if (m is Map<String, dynamic>) {
                final inner =
                    (m['user'] ?? m) as Map<String, dynamic>?; // { user: {...} } or {...}
                final id = inner?['id'];
                return id == user.id;
              }
            } catch (_) {
              return false;
            }
            return false;
          });
        });

        // AppState.friends 에도 추가 (이미 있으면 중복 추가 X)
        final alreadyFriend =
            AppState.friends.any((f) => f.id == user.id);
        if (!alreadyFriend) {
          AppState.friends.add(user);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${user.name}님이 친구로 추가되었습니다.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("친구 추가 실패")),
          );
        }
      }
    } catch (e) {
      debugPrint("친구추가 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("친구추가 오류: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFriends = AppState.friends;

    // 원본 리스트(_rawRecommended)를 User 리스트로 변환
    final List<User> users = _rawRecommended
        .map((item) {
          try {
            return _mapToUser(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<User>()
        .toList();

    // 검색 필터링
    final filteredRecommended = _searchQuery.isEmpty
        ? users
        : users
            .where((user) =>
                user.name.toLowerCase().contains(_searchQuery) ||
                (user.school?.toLowerCase().contains(_searchQuery) ?? false) ||
                (user.region?.toLowerCase().contains(_searchQuery) ?? false))
            .toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🔍 검색바
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: "추천 친구 검색...",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '지역·학교·나이가 유사한 친구들을 추천해요',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ...filteredRecommended.map((user) {
          final isFriendAlready =
              currentFriends.any((f) => f.id == user.id);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(user.name),
              subtitle: Text("${user.school} · ${user.region}"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendProfileScreen(user: user),
                  ),
                );
              },
              trailing: isFriendAlready
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    )
                  : FilledButton(
                      onPressed: () => _addFriend(user),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                      ),
                      child: const Text('추가'),
                    ),
            ),
          );
        }),

        // 검색 결과 없음 안내
        if (filteredRecommended.isEmpty && _searchQuery.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "검색 결과가 없습니다",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
