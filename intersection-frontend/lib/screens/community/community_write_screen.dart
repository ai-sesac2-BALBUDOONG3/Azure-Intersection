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

  // 웹/앱 모두 지원을 위한 변수들
  Uint8List? selectedBytes; // 웹용 이미지 데이터
  File? selectedFile;       // 앱용 이미지 파일
  String? previewName;      // 파일명

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _removeImage() {
    setState(() {
      selectedBytes = null;
      selectedFile = null;
      previewName = null;
    });
  }

  // -------------------------------------------------------
  // 🔥 이미지 선택 (웹/앱 분리 처리)
  // -------------------------------------------------------
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // 🌐 웹: FilePicker 사용
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          selectedBytes = result.files.first.bytes!;
          previewName = result.files.first.name;
          selectedFile = null; // 웹에서는 File 객체 사용 안 함
        });
      }
    } else {
      // 📱 앱: ImagePicker 사용
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          selectedFile = File(picked.path);
          previewName = picked.name;
          selectedBytes = null; // 앱에서는 Bytes 직접 사용 안 함
        });
      }
    }
  }

  // -------------------------------------------------------
  // 🔥 게시물 업로드 (수정됨)
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

    try {
      // ✅ [수정 포인트] 
      // 이전에는 이미지를 먼저 업로드하고 URL을 리스트로 넘겼지만,
      // 이제는 createPostWithMedia 함수 하나에 파일/바이트를 직접 넘깁니다.
      final response = await ApiService.createPostWithMedia(
        content: content,
        imageFile: selectedFile,      // 앱용 (File)
        imageBytes: selectedBytes,    // 웹용 (Uint8List)
        fileName: previewName,        // 웹용 파일명
      );

      // 응답으로 받은 새 게시글을 로컬 상태에 추가 (즉시 반영)
      final newPost = Post.fromJson(response);
      AppState.communityPosts.insert(0, newPost);

      if (!mounted) return;
      setState(() => _isPosting = false);
      
      // 성공적으로 작성되면 화면 닫기 (true 반환)
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("게시글 작성 실패: $e")),
      );
    }
  }

  // -------------------------------------------------------
  // 🔥 UI 구성
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
        foregroundColor: Colors.black, // 앱바 텍스트 색상
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