import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/attendance_service.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';

void main() {
  runApp(const GFAttendanceApp());
}

class GFAttendanceApp extends StatelessWidget {
  const GFAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X 기준
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('ko', 'KR'),
        ),
      ),
    );
  }
}