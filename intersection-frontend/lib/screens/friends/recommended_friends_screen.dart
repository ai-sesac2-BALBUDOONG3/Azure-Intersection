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

  /// ApiService.getFriendRecommendationsAI() 결과:
  /// [
  ///   {
  ///     "user": { ... },
  ///     "reason": "추천 이유",
  ///     "first_messages": ["...", "..."]
  ///   },
  ///   ...
  /// ]
  List<Map<String, dynamic>> _recommended = [];

  @override
  void initState() {
    super.initState();
    _loadRecommended();
  }

  Future<void> _loadRecommended() async {
    // 로그인하지 않은 경우 API 호출하지 않음
    if (AppState.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final list = await ApiService.getFriendRecommendationsAI();

      setState(() {
        _recommended = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("추천친구 불러오기 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend(Map<String, dynamic> item) async {
    try {
      final userJson =
          Map<String, dynamic>.from(item['user'] ?? <String, dynamic>{});

      final user = User(
        id: userJson['id'],
        name: userJson['name'] ?? '',
        birthYear: userJson['birth_year'] ?? 0,
        region: userJson['region'] ?? '',
        school: userJson['school_name'] ?? '',
        profileImageUrl: userJson['profile_image'],
        backgroundImageUrl: userJson['background_image'],
      );

      final success = await ApiService.addFriend(user.id);

      if (success) {
        setState(() {
          _recommended.removeWhere((m) {
            final u = m['user'] as Map?;
            return u?['id'] == user.id;
          });
        });

        AppState.friends.add(user);

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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommended.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            '지역·학교·나이가 유사한 친구들을 추천해요',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          SizedBox(height: 24),
          Center(
            child: Text(
              '아직 추천할 친구가 없어요.\n내 정보를 더 채우고, 친구를 초대해보세요!',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommended,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '지역·학교·나이가 유사한 친구들을 추천해요',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ..._recommended.map((item) {
            final userJson =
                Map<String, dynamic>.from(item['user'] ?? <String, dynamic>{});
            final reason = (item['reason'] ?? '') as String;
            final firstMessages =
                List<String>.from(item['first_messages'] ?? const []);

            final user = User(
              id: userJson['id'],
              name: userJson['name'] ?? '',
              birthYear: userJson['birth_year'] ?? 0,
              region: userJson['region'] ?? '',
              school: userJson['school_name'] ?? '',
              profileImageUrl: userJson['profile_image'],
              backgroundImageUrl: userJson['background_image'],
            );

            final isFriendAlready =
                currentFriends.any((f) => f.id == user.id);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendProfileScreen(user: user),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) 상단: 프로필 + 학교/지역 + 추가 버튼
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.person, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${user.school} · ${user.region}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          isFriendAlready
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 22)
                              : FilledButton(
                                  onPressed: () => _addFriend(item),
                                  style: FilledButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('추가'),
                                ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 2) 추천 이유
                      if (reason.isNotEmpty) ...[
                        const Text(
                          "추천 이유",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 3) 첫 메시지 후보
                      if (firstMessages.isNotEmpty) ...[
                        const Text(
                          "첫 메시지 이렇게 시작해보세요",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...firstMessages.map(
                          (msg) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(fontSize: 13),
                                ),
                                Expanded(
                                  child: Text(
                                    msg,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
