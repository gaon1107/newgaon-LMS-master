import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/face_recognition_model.dart';
import '../services/auth_service.dart';

class GaonFaceService {
  static final Dio _dio = Dio();
  static String? _faceApiToken;
  static String? _faceApiBaseUrl;
  static String? _groupId;

  // 초기화
  static Future<void> initialize() async {
    final authService = AuthService();
    final config = await authService.getStoredConfig();

    if (config != null) {
      _faceApiBaseUrl = config['faceApiBaseUrl'];
      _groupId = config['groupId'] ?? config['branchId'];

      // Face API 토큰 획득
      await _getFaceApiToken(config['faceClientToken']);
    }

    // HTTP 클라이언트 설정
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'User-Agent': 'GFKids for Flutter',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json;charset=UTF-8',
      },
    );

    // 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_faceApiToken != null) {
            options.headers['ApiToken'] = _faceApiToken;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('Face API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  // Face API 토큰 획득
  static Future<bool> _getFaceApiToken(String? clientToken) async {
    if (clientToken == null || _faceApiBaseUrl == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        '$_faceApiBaseUrl/get/token',
        options: Options(
          headers: {
            'ClientToken': clientToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['statusCode'] == 200) {
          _faceApiToken = data['apiToken'];
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error getting Face API token: $e');
    }

    return false;
  }

  // 얼굴 인식
  static Future<FaceRecognitionResult?> recognizeFace(
    Uint8List imageBytes, {
    double similarity = 70.0,
  }) async {
    if (_faceApiBaseUrl == null || _groupId == null || _faceApiToken == null) {
      debugPrint('Face service not properly initialized');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'Image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face_image.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'Group': _groupId,
        'WithLandmarks': 'false',
        'WithPose': 'false',
        'WithAgeGender': 'false',
        'WithEmotions': 'false',
        'WithMasked': 'false',
        'MultiDetection': 'false',
        'Similarity': similarity.toString(),
      });

      final response = await _dio.post(
        '$_faceApiBaseUrl/v1/face/recognize',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return _parseFaceRecognitionResponse(data);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Face recognition API error: ${e.response?.statusCode}');
        debugPrint('Error response: ${e.response?.data}');
      } else {
        debugPrint('Face recognition error: $e');
      }
    }

    return null;
  }

  // 얼굴 등록
  static Future<FaceRecognitionResult?> enrollFace(
    String faceId,
    Uint8List imageBytes,
  ) async {
    if (_faceApiBaseUrl == null || _groupId == null || _faceApiToken == null) {
      debugPrint('Face service not properly initialized');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'Image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face_image.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'FaceId': faceId,
        'Group': _groupId,
      });

      final response = await _dio.post(
        '$_faceApiBaseUrl/v1/face/enrollment',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return _parseFaceRecognitionResponse(data);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Face enrollment API error: ${e.response?.statusCode}');
        debugPrint('Error response: ${e.response?.data}');
      } else {
        debugPrint('Face enrollment error: $e');
      }
    }

    return null;
  }

  // 얼굴 삭제
  static Future<bool> deleteFace(String faceId) async {
    if (_faceApiBaseUrl == null || _groupId == null || _faceApiToken == null) {
      debugPrint('Face service not properly initialized');
      return false;
    }

    try {
      final response = await _dio.post(
        '$_faceApiBaseUrl/v1/face/unenrollment',
        data: {
          'FaceId[]': [faceId],
          'Group': _groupId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Face deletion error: $e');
    }

    return false;
  }

  // 등록된 얼굴 목록 조회
  static Future<List<String>> getEnrolledFaces() async {
    if (_faceApiBaseUrl == null || _groupId == null || _faceApiToken == null) {
      debugPrint('Face service not properly initialized');
      return [];
    }

    try {
      final response = await _dio.post(
        '$_faceApiBaseUrl/v1/face/all',
        data: {
          'Group': _groupId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final result = _parseFaceRecognitionResponse(data);

        if (result != null && result.faces.isNotEmpty) {
          return result.faces.map((face) => face.faceId).toList();
        }
      }
    } catch (e) {
      debugPrint('Get enrolled faces error: $e');
    }

    return [];
  }

  // 얼굴 감지 (등록되지 않은 얼굴)
  static Future<FaceRecognitionResult?> detectFace(Uint8List imageBytes) async {
    if (_faceApiBaseUrl == null || _faceApiToken == null) {
      debugPrint('Face service not properly initialized');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'Image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face_image.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'WithLandmarks': 'false',
        'WithPose': 'false',
        'WithAgeGender': 'false',
        'WithEmotions': 'false',
        'WithMasked': 'false',
        'MultiDetection': 'false',
      });

      final response = await _dio.post(
        '$_faceApiBaseUrl/v1/face/detect',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return _parseFaceRecognitionResponse(data);
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    return null;
  }

  // API 응답 파싱
  static FaceRecognitionResult? _parseFaceRecognitionResponse(Map<String, dynamic> data) {
    try {
      final faces = <FaceInfo>[];

      if (data['Faces'] != null && data['Faces'] is List) {
        for (final faceData in data['Faces']) {
          if (faceData is Map<String, dynamic>) {
            final face = FaceInfo(
              faceId: faceData['FaceId'] ?? 'Unknown',
              similarity: faceData['Similarity'] ?? 0,
              faceRect: _parseFaceRect(faceData['FaceRect']),
              age: faceData['Age'] ?? 0,
              gender: _parseGender(faceData['Gender']),
              masked: faceData['Masked'] ?? false,
            );
            faces.add(face);
          }
        }
      }

      return FaceRecognitionResult(
        requestId: data['RequestId'] ?? '',
        elapsedTotal: data['ElapsedTotal'] ?? 0,
        faces: faces,
        imageSize: _parseImageSize(data['ImageSize']),
      );
    } catch (e) {
      debugPrint('Error parsing face recognition response: $e');
      return null;
    }
  }

  static FaceRect? _parseFaceRect(Map<String, dynamic>? data) {
    if (data == null) return null;

    return FaceRect(
      x: data['X'] ?? 0,
      y: data['Y'] ?? 0,
      width: data['Width'] ?? 0,
      height: data['Height'] ?? 0,
    );
  }

  static Gender? _parseGender(Map<String, dynamic>? data) {
    if (data == null) return null;

    return Gender(
      male: (data['Male'] ?? 0.0).toDouble(),
      female: (data['Female'] ?? 0.0).toDouble(),
    );
  }

  static ImageSize? _parseImageSize(Map<String, dynamic>? data) {
    if (data == null) return null;

    return ImageSize(
      width: data['Width'] ?? 0,
      height: data['Height'] ?? 0,
    );
  }

  // 서비스 상태 확인
  static bool get isInitialized {
    return _faceApiBaseUrl != null &&
           _faceApiToken != null &&
           _groupId != null;
  }

  // 설정 정보 새로고침
  static Future<void> refreshConfig() async {
    await initialize();
  }
}