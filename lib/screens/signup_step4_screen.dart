import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/signup_form_data.dart';
import '../config/api_config.dart'; // ✅ 우리가 만든 ApiConfig 불러오는 곳

class SignupStep4Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep4Screen({super.key, required this.data});

  @override
  State<SignupStep4Screen> createState() => _SignupStep4ScreenState();
}

class _SignupStep4ScreenState extends State<SignupStep4Screen> {
  final _interestsController = TextEditingController();
  bool _agreed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관에 동의해야 가입이 완료돼요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // ✅ 기존 data + 관심사 업데이트
    final updated = widget.data.copyWith(
      interests: _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    // ✅ birthYear를 정수로 변환
    int? birthYearInt;
    try {
      birthYearInt = int.parse(updated.birthYear);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년도가 올바르지 않습니다')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // 공통 설정에서 baseUrl 가져와서 backend의 사용자 생성 엔드포인트로 요청
    // (서버의 OpenAPI에 따라 경로가 '/users/'인 경우가 있어 그에 맞춰 전송)
    final url = Uri.parse("${ApiConfig.baseUrl}/users/");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // FastAPI UserCreate 스키마에 맞춘 필드명
          "email": updated.email ?? updated.userId,
          "password": updated.password,
          "name": updated.name,
          "birth_year": birthYearInt,
          "gender": updated.gender ?? '',
          "region": updated.region,
          "school_name": updated.schoolName ?? '',
          "school_type": updated.schoolLevel ?? '',
          "admission_year": int.tryParse(updated.entryYear) ?? 0,
          // 추가 정보는 서버가 받으면 처리하고, 아니면 무시됩니다.
          "interests": updated.interests ?? [],
        }),
      );

      // 위 await 이후에 위젯이 언마운트 되었을 수 있으니 확인
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // 디버그 로그: 응답 상세
      debugPrint('Signup response: ${response.statusCode} ${response.body}');

      // 2xx 계열은 성공으로 간주하되, 서버가 명시적으로 success:false를 반환하면 오류 표시
      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = null;
        }

        final bool serverExplicitFailure = data is Map && data['success'] == false;

        if (!serverExplicitFailure) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('회원가입 완료'),
              content: const Text('intersection에 오신 걸 환영합니다!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닻기
                    // 전체 네비게이션 스택을 제거하고 추천 화면으로 이동
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/recommended',
                      (route) => false,
                    );
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '오류가 발생했어요.')),
          );
        }
      } else {
          if (!mounted) return;
          // 서버 에러일 때 응답 본문을 사용자에게 보여줍니다 (디버깅 도움)
          String bodyPreview = response.body;
          try {
            final parsed = jsonDecode(response.body);
            bodyPreview = parsed is String ? parsed : jsonEncode(parsed);
          } catch (_) {
            // ignore JSON parse errors, keep raw body
          }
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('서버 오류 (${response.statusCode})'),
              content: SingleChildScrollView(child: Text(bodyPreview)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('통신 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 4/4 - 추가 정보')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _interestsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '추가 정보 / 관심사',
                hintText: '예: 98년생, 추억의 만화, A초등학교 시절 친구들...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) {
                    setState(() {
                      _agreed = v ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    '서비스 이용약관 및 개인정보 처리방침에 동의합니다.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('완료'),
              ),
            ),
            const Spacer(),
            const Text(
              '추가 정보는 추천 알고리즘 개선에만 활용되며\n'
              '외부에 공개되지 않아요.\n'
              '이 정보는 마이페이지에서 언제든지 수정할 수 있어요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
