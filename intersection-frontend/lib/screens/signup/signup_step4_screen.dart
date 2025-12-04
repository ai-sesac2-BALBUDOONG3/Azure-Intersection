import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoPicker 사용을 위해 추가
import 'package:intersection/data/signup_form_data.dart';
import 'package:intersection/services/api_service.dart';
import 'package:intersection/models/user.dart';
import 'package:intersection/models/school_info.dart';
import 'package:intersection/widgets/school_input_widget.dart';
import 'package:intersection/data/app_state.dart';
import 'package:intersection/data/user_storage.dart';
import 'package:intersection/screens/main_tab_screen.dart';

class SignupStep4Screen extends StatefulWidget {
  final SignupFormData data;

  const SignupStep4Screen({super.key, required this.data});

  @override
  State<SignupStep4Screen> createState() => _SignupStep4ScreenState();
}

class _SignupStep4ScreenState extends State<SignupStep4Screen> {
  List<SchoolInfo> schools = [];

  late TextEditingController nicknamesController;
  late TextEditingController memoryKeywordsController;
  late TextEditingController interestsController;

  bool hasTransferInfo = false;
  late TextEditingController transferInfoController;

  @override
  void initState() {
    super.initState();
    // 기존 데이터가 있으면 첫 번째 학교로 초기화
    if (widget.data.schoolName.isNotEmpty) {
      schools = [
        SchoolInfo(
          name: widget.data.schoolName,
          schoolType: widget.data.schoolLevel.isNotEmpty ? widget.data.schoolLevel : null,
          admissionYear: widget.data.entryYear.isNotEmpty ? int.tryParse(widget.data.entryYear) : null,
        ),
      ];
    } else {
      // 기본으로 하나의 빈 학교 정보 추가
      schools = [SchoolInfo(name: '')];
    }

    nicknamesController =
        TextEditingController(text: widget.data.nicknames ?? '');
    memoryKeywordsController =
        TextEditingController(text: widget.data.memoryKeywords ?? '');
    interestsController =
        TextEditingController(text: (widget.data.interests ?? []).join(', '));

    hasTransferInfo = widget.data.transferInfo?.isNotEmpty == true;
    transferInfoController =
        TextEditingController(text: widget.data.transferInfo ?? '');
  }

  @override
  void dispose() {
    nicknamesController.dispose();
    memoryKeywordsController.dispose();
    interestsController.dispose();
    transferInfoController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    // 첫 번째 학교는 필수 입력
    if (schools.isEmpty) return false;
    final firstSchool = schools[0];
    return firstSchool.name.isNotEmpty &&
        firstSchool.schoolType != null &&
        firstSchool.admissionYear != null;
  }

  Future<void> _submitSignup() async {
    final form = widget.data;

    final birthYear = int.tryParse(form.birthYear);
    final currentYear = DateTime.now().year;

    if (birthYear == null || birthYear < 1900 || birthYear > currentYear) {
      _showError('출생년도를 올바르게 입력해주세요.');
      return;
    }

    // 여러 학교 정보 검증
    if (schools.isEmpty || schools[0].name.isEmpty) {
      _showError('학교 정보를 입력해주세요.');
      return;
    }

    // 모든 학교 정보 검증
    for (var school in schools) {
      if (school.name.isEmpty) {
        _showError('학교명을 입력해주세요.');
        return;
      }
      if (school.admissionYear == null) {
        _showError('입학년도를 올바르게 입력해주세요.');
        return;
      }
    }

    // 여러 학교 정보를 JSON 형식으로 변환
    final schoolsJson = schools.map((school) => {
      'name': school.name,
      'school_type': school.schoolType,
      'admission_year': school.admissionYear,
    }).toList();

    // 첫 번째 학교 정보는 하위 호환성을 위해 school_name에도 저장
    final firstSchool = schools[0];

    final payload = {
      'login_id': form.loginId,
      'email': form.loginId,
      'password': form.password,
      'name': form.name,
      'birth_year': birthYear,
      'gender': form.gender.isNotEmpty ? form.gender : null,
      'region': form.baseRegion,
      'school_name': schoolNameController.text,
      'school_type': selectedSchoolLevel,
      'admission_year': admissionYear,
    };

    try {
      await ApiService.signup(payload);

      if (!mounted) return;

      // 신규 사용자 플래그 ON
      AppState.isNewUser = true;

      // 자동 로그인
      try {
        final token = await ApiService.login(form.loginId, form.password);
        AppState.token = token;

        final user = await ApiService.getMyInfo();
        await AppState.login(token, user);
      } catch (e) {
        debugPrint("자동 로그인 실패: $e");
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('intersection에 오신 것을 환영합니다!'),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainTabScreen(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입 - 3단계'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 진행도 표시
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('진행도', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '단계 3/3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.66, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (_, value, __) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Colors.black),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('학교 정보 입력',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    '학교 정보를 입력해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // 학교명 (자동완성)
                  const Text('학교명',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return await ApiService.searchSchools(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          schoolNameController.text = selection;
                          setState(() {}); 
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (schoolNameController.text.isNotEmpty && 
                              controller.text.isEmpty) {
                            controller.text = schoolNameController.text;
                          }
                          controller.addListener(() {
                            schoolNameController.text = controller.text;
                            setState(() {}); 
                          });

                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              hintText: '예: OO초등학교',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_city_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: constraints.maxWidth,
                                color: Colors.white,
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(option),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // 🔥 [수정] 입학년도 (휠 피커 적용)
                  const Text('입학년도',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showEntryYearPicker, // 탭하면 휠 피커 열기
                    child: AbsorbPointer(
                      child: TextField(
                        controller: entryYearController,
                        decoration: InputDecoration(
                          hintText: '연도 선택',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(height: 32),

                  const Text('추가 정보 (선택사항)',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text('별명들 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nicknamesController,
                    decoration: InputDecoration(
                      hintText: '예: 철수, 공대로봇',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon:
                          const Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('기억 키워드 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoryKeywordsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '예: 운동회, 소풍, 학교축제',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.favorite_border),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('관심사 (선택사항)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: interestsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '예: 만화, 야구, 힙합',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.star_border),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canProceed() ? _submitSignup : null,
                child: const Text('회원가입 완료'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}