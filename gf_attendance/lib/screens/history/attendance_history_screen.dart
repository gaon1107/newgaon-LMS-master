import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/state_model.dart';
import '../../utils/app_constants.dart';
import '../../widgets/loading_widget.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceHistory();
    });
  }

  Future<void> _loadAttendanceHistory() async {
    final provider = context.read<AttendanceProvider>();

    if (_selectedStudentId != null) {
      await provider.loadStudentStates(
        _selectedStudentId!,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
    } else {
      await provider.loadTodayStates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '출결 이력',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSans',
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 필터 정보 표시
              _buildFilterInfo(provider),

              // 출결 이력 목록
              Expanded(
                child: _buildAttendanceHistoryList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAttendanceHistory,
        backgroundColor: const Color(AppConstants.primaryColorValue),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterInfo(AttendanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20.sp,
                color: const Color(AppConstants.primaryColorValue),
              ),
              SizedBox(width: 8.w),
              Text(
                '조회 조건',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.textPrimaryColor),
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Row(
            children: [
              Expanded(
                child: Text(
                  '기간: ${_formatDate(_selectedStartDate)} ~ ${_formatDate(_selectedEndDate)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(AppConstants.textSecondaryColor),
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
              if (_selectedStudentId != null) ...[
                SizedBox(width: 16.w),
                Text(
                  '학생: ${_getStudentName(_selectedStudentId!, provider)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(AppConstants.textSecondaryColor),
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 8.h),

          Row(
            children: [
              Text(
                '총 ${provider.stateList.length}건',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(AppConstants.primaryColorValue),
                  fontFamily: 'NotoSans',
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showFilterDialog,
                icon: Icon(
                  Icons.tune,
                  size: 16.sp,
                  color: const Color(AppConstants.primaryColorValue),
                ),
                label: Text(
                  '필터 변경',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(AppConstants.primaryColorValue),
                    fontFamily: 'NotoSans',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistoryList(AttendanceProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget(message: '출결 이력을 불러오는 중...');
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
              onPressed: _loadAttendanceHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (provider.stateList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: const Color(AppConstants.textSecondaryColor),
            ),
            SizedBox(height: 16.h),
            Text(
              '출결 이력이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '다른 기간을 선택해보세요',
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

    // 날짜별로 그룹화
    final groupedStates = _groupStatesByDate(provider.stateList);

    return RefreshIndicator(
      onRefresh: _loadAttendanceHistory,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: groupedStates.length,
        itemBuilder: (context, index) {
          final date = groupedStates.keys.elementAt(index);
          final states = groupedStates[date]!;

          return _buildDateSection(date, states);
        },
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<StateModel> states) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16.sp,
                color: const Color(AppConstants.primaryColorValue),
              ),
              SizedBox(width: 8.w),
              Text(
                '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} (${_getWeekday(date.weekday)})',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.primaryColorValue),
                  fontFamily: 'NotoSans',
                ),
              ),
              const Spacer(),
              Text(
                '${states.length}건',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(AppConstants.primaryColorValue),
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
        ),

        // 출결 기록 목록
        ...states.map((state) => _buildStateCard(state)),

        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildStateCard(StateModel state) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // 상태 아이콘
            CircleAvatar(
              radius: 20.r,
              backgroundColor: _getStateColor(state.state),
              child: Icon(
                _getStateIcon(state.state),
                size: 20.sp,
                color: Colors.white,
              ),
            ),

            SizedBox(width: 16.w),

            // 학생 정보 및 출결 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.studentName ?? '알 수 없음',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(AppConstants.textPrimaryColor),
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStateColor(state.state).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          state.statusText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStateColor(state.state),
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: const Color(AppConstants.textSecondaryColor),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        state.taggedAt != null
                            ? '${state.taggedAt!.hour.toString().padLeft(2, '0')}:${state.taggedAt!.minute.toString().padLeft(2, '0')}'
                            : '시간 미상',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Icon(
                        state.isKeypad ? Icons.dialpad : Icons.face,
                        size: 14.sp,
                        color: const Color(AppConstants.textSecondaryColor),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        state.isKeypad ? '키패드' : '얼굴인식',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ],
                  ),

                  if (state.comment != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      state.comment!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(AppConstants.textSecondaryColor),
                        fontStyle: FontStyle.italic,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setBottomSheetState) {
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

              // 제목
              Text(
                '조회 조건 설정',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(AppConstants.textPrimaryColor),
                  fontFamily: 'NotoSans',
                ),
              ),
              SizedBox(height: 24.h),

              // 기간 선택
              _buildDatePicker('시작일', _selectedStartDate, (date) {
                setBottomSheetState(() {
                  _selectedStartDate = date;
                });
              }),
              SizedBox(height: 16.h),

              _buildDatePicker('종료일', _selectedEndDate, (date) {
                setBottomSheetState(() {
                  _selectedEndDate = date;
                });
              }),
              SizedBox(height: 24.h),

              // 학생 선택
              Consumer<AttendanceProvider>(
                builder: (context, provider, child) {
                  return _buildStudentDropdown(provider, setBottomSheetState);
                },
              ),

              SizedBox(height: 32.h),

              // 적용 버튼
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {});
                        _loadAttendanceHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColorValue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '적용',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(String label, DateTime selectedDate, Function(DateTime) onDateSelected) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSans',
        ),
      ),
      subtitle: Text(
        _formatDate(selectedDate),
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(AppConstants.primaryColorValue),
          fontFamily: 'NotoSans',
        ),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
    );
  }

  Widget _buildStudentDropdown(AttendanceProvider provider, StateSetter setBottomSheetState) {
    return ListTile(
      title: Text(
        '학생 선택',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSans',
        ),
      ),
      subtitle: Text(
        _selectedStudentId == null
            ? '전체 학생'
            : _getStudentName(_selectedStudentId!, provider),
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(AppConstants.primaryColorValue),
          fontFamily: 'NotoSans',
        ),
      ),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('학생 선택'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('전체 학생'),
                    leading: Radio<String?>(
                      value: null,
                      groupValue: _selectedStudentId,
                      onChanged: (value) {
                        setBottomSheetState(() {
                          _selectedStudentId = value;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ...provider.studentList.map((student) => ListTile(
                    title: Text(student.name),
                    subtitle: Text('학번: ${student.studentNumber}'),
                    leading: Radio<String?>(
                      value: student.id,
                      groupValue: _selectedStudentId,
                      onChanged: (value) {
                        setBottomSheetState(() {
                          _selectedStudentId = value;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper 메서드들
  Map<DateTime, List<StateModel>> _groupStatesByDate(List<StateModel> states) {
    final grouped = <DateTime, List<StateModel>>{};

    for (final state in states) {
      if (state.taggedAt != null) {
        final date = DateTime(
          state.taggedAt!.year,
          state.taggedAt!.month,
          state.taggedAt!.day,
        );

        if (!grouped.containsKey(date)) {
          grouped[date] = [];
        }
        grouped[date]!.add(state);
      }
    }

    // 날짜 순으로 정렬 (최신순)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedMap = <DateTime, List<StateModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  String _getStudentName(String studentId, AttendanceProvider provider) {
    final student = provider.studentList
        .where((s) => s.id == studentId)
        .firstOrNull;
    return student?.name ?? '알 수 없음';
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

  IconData _getStateIcon(int state) {
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
}