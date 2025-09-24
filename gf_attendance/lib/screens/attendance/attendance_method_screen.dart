import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/student_model.dart';
import '../../utils/app_constants.dart';
import '../../widgets/loading_widget.dart';

class AttendanceMethodScreen extends StatefulWidget {
  final StudentModel? selectedStudent;
  final String? mode;

  const AttendanceMethodScreen({
    Key? key,
    this.selectedStudent,
    this.mode,
  }) : super(key: key);

  @override
  State<AttendanceMethodScreen> createState() => _AttendanceMethodScreenState();
}

class _AttendanceMethodScreenState extends State<AttendanceMethodScreen> {
  final TextEditingController _keypadController = TextEditingController();
  bool _isRecognizing = false;

  @override
  void initState() {
    super.initState();

    // 선택된 학생이 있으면 Provider에 설정
    if (widget.selectedStudent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AttendanceProvider>().setSelectedStudent(widget.selectedStudent);
      });
    }
  }

  @override
  void dispose() {
    _keypadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '출결 등록',
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
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 현재 출결 상태 표시
                _buildCurrentStateCard(provider),

                SizedBox(height: 32.h),

                // 선택된 학생 표시 (있는 경우)
                if (provider.selectedStudent != null) ...[
                  _buildSelectedStudentCard(provider.selectedStudent!),
                  SizedBox(height: 32.h),
                ],

                // 출결 방식 선택
                if (widget.mode == null) ...[
                  _buildMethodSelectionSection(),
                ] else if (widget.mode == 'face_recognition') ...[
                  _buildFaceRecognitionRedirectSection(provider),
                ] else if (widget.mode == 'keypad') ...[
                  _buildKeypadSection(provider),
                ],

                SizedBox(height: 32.h),

                // 출결 상태 선택 버튼들
                if (provider.selectedStudent != null) ...[
                  _buildAttendanceStateButtons(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStateCard(AttendanceProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppConstants.primaryColorValue),
              const Color(AppConstants.accentColorValue),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.today,
              size: 32.sp,
              color: Colors.white,
            ),
            SizedBox(height: 12.h),
            Text(
              '현재 출결 상태',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white70,
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              provider.currentStateText,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedStudentCard(StudentModel student) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
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
                    '선택된 학생',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(AppConstants.textSecondaryColor),
                      fontFamily: 'NotoSans',
                    ),
                  ),
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
            IconButton(
              onPressed: () {
                context.read<AttendanceProvider>().clearSelectedStudent();
              },
              icon: Icon(
                Icons.clear,
                color: const Color(AppConstants.textSecondaryColor),
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelectionSection() {
    return Column(
      children: [
        Text(
          '출결 방식을 선택하세요',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.textPrimaryColor),
            fontFamily: 'NotoSans',
          ),
        ),
        SizedBox(height: 24.h),

        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                '얼굴인식',
                Icons.face_retouching_natural,
                const Color(AppConstants.primaryColorValue),
                '카메라를 통한\n얼굴 인식',
                () => _navigateToFaceRecognition(),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildMethodCard(
                '키패드 입력',
                Icons.dialpad,
                const Color(AppConstants.accentColorValue),
                '학번을 직접\n입력',
                () => _showKeypadDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(24.w),
          height: 160.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.sp,
                color: color,
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.textPrimaryColor),
                  fontFamily: 'NotoSans',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(AppConstants.textSecondaryColor),
                  fontFamily: 'NotoSans',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceRecognitionRedirectSection(AttendanceProvider provider) {
    return Column(
      children: [
        Text(
          '얼굴인식 출결',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.textPrimaryColor),
            fontFamily: 'NotoSans',
          ),
        ),
        SizedBox(height: 24.h),

        // 안내 메시지
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.face_retouching_natural,
                size: 64.sp,
                color: const Color(AppConstants.primaryColorValue),
              ),
              SizedBox(height: 16.h),
              Text(
                '전면 카메라를 사용하여\n얼굴인식 출결을 진행합니다',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(AppConstants.textPrimaryColor),
                  fontFamily: 'NotoSans',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                '현재 출결 모드: ${provider.currentStateText}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(AppConstants.primaryColorValue),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSans',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 24.h),

        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: _navigateToFaceRecognition,
            icon: Icon(Icons.camera_alt, size: 20.sp),
            label: Text(
              '얼굴인식 화면으로 이동',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSans',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadSection(AttendanceProvider provider) {
    return Column(
      children: [
        Text(
          '학번 입력',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.textPrimaryColor),
            fontFamily: 'NotoSans',
          ),
        ),
        SizedBox(height: 24.h),

        TextField(
          controller: _keypadController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: '학번을 입력하세요',
            hintText: '예: 2024001',
            prefixIcon: Icon(
              Icons.numbers,
              color: const Color(AppConstants.primaryColorValue),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(AppConstants.primaryColorValue),
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 18.sp,
            fontFamily: 'NotoSans',
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 24.h),

        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: provider.isLoading ? null : _searchStudentByNumber,
            icon: provider.isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.search, size: 20.sp),
            label: Text(
              provider.isLoading ? '검색 중...' : '학생 검색',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSans',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.accentColorValue),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStateButtons(AttendanceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출결 상태 선택',
          style: TextStyle(
            fontSize: 18.sp,
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
          AppConstants.stateAttendIn,
          provider,
        ),
        SizedBox(height: 12.h),

        _buildStateButton(
          '수업출석',
          Icons.event_available,
          const Color(AppConstants.accentColorValue),
          AppConstants.stateAttendClass,
          provider,
        ),
        SizedBox(height: 12.h),

        _buildStateButton(
          '하원',
          Icons.logout,
          const Color(AppConstants.primaryColorValue),
          AppConstants.stateLeaveOut,
          provider,
        ),
        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: _buildStateButton(
                '지각',
                Icons.schedule,
                Colors.orange,
                AppConstants.stateAttendLate,
                provider,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStateButton(
                '조퇴',
                Icons.exit_to_app,
                const Color(AppConstants.errorColor),
                AppConstants.stateLeaveEarly,
                provider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateButton(
    String text,
    IconData icon,
    Color color,
    int state,
    AttendanceProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: () => _recordAttendance(state, provider),
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

  void _navigateToFaceRecognition() {
    Navigator.of(context).pushNamed(
      '/face_recognition',
      arguments: {
        'mode': widget.mode,
        'selectedStudent': widget.selectedStudent,
      },
    );
  }

  void _showKeypadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학번 입력'),
        content: TextField(
          controller: _keypadController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '학번',
            hintText: '예: 2024001',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchStudentByNumber();
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchStudentByNumber() async {
    final studentNumber = _keypadController.text.trim();

    if (studentNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학번을 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final success = await provider.recordAttendanceByKeypad(
      studentNumber: studentNumber,
      state: provider.currentAttendanceState,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.selectedStudent?.name} 학생의 출결이 기록되었습니다.'),
            backgroundColor: const Color(AppConstants.successColor),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? '출결 기록에 실패했습니다.'),
            backgroundColor: const Color(AppConstants.errorColor),
          ),
        );
      }
    }
  }

  Future<void> _recordAttendance(int state, AttendanceProvider provider) async {
    final student = provider.selectedStudent;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생을 먼저 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await provider.recordAttendance(
      studentId: student.id,
      state: state,
      isKeypad: widget.mode == 'keypad',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} 학생의 출결이 기록되었습니다.'),
            backgroundColor: const Color(AppConstants.successColor),
          ),
        );
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
}