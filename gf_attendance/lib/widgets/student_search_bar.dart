import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../models/student_model.dart';
import '../utils/app_constants.dart';
import 'custom_text_field.dart';

class StudentSearchBar extends StatefulWidget {
  final Function(StudentModel?)? onStudentSelected;
  final bool enabled;
  final String? initialQuery;

  const StudentSearchBar({
    super.key,
    this.onStudentSelected,
    this.enabled = true,
    this.initialQuery,
  });

  @override
  State<StudentSearchBar> createState() => _StudentSearchBarState();
}

class _StudentSearchBarState extends State<StudentSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<StudentModel> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  StudentModel? _selectedStudent;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _showResults = query.isNotEmpty;
    });

    final attendanceService = context.read<AttendanceService>();
    final allStudents = attendanceService.studentList;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }

    // 검색 수행 (이름, 학번으로 검색)
    final results = allStudents.where((student) {
      final name = student.name.toLowerCase();
      final studentNumber = student.studentNumber.toLowerCase();
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) ||
             studentNumber.contains(searchQuery);
    }).take(10).toList(); // 최대 10개 결과만 표시

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectStudent(StudentModel student) {
    setState(() {
      _selectedStudent = student;
      _searchController.text = '${student.name} (${student.studentNumber})';
      _showResults = false;
    });

    _focusNode.unfocus();
    widget.onStudentSelected?.call(student);
  }

  void _clearSearch() {
    setState(() {
      _selectedStudent = null;
      _searchResults = [];
      _showResults = false;
    });

    _searchController.clear();
    widget.onStudentSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색 입력 필드
        CustomSearchField(
          controller: _searchController,
          hintText: '학생 이름 또는 학번으로 검색',
          enabled: widget.enabled,
          onChanged: _performSearch,
          onClear: _clearSearch,
          onTap: () {
            if (_searchController.text.isNotEmpty) {
              setState(() {
                _showResults = true;
              });
            }
          },
          showClearButton: true,
        ),

        // 검색 결과 목록
        if (_showResults) ...[
          SizedBox(height: 8.h),
          _buildSearchResults(),
        ],

        // 선택된 학생 정보
        if (_selectedStudent != null) ...[
          SizedBox(height: 12.h),
          _buildSelectedStudentCard(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearching
          ? Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '검색 중...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(AppConstants.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            )
          : _searchResults.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 16.sp,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '검색 결과가 없습니다',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final student = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(AppConstants.primaryColorValue),
                        radius: 20.r,
                        child: Text(
                          student.name.isNotEmpty ? student.name[0] : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(AppConstants.textPrimaryColor),
                        ),
                      ),
                      subtitle: Text(
                        '학번: ${student.studentNumber}${student.className != null ? ' • ${student.className}' : ''}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(AppConstants.textSecondaryColor),
                        ),
                      ),
                      onTap: () => _selectStudent(student),
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSelectedStudentCard() {
    if (_selectedStudent == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 학생 아바타
          CircleAvatar(
            backgroundColor: const Color(AppConstants.primaryColorValue),
            radius: 24.r,
            child: Text(
              _selectedStudent!.name.isNotEmpty ? _selectedStudent!.name[0] : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // 학생 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedStudent!.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(AppConstants.textPrimaryColor),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '학번: ${_selectedStudent!.studentNumber}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(AppConstants.textSecondaryColor),
                  ),
                ),
                if (_selectedStudent!.className != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '반: ${_selectedStudent!.className}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(AppConstants.textSecondaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 선택 취소 버튼
          IconButton(
            onPressed: _clearSearch,
            icon: Icon(
              Icons.close,
              size: 20.sp,
              color: const Color(AppConstants.textSecondaryColor),
            ),
            constraints: BoxConstraints.tightFor(
              width: 32.w,
              height: 32.w,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}