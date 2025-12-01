// intersection-frontend/lib/config/api_config.dart

import 'package:flutter/foundation.dart';

/// 운영/개발 환경 구분용 enum
enum AppEnvironment {
  dev,
  prod,
}

class ApiConfig {
  /// 빌드 시점에 넘기는 환경 값
  /// flutter run/build 명령어에서 --dart-define=APP_ENV=dev|prod
  static const String _envString =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// 필요 시 강제로 API_BASE_URL를 지정할 수도 있음
  /// flutter build web ... --dart-define=API_BASE_URL=https://custom-api...
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
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

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

  /// 로그 출력 여부 등에도 활용 가능
  static bool get enableLogging => !isProd;
}
