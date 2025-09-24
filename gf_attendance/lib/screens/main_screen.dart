import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../utils/app_constants.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/student_search_bar.dart';
import '../widgets/attendance_action_buttons.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final attendanceService = context.read<AttendanceService>();

    // 오늘 날짜의 출결 데이터와 학생 목록 로드
    await Future.wait([
      attendanceService.fetchStateList(date: DateTime.now()),
      attendanceService.fetchStudentList(),
    ]);
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmDialog();
    if (!confirmed) return;

    try {
      final authService = context.read<AuthService>();
      await authService.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: AppConstants.mediumAnimation,
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<bool> _showLogoutConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppConstants.defaultPadding.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환영 메시지
              _buildWelcomeSection(),

              SizedBox(height: 24.h),

              // 학생 검색
              const StudentSearchBar(),

              SizedBox(height: 24.h),

              // 출결 액션 버튼들
              const AttendanceActionButtons(),

              SizedBox(height: 24.h),

              // 오늘 출결 요약
              _buildTodayAttendanceSection(),

              SizedBox(height: 24.h),

              // 최근 출결 목록
              _buildRecentAttendanceSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppConstants.appName),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadInitialData,
          tooltip: '새로고침',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'logout':
                _handleLogout();
                break;
              case 'settings':
                // TODO: 설정 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('설정 기능은 추후 구현 예정입니다')),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('설정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('로그아웃'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColorValue),
            const Color(AppConstants.accentColorValue),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'NotoSans',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '가온 출결관리 시스템입니다.',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'NotoSans',
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '오늘도 좋은 하루 되세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 출결 현황',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 12.h),
        const AttendanceSummaryCard(),
      ],
    );
  }

  Widget _buildRecentAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 출결 기록',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // TODO: 전체 출결 기록 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('전체 보기 기능은 추후 구현 예정입니다')),
                );
              },
              child: Text(
                '전체 보기',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildRecentAttendanceList(),
      ],
    );
  }

  Widget _buildRecentAttendanceList() {
    return Consumer<AttendanceService>(
      builder: (context, attendanceService, child) {
        if (attendanceService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (attendanceService.error != null) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    attendanceService.error!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final todayAttendance = attendanceService.getTodayAttendance();

        if (todayAttendance.isEmpty) {
          return Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 48.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16.h),
                Text(
                  '오늘 출결 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '출결 체크를 시작해보세요',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todayAttendance.length > 5 ? 5 : todayAttendance.length,
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final attendance = todayAttendance[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(attendance.state),
                  child: Icon(
                    _getStatusIcon(attendance.state),
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  attendance.studentName ?? '알 수 없는 학생',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  '${attendance.stateDescription} • ${_formatTime(attendance.createdAt ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(AppConstants.textSecondaryColor),
                  ),
                ),
                trailing: Icon(
                  attendance.isKeypad ? Icons.dialpad : Icons.face,
                  size: 20.sp,
                  color: const Color(AppConstants.textSecondaryColor),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(int state) {
    switch (state) {
      case AppConstants.stateAttendIn:
      case AppConstants.stateAttendClass:
        return const Color(AppConstants.successColor);
      case AppConstants.stateLeaveOut:
        return const Color(AppConstants.primaryColorValue);
      case AppConstants.stateAttendLate:
        return Colors.orange;
      case AppConstants.stateLeaveEarly:
        return const Color(AppConstants.errorColor);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int state) {
    switch (state) {
      case AppConstants.stateAttendIn:
        return Icons.login;
      case AppConstants.stateAttendClass:
        return Icons.event_available;
      case AppConstants.stateLeaveOut:
        return Icons.logout;
      case AppConstants.stateAttendLate:
        return Icons.schedule;
      case AppConstants.stateLeaveEarly:
        return Icons.exit_to_app;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}