// lib/screens/community/comment_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/models/comment.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/config/api_config.dart';

/// =============================================================
/// 🔥 인스타그램 스타일 댓글 BottomSheet (Future로 변경됨)
/// =============================================================
Future<void> openCommentSheet(BuildContext context, Post post) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CommentScreen(
            post: post,
            scrollController: controller,
          ),
        );
      },
    ),
  );
}

/// =============================================================
/// 🔥 CommentScreen – BottomSheet 내부
/// =============================================================
class CommentScreen extends StatefulWidget {
  final Post post;
  final ScrollController? scrollController;

  const CommentScreen({
    super.key,
    required this.post,
    this.scrollController,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Comment> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
  try {
    final rows = await ApiService.listComments(widget.post.id);

    // 🔥 추가: 서버에서 내려오는 댓글 JSON을 모두 출력
    for (var j in rows) {
      print("🔥 COMMENT JSON = $j");
    }

    setState(() {
      comments = rows.map((json) => Comment.fromJson(json)).toList();
      loading = false;
    });
  } catch (_) {
    loading = false;
  }
}


  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final resp = await ApiService.createComment(widget.post.id, text);
      final newComment = Comment.fromJson(resp);

      setState(() {
        comments.add(newComment);
      });

      _controller.clear();
    } catch (_) {}
  }

  void _toggleLike(Comment c) async {
    final old = c.liked;

    if (old) {
      c.liked = false;
      c.likesCount -= 1;
      setState(() {});
      await ApiService.unlikeComment(c.id);
    } else {
      c.liked = true;
      c.likesCount += 1;
      setState(() {});
      await ApiService.likeComment(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 드래그 핸들
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: const [
              Text(
                "댓글",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
        ),

        // 원본 게시물 텍스트
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            widget.post.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : comments.isEmpty
                  ? const Center(
                      child: Text(
                        "아직 댓글이 없어요.\n첫 댓글을 남겨보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return CommentItem(
                          comment: c,
                          onToggleLike: () => _toggleLike(c),
                        );
                      },
                    ),
        ),

        // 입력창
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "댓글을 입력하세요",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black87),
            onPressed: _sendComment,
          ),
        ],
      ),
    );
  }
}

/// =============================================================
/// 🔥 프로필 이미지 Provider
/// =============================================================
ImageProvider commentProfileProvider(String? url) {
  if (url != null && url.isNotEmpty) {
    if (url.startsWith("http")) return NetworkImage(url);
    if (url.startsWith("/")) return NetworkImage("${ApiConfig.baseUrl}$url");
  }
  return const AssetImage("assets/images/logo.png");
}

/// =============================================================
/// 🔥 단일 댓글 UI
/// =============================================================
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onToggleLike;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: commentProfileProvider(comment.authorProfileImage),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName ?? "익명",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.createdAt.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: onToggleLike,
            child: Column(
              children: [
                Icon(
                  comment.liked ? Icons.whatshot : Icons.whatshot_outlined,
                  color: comment.liked ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  comment.likesCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: comment.liked ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),
          const Icon(Icons.more_vert, size: 20),
        ],
      ),
    );
  }
}
