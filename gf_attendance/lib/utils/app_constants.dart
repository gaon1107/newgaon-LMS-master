class AppConstants {
  // App Information
  static const String appName = '가온 출결관리 시스템';
  static const String appVersion = '1.0.0';
  static const String packageName = 'kr.newgaon.gfkids';

  // API Endpoints (Spring Boot 백엔드)
  static const String baseUrl = 'http://localhost:8080';
  static const String stateEndpoint = '/state';
  static const String studentEndpoint = '/student';
  static const String authEndpoint = '/auth';

  // Storage Keys
  static const String userIdKey = 'user_id';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String deviceIdKey = 'device_id';

  // Attendance States (기존 앱과 동일)
  static const int stateAttendIn = 0;      // 등원
  static const int stateAttendClass = 1;   // 수업 출석
  static const int stateLeaveOut = 2;      // 하원
  static const int stateAttendLate = 3;    // 지각
  static const int stateLeaveEarly = 4;    // 조퇴

  // Face Recognition Settings
  static const double faceDetectionThreshold = 0.8;
  static const int maxRecognitionAttempts = 3;
  static const int recognitionTimeoutSeconds = 30;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // Colors (기존 앱 색상과 동일하게 설정)
  static const int primaryColorValue = 0xFF2E7D32; // 가온 그린
  static const int accentColorValue = 0xFF4CAF50;
  static const int backgroundColor = 0xFFF5F5F5;
  static const int textPrimaryColor = 0xFF212121;
  static const int textSecondaryColor = 0xFF757575;
  static const int errorColor = 0xFFD32F2F;
  static const int successColor = 0xFF388E3C;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Network Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 10);
}