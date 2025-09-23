import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/attendance/student_list_screen.dart';
import '../screens/attendance/attendance_method_screen.dart';
import '../screens/history/attendance_history_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String studentList = '/student-list';
  static const String attendanceMethod = '/attendance-method';
  static const String attendanceHistory = '/attendance-history';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      main: (context) => const MainScreen(),
      studentList: (context) => const StudentListScreen(),
      attendanceMethod: (context) => const AttendanceMethodScreen(),
      attendanceHistory: (context) => const AttendanceHistoryScreen(),
      settings: (context) => const SettingsScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case main:
        return MaterialPageRoute(builder: (context) => const MainScreen());
      case studentList:
        return MaterialPageRoute(builder: (context) => const StudentListScreen());
      case attendanceMethod:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => AttendanceMethodScreen(
            selectedStudent: args?['selectedStudent'],
          ),
        );
      case attendanceHistory:
        return MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen());
      case settings:
        return MaterialPageRoute(builder: (context) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}