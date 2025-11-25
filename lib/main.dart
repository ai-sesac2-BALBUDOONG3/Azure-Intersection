import 'package:flutter/material.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/signup_form_data.dart';

// 🔥 자동 로그인 유지용
import 'package:intersection/data/user_storage.dart';

// Screens
import 'package:intersection/screens/landing_screen.dart';
import 'package:intersection/screens/main_tab_screen.dart';
import 'package:intersection/screens/phone_verification_screen.dart';
import 'package:intersection/screens/signup_step1_screen.dart';
import 'package:intersection/screens/signup_step3_screen.dart';
import 'package:intersection/screens/signup_step4_screen.dart';

import 'package:intersection/screens/recommended_screen.dart';
import 'package:intersection/screens/login_screen.dart';
import 'package:intersection/screens/friends_screen.dart';
import 'package:intersection/screens/comment_screen.dart';
import 'package:intersection/screens/community_write_screen.dart';
import 'package:intersection/screens/report_screen.dart';

import 'package:intersection/models/post.dart';

/// 🔥 여기서 자동 로그인 상태 복원
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 저장된 사용자 불러오기
  AppState.currentUser = await UserStorage.load();

  runApp(const IntersectionApp());
}

class IntersectionApp extends StatelessWidget {
  const IntersectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'intersection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a1a),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),

      /// 🔥 로그인 여부에 따라 초기 화면 전환
      home: AppState.currentUser == null
          ? const LandingScreen()
          : const MainTabScreen(),

      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/signup/phone':
            return MaterialPageRoute(builder: (_) => const PhoneVerificationScreen());

          case '/signup/step1':
            return MaterialPageRoute(builder: (_) => const SignupStep1Screen());

          case '/signup/step3':
            if (args is SignupFormData) {
              return MaterialPageRoute(
                builder: (_) => SignupStep3Screen(data: args),
              );
            }
            return _error("회원가입 데이터가 누락되었습니다.");

          case '/signup/step4':
            if (args is SignupFormData) {
              return MaterialPageRoute(
                builder: (_) => SignupStep4Screen(data: args),
              );
            }
            return _error("회원가입 데이터가 누락되었습니다.");

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/recommended':
            return MaterialPageRoute(builder: (_) => const RecommendedFriendsScreen());

          case '/friends':
            return MaterialPageRoute(builder: (_) => const FriendsScreen());

          case '/comments':
            if (args is Post) {
              return MaterialPageRoute(
                builder: (_) => CommentScreen(post: args),
              );
            }
            return _error("게시물 정보가 누락되었습니다.");

          case '/write':
            return MaterialPageRoute(builder: (_) => const CommunityWriteScreen());

          case '/report':
            if (args is Post) {
              return MaterialPageRoute(
                builder: (_) => ReportScreen(post: args),
              );
            }
            return _error("게시물 정보가 누락되었습니다.");

          default:
            return _error("존재하지 않는 페이지입니다.");
        }
      },
    );
  }

  Route<dynamic> _error(String msg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("오류")),
        body: Center(
          child: Text(msg),
        ),
      ),
    );
  }
}
