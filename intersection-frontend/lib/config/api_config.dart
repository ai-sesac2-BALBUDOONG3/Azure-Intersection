// lib/config/api_config.dart

import 'package:flutter/foundation.dart';

/// 앱 환경 구분용 enum
enum AppEnvironment {
  dev,
  prod,
}

class ApiConfig {
  /// flutter build/run 시 넘기는 ENV (없으면 기본 prod)
  static const String _envString =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  /// 필요하면 API_BASE_URL로 완전히 덮어쓸 수 있는 옵션
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static AppEnvironment get environment {
    switch (_envString.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  /// ✅ 실제 사용하는 Azure App Service 주소 (운영)
  static const String _azureBaseUrl =
      'https://intersection-api-balbudoong-dvaefbfhbychg9dc.canadacentral-01.azurewebsites.net';

  /// 최종 API Base URL
  static String get baseUrl {
    // 1순위: dart-define 으로 직접 지정한 값
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    // 2순위: 환경값 (지금은 dev/prod 모두 Azure로 통일)
    switch (environment) {
      case AppEnvironment.dev:
        // 🟦 개발 환경도 Azure 운영 API 사용
        return _azureBaseUrl;
      case AppEnvironment.prod:
        // 🟥 운영 환경 역시 동일한 Azure 운영 API 사용
        return _azureBaseUrl;
    }
  }

  static bool get isProd => environment == AppEnvironment.prod;

  /// 비운영일 때만 로그 활성화 (지금은 dev/prod 둘 다 Azure지만, dev일 땐 로그 ON)
  static bool get enableLogging => !isProd;

  /// 디버깅용: 현재 설정 로그
  static void debugPrintConfig() {
    if (kDebugMode) {
      debugPrint('[ApiConfig] ENV=$_envString '
          'overrideBaseUrl=$_overrideBaseUrl '
          'baseUrl=$baseUrl');
    }
  }
}
