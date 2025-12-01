// intersection-frontend/lib/config/api_config.dart

import 'package:flutter/foundation.dart';

/// 앱 환경 구분용 enum
enum AppEnvironment {
  dev,
  prod,
}

class ApiConfig {
  /// 빌드 시점에 넘기는 환경 값
  /// flutter build ... --dart-define=APP_ENV=dev|prod
  static const String _envString =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// API_BASE_URL을 직접 지정할 수 있는 옵션
  /// flutter build ... --dart-define=API_BASE_URL=...
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

  /// 최종 API Base URL
  static String get baseUrl {
    // 1순위: 명시적으로 dart-define으로 지정한 값
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    // 2순위: 환경별 기본값
    switch (environment) {
      case AppEnvironment.dev:
        // 로컬 FastAPI
        return 'http://127.0.0.1:8000';
      case AppEnvironment.prod:
        // Azure App Service 운영 API
        return 'https://intersection-api-balbudoong-main-ezeqgpdwehcfcvbm.canadacentral-01.azurewebsites.net';
    }
  }

  static bool get isProd => environment == AppEnvironment.prod;

  /// 로그 출력 여부 등
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
