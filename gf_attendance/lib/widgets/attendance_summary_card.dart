import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../utils/app_constants.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceService>(
      builder: (context, attendanceService, child) {
        final todayAttendance = attendanceService.getTodayAttendance();
        final summary = _calculateSummary(todayAttendance);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘 출결 요약',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(AppConstants.textPrimaryColor),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.primaryColorValue),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${DateTime.now().month}/${DateTime.now().day}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // 총 출결 수
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 24.sp,
                      color: const Color(AppConstants.primaryColorValue),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '총 출결 수: ${summary['total']}건',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(AppConstants.textPrimaryColor),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // 출결 상태별 통계
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem(
                        '출석',
                        summary['present']!,
                        const Color(AppConstants.successColor),
                        Icons.check_circle_outline,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatusItem(
                        '하원',
                        summary['absent']!,
                        const Color(AppConstants.primaryColorValue),
                        Icons.logout,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem(
                        '지각',
                        summary['late']!,
                        Colors.orange,
                        Icons.schedule,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatusItem(
                        '조퇴',
                        summary['earlyLeave']!,
                        const Color(AppConstants.errorColor),
                        Icons.exit_to_app,
                      ),
                    ),
                  ],
                ),

                if (summary['total']! > 0) ...[
                  SizedBox(height: 16.h),

                  // 출석률 표시
                  _buildAttendanceRate(summary),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
          SizedBox(height: 4.h),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRate(Map<String, int> summary) {
    final total = summary['total']!;
    final present = summary['present']!;
    final rate = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColorValue).withOpacity(0.1),
            const Color(AppConstants.accentColorValue).withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '출석률',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(AppConstants.textPrimaryColor),
                ),
              ),
              Text(
                '$rate%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              rate >= 90
                  ? const Color(AppConstants.successColor)
                  : rate >= 70
                      ? Colors.orange
                      : const Color(AppConstants.errorColor),
            ),
            minHeight: 6.h,
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateSummary(List<dynamic> attendanceList) {
    int total = attendanceList.length;
    int present = 0;
    int absent = 0;
    int late = 0;
    int earlyLeave = 0;

    for (var attendance in attendanceList) {
      switch (attendance.state) {
        case AppConstants.stateAttendIn:
        case AppConstants.stateAttendClass:
          present++;
          break;
        case AppConstants.stateLeaveOut:
          absent++;
          break;
        case AppConstants.stateAttendLate:
          late++;
          break;
        case AppConstants.stateLeaveEarly:
          earlyLeave++;
          break;
      }
    }

    return {
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
      'earlyLeave': earlyLeave,
    };
  }
}