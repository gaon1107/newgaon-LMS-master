import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/student_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/routes.dart';
import '../../widgets/loading_widget.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadStudentList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '학생 목록',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSans',
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 검색 바
              _buildSearchBar(provider),

              // 학생 목록
              Expanded(
                child: _buildStudentList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(AttendanceProvider provider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '학생 이름 또는 학번으로 검색...',
          hintStyle: TextStyle(
            fontSize: 16.sp,
            color: const Color(AppConstants.textSecondaryColor),
            fontFamily: 'NotoSans',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(AppConstants.textSecondaryColor),
            size: 24.sp,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    provider.loadStudentList();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: const Color(AppConstants.textSecondaryColor),
                    size: 20.sp,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: 'NotoSans',
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });

          // 검색어가 비어있으면 전체 목록 로드
          if (value.isEmpty) {
            provider.loadStudentList();
          } else {
            // 검색 실행
            provider.searchStudents(value);
          }
        },
      ),
    );
  }

  Widget _buildStudentList(AttendanceProvider provider) {
    if (provider.isLoading && provider.studentList.isEmpty) {
      return const LoadingWidget(message: '학생 목록을 불러오는 중...');
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: const Color(AppConstants.errorColor),
            ),
            SizedBox(height: 16.h),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(AppConstants.errorColor),
                fontFamily: 'NotoSans',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => provider.loadStudentList(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 검색 결과에 따른 필터링
    final filteredStudents = _searchQuery.isEmpty
        ? provider.studentList
        : provider.studentList.where((student) {
            final query = _searchQuery.toLowerCase();
            return student.name.toLowerCase().contains(query) ||
                   student.studentNumber.toLowerCase().contains(query);
          }).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64.sp,
              color: const Color(AppConstants.textSecondaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty
                  ? '등록된 학생이 없습니다.'
                  : '검색 결과가 없습니다.',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isEmpty
                  ? '학생을 먼저 등록해주세요.'
                  : '다른 검색어를 시도해보세요.',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadStudentList(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          return _buildStudentCard(student, provider);
        },
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student, AttendanceProvider provider) {
    // 학생의 오늘 최신 출결 상태 확인
    final latestState = provider.getStudentLatestState(student.id);
    final todayStates = provider.selectedStudentTodayStates;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showAttendanceDialog(student, provider),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 학생 아바타
              CircleAvatar(
                radius: 28.r,
                backgroundColor: student.profileImage != null
                    ? Colors.transparent
                    : const Color(AppConstants.primaryColorValue),
                backgroundImage: student.profileImage != null
                    ? NetworkImage(student.profileImage!)
                    : null,
                child: student.profileImage == null
                    ? Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSans',
                        ),
                      )
                    : null,
              ),

              SizedBox(width: 16.w),

              // 학생 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(AppConstants.textPrimaryColor),
                        fontFamily: 'NotoSans',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '학번: ${student.studentNumber}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(AppConstants.textSecondaryColor),
                        fontFamily: 'NotoSans',
                      ),
                    ),
                    if (student.className != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '학급: ${student.className}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 출결 상태 표시
              Column(
                children: [
                  if (latestState != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStateColor(latestState.state).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        latestState.statusText,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStateColor(latestState.state),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (latestState.taggedAt != null)
                      Text(
                        '${latestState.taggedAt!.hour.toString().padLeft(2, '0')}:${latestState.taggedAt!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: const Color(AppConstants.textSecondaryColor),
                    size: 24.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceDialog(StudentModel student, AttendanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _buildAttendanceBottomSheet(student, provider),
    );
  }

  Widget _buildAttendanceBottomSheet(StudentModel student, AttendanceProvider provider) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // 학생 정보
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: const Color(AppConstants.primaryColorValue),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(AppConstants.textPrimaryColor),
                        fontFamily: 'NotoSans',
                      ),
                    ),
                    Text(
                      '학번: ${student.studentNumber}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(AppConstants.textSecondaryColor),
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // 출결 상태 버튼들
          Text(
            '출결 상태 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.textPrimaryColor),
              fontFamily: 'NotoSans',
            ),
          ),
          SizedBox(height: 16.h),

          _buildStateButton(
            '등원',
            Icons.login,
            const Color(AppConstants.successColor),
            () => _recordAttendance(student, AppConstants.stateAttendIn, provider),
          ),
          SizedBox(height: 12.h),

          _buildStateButton(
            '수업출석',
            Icons.event_available,
            const Color(AppConstants.accentColorValue),
            () => _recordAttendance(student, AppConstants.stateAttendClass, provider),
          ),
          SizedBox(height: 12.h),

          _buildStateButton(
            '하원',
            Icons.logout,
            const Color(AppConstants.primaryColorValue),
            () => _recordAttendance(student, AppConstants.stateLeaveOut, provider),
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildStateButton(
                  '지각',
                  Icons.schedule,
                  Colors.orange,
                  () => _recordAttendance(student, AppConstants.stateAttendLate, provider),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStateButton(
                  '조퇴',
                  Icons.exit_to_app,
                  const Color(AppConstants.errorColor),
                  () => _recordAttendance(student, AppConstants.stateLeaveEarly, provider),
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildStateButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20.sp),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Future<void> _recordAttendance(
    StudentModel student,
    int state,
    AttendanceProvider provider,
  ) async {
    Navigator.of(context).pop(); // 바텀시트 닫기

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('출결을 기록하는 중...'),
          ],
        ),
      ),
    );

    final success = await provider.recordAttendance(
      studentId: student.id,
      state: state,
      isKeypad: false, // 수동 입력
    );

    // 로딩 다이얼로그 닫기
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} 학생의 출결이 기록되었습니다.'),
            backgroundColor: const Color(AppConstants.successColor),
          ),
        );
        // 메인 화면으로 돌아가기
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? '출결 기록에 실패했습니다.'),
            backgroundColor: const Color(AppConstants.errorColor),
          ),
        );
      }
    }
  }

  Color _getStateColor(int state) {
    switch (state) {
      case AppConstants.stateAttendIn:
      case AppConstants.stateAttendClass:
        return const Color(AppConstants.successColor);
      case AppConstants.stateAttendLate:
        return Colors.orange;
      case AppConstants.stateLeaveOut:
        return const Color(AppConstants.primaryColorValue);
      case AppConstants.stateLeaveEarly:
        return const Color(AppConstants.errorColor);
      default:
        return Colors.grey;
    }
  }
}