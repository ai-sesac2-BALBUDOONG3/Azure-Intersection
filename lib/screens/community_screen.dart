import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/user.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = AppState.currentUser;
    final posts = AppState.communityPosts; // ← AppState에서 필터된 게시물

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
      ),
      body: me == null
          ? const Center(child: Text('로그인 정보가 없어요. 앱을 다시 시작해줘.'))
          : posts.isEmpty
              ? const Center(
                  child: Text(
                    '아직 커뮤니티에 글이 없어요.\n나중에 글 작성 기능도 붙이자.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    // 🔥 author 찾기 (friends + 나)
                    User? author;
                    final allKnownUsers = [
                      if (me != null) me,
                      ...AppState.friends
                    ];

                    try {
                      author = allKnownUsers.firstWhere(
                        (u) => u.id == post.authorId,
                      );
                    } catch (_) {
                      author = null;
                    }

                    return _PostCard(
                      post: post,
                      author: author,
                    );
                  },
                ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final User? author;

  const _PostCard({
    required this.post,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = author?.name ?? "알 수 없는 사용자";
    final displaySub = author == null
        ? ""
        : "${author!.school} · ${author!.region}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (displaySub.isNotEmpty)
                      Text(
                        displaySub,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              post.content,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('좋아요는 나중에')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('댓글은 나중에')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
