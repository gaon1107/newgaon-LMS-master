import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/attendance_service.dart';
import 'services/gaon_face_service.dart';
import 'services/lms_api_service.dart';
import 'services/audio_service.dart';
import 'services/sync_service.dart';
import 'providers/attendance_provider.dart';
import 'screens/main_attendance_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';
import 'utils/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 방향 고정 (가로 모드)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 시스템 UI 설정
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    // 핵심 서비스들 초기화
    await _initializeServices();
  } catch (e) {
    debugPrint('Service initialization error: $e');
  }

  runApp(const GFAttendanceApp());
}

// 서비스 초기화 함수
Future<void> _initializeServices() async {
  // 가온 얼굴인식 서비스 초기화
  await GaonFaceService.initialize();

  // LMS API 서비스 초기화
  await LmsApiService.initialize();

  // 오디오 서비스 초기화
  await AudioService.initialize();

  // 백그라운드 동기화 서비스 시작
  SyncService.startBackgroundSync();

  debugPrint('All services initialized successfully');
}

class GFAttendanceApp extends StatelessWidget {
  const GFAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X 기준
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          home: const MainAttendanceScreen(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('ko', 'KR'),
          routes: AppRoutes.getRoutes(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}