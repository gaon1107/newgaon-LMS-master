import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'api_service.dart';
import '../models/state_model.dart';
import '../models/student_model.dart';
import '../utils/app_constants.dart';

class AttendanceService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StateModel> _stateList = [];
  List<StudentModel> _studentList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StateModel> get stateList => _stateList;
  List<StudentModel> get studentList => _studentList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 출결 목록 조회 (Spring Boot 백엔드)
  Future<void> fetchStateList({
    DateTime? date,
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T')[0];
      }

      if (studentId != null) {
        queryParams['studentId'] = studentId;
      }

      final response = await _apiService.get(
        AppConstants.stateEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> stateData = response['data'] ?? response;
      _stateList = stateData
          .map((json) => StateModel.fromJson(json))
          .toList();
    } catch (e) {
      _setError('출결 목록 조회 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Fetch state list error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 출결 상태 기록 (Spring Boot 백엔드)
  Future<StateModel?> recordAttendance({
    required String studentId,
    required int state,
    bool isKeypad = false,
    String? deviceId,
    String? thumbnail,
    String? recognizeLog,
    String? comment,
    Uint8List? thumbnailBytes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = <String, dynamic>{
        'studentId': studentId,
        'state': state,
        'taggedAt': DateTime.now().toIso8601String(),
        'isKeypad': isKeypad,
        'deviceId': deviceId ?? 'flutter_app',
        'appId': AppConstants.packageName,
        'appVersion': AppConstants.appVersion,
        'isForced': false,
        'isModified': false,
        'isDelayed': false,
      };

      // 썸네일 이미지 처리
      if (thumbnailBytes != null) {
        data['thumbnail'] = base64Encode(thumbnailBytes);
      } else if (thumbnail != null) {
        data['thumbnail'] = thumbnail;
      }

      // 얼굴인식 로그 추가
      if (recognizeLog != null) {
        data['recognizeLog'] = recognizeLog;
      }

      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await _apiService.post(
        AppConstants.stateEndpoint,
        data: data,
      );

      final newState = StateModel.fromJson(response['data'] ?? response);

      // 로컬 목록에 추가
      _stateList.insert(0, newState);
      notifyListeners();

      return newState;
    } catch (e) {
      _setError('출결 기록 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Record attendance error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 출결 상태 수정
  Future<StateModel?> updateState({
    required String stateId,
    int? state,
    String? comment,
    bool? isForced,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = <String, dynamic>{};

      if (state != null) data['state'] = state;
      if (comment != null) data['comment'] = comment;
      if (isForced != null) data['isForced'] = isForced;

      data['isModified'] = true;
      data['modifiedAt'] = DateTime.now().toIso8601String();

      final response = await _apiService.put(
        '${AppConstants.stateEndpoint}/$stateId',
        data: data,
      );

      final updatedState = StateModel.fromJson(response['data'] ?? response);

      // 로컬 목록에서 업데이트
      final index = _stateList.indexWhere((s) => s.id == stateId);
      if (index != -1) {
        _stateList[index] = updatedState;
        notifyListeners();
      }

      return updatedState;
    } catch (e) {
      _setError('출결 수정 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Update state error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 학생 목록 조회
  Future<void> fetchStudentList({
    int page = 1,
    int limit = 100,
    String search = '',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiService.get(
        AppConstants.studentEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> studentData = response['data'] ?? response;
      _studentList = studentData
          .map((json) => StudentModel.fromJson(json))
          .toList();
    } catch (e) {
      _setError('학생 목록 조회 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Fetch student list error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 출결 통계 조회
  Future<Map<String, dynamic>?> fetchAttendanceStats({
    DateTime? startDate,
    DateTime? endDate,
    String? studentId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (studentId != null) {
        queryParams['studentId'] = studentId;
      }

      final response = await _apiService.get(
        '${AppConstants.stateEndpoint}/stats',
        queryParameters: queryParams,
      );

      return response['data'] ?? response;
    } catch (e) {
      _setError('출결 통계 조회 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Fetch attendance stats error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 학생별 출결 현황 조회
  Future<List<StateModel>?> fetchStudentStates({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final queryParams = <String, String>{
        'studentId': studentId,
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        AppConstants.stateEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> stateData = response['data'] ?? response;
      return stateData
          .map((json) => StateModel.fromJson(json))
          .toList();
    } catch (e) {
      _setError('학생 출결 현황 조회 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Fetch student states error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 학생 검색 (식별자로)
  Future<StudentModel?> findStudentByIdentifier(String identifier) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get(
        '${AppConstants.studentEndpoint}/search',
        queryParameters: {
          'identifier': identifier,
        },
      );

      if (response['data'] != null) {
        return StudentModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _setError('학생 검색 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Find student by identifier error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Face ID로 학생 검색
  Future<StudentModel?> findStudentByFaceId(String faceId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get(
        '${AppConstants.studentEndpoint}/search',
        queryParameters: {
          'faceId': faceId,
        },
      );

      if (response['data'] != null) {
        return StudentModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _setError('Face ID로 학생 검색 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Find student by face ID error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ID로 학생 찾기
  StudentModel? findStudentById(String studentId) {
    try {
      return _studentList.firstWhere((student) => student.id == studentId);
    } catch (e) {
      return null;
    }
  }

  // 학번으로 학생 검색 (API 호출)
  Future<StudentModel?> findStudentByNumberAPI(String studentNumber) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get(
        '${AppConstants.studentEndpoint}/search',
        queryParameters: {
          'studentNumber': studentNumber,
        },
      );

      if (response['data'] != null) {
        return StudentModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _setError('학생 검색 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Find student by number error: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 로컬 목록에서 학번으로 학생 찾기
  StudentModel? findStudentByNumber(String studentNumber) {
    try {
      return _studentList.firstWhere(
        (student) => student.studentNumber == studentNumber,
      );
    } catch (e) {
      return null;
    }
  }

  // 오늘 날짜의 출결 기록 가져오기
  List<StateModel> getTodayStates() {
    final today = DateTime.now();
    return _stateList.where((state) {
      return state.taggedAt != null &&
             state.taggedAt!.year == today.year &&
             state.taggedAt!.month == today.month &&
             state.taggedAt!.day == today.day;
    }).toList();
  }

  // AttendanceSummaryCard에서 사용하는 메서드 (별칭)
  List<StateModel> getTodayAttendance() => getTodayStates();

  // 실시간 출결 현황 조회
  Future<void> fetchRecentStates({int limit = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get(
        '${AppConstants.stateEndpoint}/recent',
        queryParameters: {
          'limit': limit.toString(),
        },
      );

      final List<dynamic> stateData = response['data'] ?? response;
      _stateList = stateData
          .map((json) => StateModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('실시간 출결 조회 중 오류가 발생했습니다: $e');
      if (kDebugMode) {
        print('Fetch recent states error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // 에러 초기화
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // 데이터 초기화
  void clearData() {
    _stateList.clear();
    _studentList.clear();
    _error = null;
    notifyListeners();
  }
}