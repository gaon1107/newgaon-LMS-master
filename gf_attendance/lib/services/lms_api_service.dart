import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/student_vo.dart';
import '../models/lms_student_state.dart';
import '../services/auth_service.dart';

class LmsApiService {
  static final Dio _dio = Dio();
  static String? _lmsBaseUrl;
  static String? _bearerToken;
  static String? _branchId;

  // 초기화
  static Future<void> initialize() async {
    final authService = AuthService();
    final config = await authService.getStoredConfig();

    if (config != null) {
      _lmsBaseUrl = config['lmsBaseUrl'];
      _branchId = config['branchId'];
    }

    // HTTP 클라이언트 설정
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': 'GFKids for Flutter',
        'Content-Type': 'application/json',
        'Accept': 'application/json;charset=UTF-8',
      },
    );

    // 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_bearerToken != null) {
            options.headers['Authorization'] = 'Bearer $_bearerToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('LMS API Error: ${error.message}');
          debugPrint('Status Code: ${error.response?.statusCode}');
          debugPrint('Response Data: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  // 로그인
  static Future<ApiResponse> login(String id, String password) async {
    if (_lmsBaseUrl == null) {
      return ApiResponse.error(message: 'LMS 서버 URL이 설정되지 않았습니다.');
    }

    try {
      final response = await _dio.post(
        '$_lmsBaseUrl/api/d/1.0/login',
        data: {
          'id': id,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          _bearerToken = data['token'];

          // 토큰 저장
          final authService = AuthService();
          await authService.saveToken(_bearerToken!);

          return ApiResponse.createSuccess(
            message: '로그인 성공',
            data: data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
          );
        } else {
          return ApiResponse.error(
            message: data['message'] ?? '로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          return ApiResponse.error(message: '아이디 또는 비밀번호가 올바르지 않습니다.');
        } else if (e.response?.statusCode == 403) {
          return ApiResponse.error(message: '접근 권한이 없습니다.');
        }
      }
      debugPrint('Login error: $e');
      return ApiResponse.error(message: '서버 연결에 실패했습니다.');
    }

    return ApiResponse.error(message: '로그인에 실패했습니다.');
  }

  // 학생 목록 조회
  static Future<List<StudentVO>> getAllStudents() async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      debugPrint('LMS service not properly initialized');
      return [];
    }

    try {
      final response = await _dio.get(
        '$_lmsBaseUrl/api/d/1.0/student/get/all',
        queryParameters: {
          if (_branchId != null) 'branchId': _branchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          final studentsData = data['data'] as List?;
          if (studentsData != null) {
            return studentsData
                .map((studentJson) => StudentVO.fromJson(studentJson))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Get all students error: $e');
    }

    return [];
  }

  // 학생 정보 조회
  static Future<StudentVO?> getStudentById(String studentId) async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      debugPrint('LMS service not properly initialized');
      return null;
    }

    try {
      final response = await _dio.get(
        '$_lmsBaseUrl/api/d/1.0/student/get/$studentId',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data['success'] == true) {
          return StudentVO.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Get student by id error: $e');
    }

    return null;
  }

  // 출결 상태 등록
  static Future<ApiResponse> setStudentState(LmsStudentState state) async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      debugPrint('LMS service not properly initialized');
      return ApiResponse.error(message: 'LMS 서비스가 초기화되지 않았습니다.');
    }

    try {
      final response = await _dio.post(
        '$_lmsBaseUrl/api/d/1.0/student/state/set',
        data: state.toServerJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse.fromJson(data);
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('Set student state API error: ${e.response?.statusCode}');
        debugPrint('Error response: ${e.response?.data}');

        if (e.response?.statusCode == 400) {
          return ApiResponse.error(message: '잘못된 요청입니다.');
        } else if (e.response?.statusCode == 401) {
          return ApiResponse.error(message: '인증이 필요합니다.');
        } else if (e.response?.statusCode == 404) {
          return ApiResponse.error(message: '학생 정보를 찾을 수 없습니다.');
        }
      }
      debugPrint('Set student state error: $e');
    }

    return ApiResponse.error(message: '출결 처리에 실패했습니다.');
  }

  // 썸네일 업로드
  static Future<ApiResponse> uploadThumbnail(
    String studentId,
    Uint8List imageBytes,
  ) async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      debugPrint('LMS service not properly initialized');
      return ApiResponse.error(message: 'LMS 서비스가 초기화되지 않았습니다.');
    }

    try {
      final formData = FormData.fromMap({
        'studentId': studentId,
        'thumbnail': MultipartFile.fromBytes(
          imageBytes,
          filename: 'thumbnail_${studentId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '$_lmsBaseUrl/api/d/1.0/student/state/thumbnail/set',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse.fromJson(data);
      }
    } catch (e) {
      debugPrint('Upload thumbnail error: $e');
    }

    return ApiResponse.error(message: '썸네일 업로드에 실패했습니다.');
  }

  // 토큰 유효성 검사
  static Future<bool> validateToken() async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      return false;
    }

    try {
      final response = await _dio.get(
        '$_lmsBaseUrl/api/d/1.0/auth/validate',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Validate token error: $e');
      return false;
    }
  }

  // 토큰 새로고침
  static Future<bool> refreshToken() async {
    final authService = AuthService();
    final refreshToken = await authService.getRefreshToken();

    if (_lmsBaseUrl == null || refreshToken == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        '$_lmsBaseUrl/api/d/1.0/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          _bearerToken = data['token'];
          await authService.saveToken(_bearerToken!);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Refresh token error: $e');
    }

    return false;
  }

  // 로그아웃
  static Future<void> logout() async {
    try {
      if (_lmsBaseUrl != null && _bearerToken != null) {
        await _dio.post('$_lmsBaseUrl/api/d/1.0/auth/logout');
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _bearerToken = null;
      final authService = AuthService();
      await authService.clearTokens();
    }
  }

  // 출결 이력 조회 (관리자용)
  static Future<List<Map<String, dynamic>>> getAttendanceHistory({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    if (_lmsBaseUrl == null || _bearerToken == null) {
      return [];
    }

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (studentId != null) 'studentId': studentId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (_branchId != null) 'branchId': _branchId,
      };

      final response = await _dio.get(
        '$_lmsBaseUrl/api/d/1.0/student/state/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final historyData = data['data'] as List?;
          if (historyData != null) {
            return historyData.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (e) {
      debugPrint('Get attendance history error: $e');
    }

    return [];
  }

  // 서비스 상태 확인
  static bool get isInitialized {
    return _lmsBaseUrl != null && _bearerToken != null;
  }

  // 설정 정보 새로고침
  static Future<void> refreshConfig() async {
    await initialize();
  }

  // 현재 브랜치 ID 반환
  static String? get currentBranchId => _branchId;

  // 현재 토큰 반환 (디버그용)
  static String? get currentToken => _bearerToken;

  // 베이스 URL 반환
  static String? get baseUrl => _lmsBaseUrl;
}