import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_vo.dart';
import '../services/lms_api_service.dart';
import '../services/gaon_face_service.dart';
import '../services/audio_service.dart';
import '../utils/database_helper.dart';
import '../providers/attendance_provider.dart';
import 'face_enrollment_dialog.dart';

class StudentManagementDialog extends StatefulWidget {
  const StudentManagementDialog({Key? key}) : super(key: key);

  @override
  State<StudentManagementDialog> createState() => _StudentManagementDialogState();
}

class _StudentManagementDialogState extends State<StudentManagementDialog> {
  List<StudentVO> _students = [];
  List<StudentVO> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      // 먼저 서버에서 최신 데이터 가져오기
      final serverStudents = await LmsApiService.getAllStudents();

      if (serverStudents.isNotEmpty) {
        // 로컬 DB 업데이트
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.insertOrUpdateStudents(serverStudents);
        _students = serverStudents;
      } else {
        // 서버 연결 실패 시 로컬 데이터 사용
        final dbHelper = DatabaseHelper.instance;
        _students = await dbHelper.getAllStudents();
      }

      _filteredStudents = _students;
    } catch (e) {
      debugPrint('Failed to load students: $e');
      _showErrorSnackBar('학생 목록을 불러오는데 실패했습니다.');
    }

    setState(() => _isLoading = false);
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) =>
          student.studentName.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query) ||
          student.className.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  Future<void> _refreshStudents() async {
    await _loadStudents();
    _showSuccessSnackBar('학생 목록이 새로고침되었습니다.');
  }

  Future<void> _showFaceEnrollmentDialog(StudentVO student) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FaceEnrollmentDialog(student: student),
    );

    if (result == true) {
      _showSuccessSnackBar('${student.studentName}님의 얼굴이 등록되었습니다.');
      await AudioService.speak('${student.studentName}님의 얼굴 등록이 완료되었습니다.');
    }
  }

  Future<void> _deleteFaceEnrollment(StudentVO student) async {
    final confirm = await _showConfirmDialog(
      '얼굴 정보 삭제',
      '${student.studentName}님의 등록된 얼굴 정보를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
    );

    if (confirm != true) return;

    try {
      final success = await GaonFaceService.deleteFace(student.studentId);

      if (success) {
        _showSuccessSnackBar('${student.studentName}님의 얼굴 정보가 삭제되었습니다.');
        await AudioService.speak('${student.studentName}님의 얼굴 정보가 삭제되었습니다.');
      } else {
        _showErrorSnackBar('얼굴 정보 삭제에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('Failed to delete face enrollment: $e');
      _showErrorSnackBar('얼굴 정보 삭제 중 오류가 발생했습니다.');
    }
  }

  Future<void> _editStudent(StudentVO student) async {
    // 학생 정보 편집 기능 (기본 구현)
    _showInfoSnackBar('학생 정보 편집 기능은 웹에서 이용해주세요.');
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        width: screenSize.width * 0.8,
        height: screenSize.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.people, size: 32, color: Color(0xff215968)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '학생 관리',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff215968),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _refreshStudents,
                  icon: const Icon(Icons.refresh),
                  tooltip: '새로고침',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 검색 바
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '학생 이름, 학번, 반 이름으로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 학생 목록 정보
            Row(
              children: [
                Text(
                  '전체 ${_students.length}명 ${_searchQuery.isNotEmpty ? '(검색 결과: ${_filteredStudents.length}명)' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 학생 목록
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('학생 목록을 불러오는 중...'),
                        ],
                      ),
                    )
                  : _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '검색 결과가 없습니다.'
                                    : '등록된 학생이 없습니다.',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentCard(student);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentVO student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지 또는 기본 아이콘
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xff219189),
              child: student.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        student.profileImage!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
            ),

            const SizedBox(width: 16),

            // 학생 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '학번: ${student.studentId}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '반: ${student.className}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // 액션 버튼들
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 얼굴 등록 버튼
                ElevatedButton.icon(
                  onPressed: () => _showFaceEnrollmentDialog(student),
                  icon: const Icon(Icons.face, size: 18),
                  label: const Text('얼굴등록'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff219189),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                ),

                const SizedBox(width: 8),

                // 얼굴 삭제 버튼
                ElevatedButton.icon(
                  onPressed: () => _deleteFaceEnrollment(student),
                  icon: const Icon(Icons.face_retouching_off, size: 18),
                  label: const Text('얼굴삭제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                ),

                const SizedBox(width: 8),

                // 편집 버튼
                IconButton(
                  onPressed: () => _editStudent(student),
                  icon: const Icon(Icons.edit),
                  tooltip: '편집',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}