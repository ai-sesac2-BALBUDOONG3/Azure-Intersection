// lib/screens/chat/services/chat_block_service.dart

import '../../../services/api_service.dart';

/// 채팅 차단/신고 상태 관리 서비스
class ChatBlockService {
  /// ✅ 차단 상태 확인
  ///
  /// - 백엔드 `/moderation/is-blocked/{user_id}` 응답(JSON)을 받아서
  ///   - is_blocked
  ///   - i_blocked_them
  ///   - they_blocked_me
  ///   셋 중 하나라도 true이면 `true` 반환
  /// - 에러가 나면 안전하게 false
  static Future<bool> checkBlockStatus(int friendId) async {
    try {
      final result = await ApiService.checkIfBlocked(friendId);

      // ApiService.checkIfBlocked는 Map<String, dynamic>을 반환한다고 가정
      final isBlocked = result['is_blocked'] == true ||
          result['i_blocked_them'] == true ||
          result['they_blocked_me'] == true;

      return isBlocked;
    } catch (e) {
      // 네트워크 에러 등 발생 시, UI가 죽지 않도록 false
      return false;
    }
  }

  /// ✅ 신고 상태 확인
  ///
  /// - 백엔드 `/moderation/my-reports/{user_id}` 응답(JSON)을 받아서
  ///   - has_reported == true 이거나
  ///   - id 필드가 존재하면 신고된 것으로 판단
  /// - 반환값 형식:
  ///   {
  ///     'isReported': bool,
  ///     'reportId': int?  // 없으면 null
  ///   }
  static Future<Map<String, dynamic>> checkReportStatus(int friendId) async {
    try {
      final report = await ApiService.checkMyReport(friendId);

      // 예시 응답 형태 가정:
      // 1) {"has_reported": false}
      // 2) {"has_reported": true, "id": 123, ...}
      final bool hasReported =
          report['has_reported'] == true || report['id'] != null;

      final reportId = report['id'];

      return {
        'isReported': hasReported,
        'reportId': reportId,
      };
    } catch (e) {
      return {
        'isReported': false,
        'reportId': null,
      };
    }
  }
}
