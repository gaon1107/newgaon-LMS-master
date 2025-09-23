import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConstants.baseUrl;
  String? _accessToken;
  String? _userId;

  // Access Token 설정
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  // 기본 헤더 생성
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // GET 요청
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      if (kDebugMode) {
        print('GET Request: $uri');
      }

      final response = await http
          .get(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('GET Error: $e');
      }
      throw _handleError(e);
    }
  }

  // POST 요청
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      if (kDebugMode) {
        print('POST Request: $uri');
        print('POST Data: ${jsonEncode(data)}');
      }

      final response = await http
          .post(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('POST Error: $e');
      }
      throw _handleError(e);
    }
  }

  // PUT 요청
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      if (kDebugMode) {
        print('PUT Request: $uri');
        print('PUT Data: ${jsonEncode(data)}');
      }

      final response = await http
          .put(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('PUT Error: $e');
      }
      throw _handleError(e);
    }
  }

  // DELETE 요청
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      if (kDebugMode) {
        print('DELETE Request: $uri');
      }

      final response = await http
          .delete(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('DELETE Error: $e');
      }
      throw _handleError(e);
    }
  }

  // Multipart 파일 업로드
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // 헤더 설정 (Content-Type 제외)
      final requestHeaders = _getHeaders(additionalHeaders: headers);
      requestHeaders.remove('Content-Type'); // multipart에서는 자동 설정
      request.headers.addAll(requestHeaders);

      // 파일 추가
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // 추가 필드
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      if (kDebugMode) {
        print('Upload Request: $uri');
        print('Upload File: $filePath');
      }

      final streamedResponse = await request.send().timeout(AppConstants.networkTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Upload Error: $e');
      }
      throw _handleError(e);
    }
  }

  // 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }

    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // 서버 에러 응답
        final errorMessage = data['error']?['message'] ??
                           data['message'] ??
                           'HTTP ${response.statusCode}';
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          errorCode: data['error']?['code'],
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }

      // JSON 파싱 실패 또는 기타 오류
      throw ApiException(
        message: 'Response parsing failed: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  // 에러 처리
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    String message = '네트워크 오류가 발생했습니다.';

    if (error.toString().contains('TimeoutException')) {
      message = '요청 시간이 초과되었습니다.';
    } else if (error.toString().contains('SocketException')) {
      message = '인터넷 연결을 확인해주세요.';
    }

    return ApiException(message: message);
  }
}

// API 예외 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $errorCode)';
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}