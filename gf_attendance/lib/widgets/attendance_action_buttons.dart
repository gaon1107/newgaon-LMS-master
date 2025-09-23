import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';
import 'custom_button.dart';

class AttendanceActionButtons extends StatelessWidget {
  const AttendanceActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출결 체크',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.textPrimaryColor),
          ),
        ),

        SizedBox(height: 16.h),

        // 상단 버튼들 (얼굴인식, 키패드)
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.face,
                label: '얼굴인식',
                subtitle: '카메라로 출결',
                backgroundColor: const Color(AppConstants.primaryColorValue),
                onPressed: () => _handleFaceRecognition(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.dialpad,
                label: '키패드',
                subtitle: '번호로 출결',
                backgroundColor: const Color(AppConstants.accentColorValue),
                onPressed: () => _handleKeypadEntry(context),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 하단 버튼들 (수동 입력, 출결 현황)
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.edit,
                label: '수동 입력',
                subtitle: '직접 입력',
                backgroundColor: Colors.orange,
                onPressed: () => _handleManualEntry(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.list_alt,
                label: '출결 현황',
                subtitle: '전체 보기',
                backgroundColor: Colors.grey.shade600,
                onPressed: () => _handleViewAttendance(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 80.h,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24.sp,
                  color: Colors.white,
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFaceRecognition(BuildContext context) {
    // TODO: 얼굴인식 화면으로 이동
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.face,
              color: const Color(AppConstants.primaryColorValue),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            const Text('얼굴인식 출결'),
          ],
        ),
        content: const Text('얼굴인식을 통한 출결 체크 기능입니다.\n\n카메라 권한이 필요하며, 등록된 학생의 얼굴을 인식하여 자동으로 출결을 처리합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 얼굴인식 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('얼굴인식 기능은 추후 구현 예정입니다')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  void _handleKeypadEntry(BuildContext context) {
    // TODO: 키패드 입력 화면으로 이동
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.dialpad,
              color: const Color(AppConstants.accentColorValue),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            const Text('키패드 출결'),
          ],
        ),
        content: const Text('학번을 직접 입력하여 출결 체크하는 기능입니다.\n\n학생이 본인의 학번을 입력하면 출결이 자동으로 처리됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 키패드 입력 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('키패드 입력 기능은 추후 구현 예정입니다')),
              );
            },
            icon: const Icon(Icons.keyboard),
            label: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  void _handleManualEntry(BuildContext context) {
    // TODO: 수동 입력 화면으로 이동
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.orange,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            const Text('수동 입력'),
          ],
        ),
        content: const Text('관리자가 직접 학생의 출결 상태를 입력하는 기능입니다.\n\n학생을 검색하고 출결 상태를 선택하여 처리할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 수동 입력 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수동 입력 기능은 추후 구현 예정입니다')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  void _handleViewAttendance(BuildContext context) {
    // TODO: 출결 현황 화면으로 이동
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.list_alt,
              color: Colors.grey.shade600,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            const Text('출결 현황'),
          ],
        ),
        content: const Text('전체 학생의 출결 현황을 확인하는 기능입니다.\n\n날짜별, 학생별, 강의별로 출결 기록을 조회하고 통계를 확인할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 출결 현황 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('출결 현황 기능은 추후 구현 예정입니다')),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text('보기'),
          ),
        ],
      ),
    );
  }
}