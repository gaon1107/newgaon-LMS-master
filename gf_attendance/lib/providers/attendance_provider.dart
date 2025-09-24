import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/state_model.dart';
import '../models/student_model.dart';
import '../services/attendance_service.dart';
import '../services/gaon_face_service.dart';
import '../utils/app_constants.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  // 현재 선택된 학생
  StudentModel? _selectedStudent;

  // 출결 상태 목록
  List<StateModel> _stateList = [];

  // 학생 목록
  List<StudentModel> _studentList = [];

  // 로딩 상태
  bool _isLoading = false;

  // 에러 메시지
  String? _errorMessage;

  // 얼굴인식 모드 여부
  bool _isFaceRecognitionMode = true;

  // 현재 출결 상태 (등원, 수업출석, 하원, 지각, 조퇴)
  int _currentAttendanceState = AppConstants.stateAttendIn;

  // Getters
  StudentModel? get selectedStudent => _selectedStudent;
  List<StateModel> get stateList => _stateList;
  List<StudentModel> get studentList => _studentList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFaceRecognitionMode => _isFaceRecognitionMode;
  int get currentAttendanceState => _currentAttendanceState;

  // 오늘의 출결 목록
  List<StateModel> get todayStates {
    final today = DateTime.now();
    return _stateList.where((state) {
      return state.taggedAt != null &&
             state.taggedAt!.year == today.year &&
             state.taggedAt!.month == today.month &&
             state.taggedAt!.day == today.day;
    }).toList();
  }

  // 선택된 학생의 오늘 출결 상태
  List<StateModel> get selectedStudentTodayStates {
    if (_selectedStudent == null) return [];

    return todayStates.where((state) =>
      state.studentId == _selectedStudent!.id
    ).toList();
  }

  // 초기화 메서드
  Future<void> initialize() async {
    await Future.wait([
      loadStudentList(),
      loadTodayStates(),
    ]);
  }

  // 학생 목록 로드
  Future<void> loadStudentList() async {
    _setLoading(true);

    try {
      await _attendanceService.fetchStudentList();
      _studentList = _attendanceService.studentList;
    } catch (e) {
      _setError('학생 목록 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 오늘의 출결 상태 로드
  Future<void> loadTodayStates() async {
    _setLoading(true);

    try {
      await _attendanceService.fetchStateList(
        date: DateTime.now(),
      );
      _stateList = _attendanceService.stateList;
    } catch (e) {
      _setError('오늘 출결 상태 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 학생별 출결 이력 로드
  Future<void> loadStudentStates(String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);

    try {
      final states = await _attendanceService.fetchStudentStates(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );
      if (states != null) {
        _stateList = states;
      }
    } catch (e) {
      _setError('학생 출결 이력 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 출결 기록
  Future<bool> recordAttendance({
    required String studentId,
    required int state,
    bool isKeypad = false,
    String? thumbnail,
    String? recognizeLog,
    String? comment,
    Uint8List? thumbnailBytes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newState = await _attendanceService.recordAttendance(
        studentId: studentId,
        state: state,
        isKeypad: isKeypad,
        thumbnail: thumbnail,
        recognizeLog: recognizeLog,
        comment: comment,
        thumbnailBytes: thumbnailBytes,
      );

      if (newState != null) {
        // 로컬 목록에 추가
        _stateList.insert(0, newState);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('출결 기록 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Face ID로 학생 찾기
  Future<StudentModel?> findStudentByFaceId(String faceId) async {
    try {
      return await _attendanceService.findStudentByFaceId(faceId);
    } catch (e) {
      _setError('Face ID로 학생 검색 실패: $e');
      return null;
    }
  }

  // 얼굴인식으로 출결 처리
  Future<bool> recordAttendanceByFace({
    required String studentIdentifier,
    required int state,
    String? thumbnail,
    String? recognizeLog,
    double? confidence,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      // 학생 검색
      final student = await _attendanceService.findStudentByFaceId(studentIdentifier);

      if (student == null) {
        _setError('학생을 찾을 수 없습니다.');
        return false;
      }

      // 선택된 학생 설정
      setSelectedStudent(student);

      // 출결 기록
      return await recordAttendance(
        studentId: student.id,
        state: state,
        isKeypad: false,
        thumbnail: thumbnail,
        recognizeLog: recognizeLog,
        thumbnailBytes: thumbnailBytes,
        comment: confidence != null ? 'Face recognition confidence: ${(confidence * 100).toStringAsFixed(1)}%' : null,
      );
    } catch (e) {
      _setError('얼굴인식 출결 처리 실패: $e');
      return false;
    }
  }

  // 키패드로 출결 처리
  Future<bool> recordAttendanceByKeypad({
    required String studentNumber,
    required int state,
  }) async {
    try {
      // 학생 검색
      final student = await _attendanceService.findStudentByNumberAPI(studentNumber);

      if (student == null) {
        _setError('학번 $studentNumber에 해당하는 학생을 찾을 수 없습니다.');
        return false;
      }

      // 선택된 학생 설정
      setSelectedStudent(student);

      // 출결 기록
      return await recordAttendance(
        studentId: student.id,
        state: state,
        isKeypad: true,
      );
    } catch (e) {
      _setError('키패드 출결 처리 실패: $e');
      return false;
    }
  }

  // 출결 상태 수정
  Future<bool> updateAttendanceState({
    required String stateId,
    int? state,
    String? comment,
    bool? isForced,
  }) async {
    _setLoading(true);

    try {
      final updatedState = await _attendanceService.updateState(
        stateId: stateId,
        state: state,
        comment: comment,
        isForced: isForced,
      );

      if (updatedState != null) {
        // 로컬 목록 업데이트
        final index = _stateList.indexWhere((s) => s.id == stateId);
        if (index != -1) {
          _stateList[index] = updatedState;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('출결 상태 수정 실패: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 학생 검색 (이름, 학번)
  Future<void> searchStudents(String query) async {
    if (query.isEmpty) {
      await loadStudentList();
      return;
    }

    _setLoading(true);

    try {
      await _attendanceService.fetchStudentList(search: query);
      _studentList = _attendanceService.studentList;
    } catch (e) {
      _setError('학생 검색 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 출결 통계 조회
  Future<Map<String, dynamic>?> getAttendanceStats({
    DateTime? startDate,
    DateTime? endDate,
    String? studentId,
  }) async {
    _setLoading(true);

    try {
      return await _attendanceService.fetchAttendanceStats(
        startDate: startDate,
        endDate: endDate,
        studentId: studentId,
      );
    } catch (e) {
      _setError('출결 통계 조회 실패: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 실시간 출결 현황 새로고침
  Future<void> refreshRecentStates() async {
    _setLoading(true);

    try {
      await _attendanceService.fetchRecentStates();
      _stateList = _attendanceService.stateList;
    } catch (e) {
      _setError('실시간 출결 현황 새로고침 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 출결 모드 변경 (얼굴인식 <-> 키패드)
  void toggleAttendanceMode() {
    _isFaceRecognitionMode = !_isFaceRecognitionMode;
    notifyListeners();
  }

  // 출결 상태 변경 (등원, 수업출석, 하원, 지각, 조퇴)
  void setCurrentAttendanceState(int state) {
    _currentAttendanceState = state;
    notifyListeners();
  }

  // 선택된 학생 설정
  void setSelectedStudent(StudentModel? student) {
    _selectedStudent = student;
    notifyListeners();
  }

  // 학생 선택 해제
  void clearSelectedStudent() {
    _selectedStudent = null;
    notifyListeners();
  }

  // 출결 상태 텍스트 가져오기
  String getStateText(int state) {
    switch (state) {
      case AppConstants.stateAttendIn:
        return '등원';
      case AppConstants.stateAttendClass:
        return '수업출석';
      case AppConstants.stateLeaveOut:
        return '하원';
      case AppConstants.stateAttendLate:
        return '지각';
      case AppConstants.stateLeaveEarly:
        return '조퇴';
      default:
        return '알 수 없음';
    }
  }

  // 현재 출결 상태 텍스트
  String get currentStateText => getStateText(_currentAttendanceState);

  // 학생이 오늘 이미 출결 처리되었는지 확인
  bool hasStudentAttendedToday(String studentId, int state) {
    return todayStates.any((s) =>
      s.studentId == studentId && s.state == state
    );
  }

  // 학생의 최근 출결 상태 가져오기
  StateModel? getStudentLatestState(String studentId) {
    final studentStates = _stateList
        .where((s) => s.studentId == studentId)
        .toList();

    if (studentStates.isEmpty) return null;

    studentStates.sort((a, b) =>
      (b.taggedAt ?? DateTime(1970)).compareTo(a.taggedAt ?? DateTime(1970))
    );

    return studentStates.first;
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();

    if (kDebugMode) {
      print('AttendanceProvider Error: $error');
    }
  }

  // 에러 초기화
  void _clearError() {
    _errorMessage = null;
  }

  // 전체 데이터 초기화
  void clearAll() {
    _selectedStudent = null;
    _stateList.clear();
    _studentList.clear();
    _errorMessage = null;
    _isLoading = false;
    _isFaceRecognitionMode = true;
    _currentAttendanceState = AppConstants.stateAttendIn;
    notifyListeners();
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }
}