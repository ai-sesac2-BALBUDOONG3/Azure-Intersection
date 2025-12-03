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
  List<User> _recommended = [];
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

  Future<void> _loadRecommended() async {
    // 로그인하지 않은 경우 API 호출하지 않음
    if (AppState.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final users = await ApiService.getRecommendedFriends();

      setState(() {
        _recommended = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("추천친구 불러오기 오류: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend(User user) async {
    try {
      final success = await ApiService.addFriend(user.id);

      if (success) {
        setState(() {
          _recommended.removeWhere((u) => u.id == user.id);
        });

        AppState.friends.add(user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user.name}님이 친구로 추가되었습니다.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("친구 추가 실패")),
        );
      }
    } catch (e) {
      debugPrint("친구추가 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("친구추가 오류: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFriends = AppState.friends;

    // 검색 필터링
    final filteredRecommended = _searchQuery.isEmpty
        ? _recommended
        : _recommended
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
                    builder: (_) =>
                        FriendProfileScreen(user: user),
                  ),
                );
              },

              trailing: isFriendAlready
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 22)
                  : FilledButton(
                      onPressed: () => _addFriend(user),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18),
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
