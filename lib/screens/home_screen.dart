import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'intersection',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧠 오늘의 질문
            const Text(
              '오늘의 기억 질문',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _MemoryQuestionCard(),

            const SizedBox(height: 28),

            // 👥 추천 친구
            const Text(
              '추천된 친구들',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _RecommendedFriendsSection(),

            const SizedBox(height: 28),

            // 🧵 커뮤니티 피드
            const Text(
              '커뮤니티 피드',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _CommunityFeedSection(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------
// 🧠 오늘의 질문 카드 (UI만, 데이터는 2단계에서 추가)
// ----------------------------------------
class _MemoryQuestionCard extends StatelessWidget {
  const _MemoryQuestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.05),
      ),
      child: const Text(
        "오늘 떠오르는 초등학교 기억은 뭐야?",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// ----------------------------------------
// 👥 추천 친구 자리만 잡아둔 상태
// ----------------------------------------
class _RecommendedFriendsSection extends StatelessWidget {
  const _RecommendedFriendsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _FriendCard(name: "홍길동", school: "A초등학교"),
          _FriendCard(name: "김철수", school: "B중학교"),
          _FriendCard(name: "이영희", school: "C고등학교"),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final String name;
  final String school;

  const _FriendCard({required this.name, required this.school});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 18),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            school,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------
// 🧵 커뮤니티 피드 자리
// ----------------------------------------
class _CommunityFeedSection extends StatelessWidget {
  const _CommunityFeedSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _PostCard(
          name: "홍길동",
          content: "초등학교 운동장에서 놀던 기억이 갑자기 떠오르네ㅋㅋ",
        ),
        SizedBox(height: 12),
        _PostCard(
          name: "이영희",
          content: "추억 얘기하니까 급식 떡볶이 생각난다.",
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final String name;
  final String content;

  const _PostCard({required this.name, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
