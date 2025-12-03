import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intersection/data/app_state.dart';
import 'package:intersection/models/post.dart';
import 'package:intersection/services/api_service.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;

  // 웹/앱 모두 지원
  Uint8List? selectedBytes;
  File? selectedFile;
  String? previewName;

  void _removeImage() {
    setState(() {
      selectedBytes = null;
      selectedFile = null;
      previewName = null;
    });
  }

  // -------------------------------------------------------
  // 🔥 이미지 선택 (웹/앱 완전 분리)
  // -------------------------------------------------------
  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          selectedBytes = result.files.first.bytes!;
          previewName = result.files.first.name;
        });
      }

    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          selectedFile = File(picked.path);
          previewName = picked.name;
        });
      }
    }
  }

  // -------------------------------------------------------
  // 🔥 게시물 업로드
  // -------------------------------------------------------
  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    // 최소한 글 또는 이미지 둘 중 하나 필요
    if (content.isEmpty && selectedBytes == null && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("내용 또는 이미지를 입력해줘.")),
      );
      return;
    }

    if (AppState.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인이 필요해요.")),
      );
      return;
    }

    setState(() => _isPosting = true);

    String? uploadedUrl;

    // -------------------------------------------------------
    // 1) 이미지 업로드
    // -------------------------------------------------------
    try {
      if (!kIsWeb && selectedFile != null) {
        // 앱: File upload
        final resp = await ApiService.uploadFile(selectedFile!);
        uploadedUrl = resp["file_url"];
      } else if (kIsWeb && selectedBytes != null) {
        // 웹: Bytes upload
        final resp = await ApiService.uploadBytes(
          selectedBytes!,
          previewName ?? "image.png",
        );
        uploadedUrl = resp["file_url"];
      }
    } catch (e) {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("이미지 업로드 실패: $e")));
      return;
    }

    // -------------------------------------------------------
    // 2) 게시물 생성 요청 (image_url 하나만)
    // -------------------------------------------------------
    try {
      final response = await ApiService.createPostWithMedia(
        content: content,
        mediaUrls: uploadedUrl != null ? [uploadedUrl] : [],
      );

      final newPost = Post.fromJson(response);
      AppState.communityPosts.insert(0, newPost);

      setState(() => _isPosting = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("게시글 작성 실패: $e")));
    }
  }

  // -------------------------------------------------------
  // 🔥 UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "새 글",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isPosting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: _submitPost,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "게시",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          //-----------------------------------------------------
          // ✏ 글 입력
          //-----------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: "어떤 추억을 공유해볼까요?",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.black87,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),

          const SizedBox(height: 20),

          //-----------------------------------------------------
          // 📷 이미지 미리보기
          //-----------------------------------------------------
          if (selectedBytes != null || selectedFile != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.memory(
                            selectedBytes!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            selectedFile!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _removeImage,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          //-----------------------------------------------------
          // 📸 이미지 추가 버튼
          //-----------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "이미지 첨부",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
