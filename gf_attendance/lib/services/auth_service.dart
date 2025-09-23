import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'api_service.dart';
import '../utils/app_constants.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  String? _deviceId;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  String? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get deviceId => _deviceId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  AuthService() {
    _initializeAuth();
  }

  // 초기화 - 저장된 인증 정보 복원
  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(AppConstants.userIdKey);
      _accessToken = prefs.getString(AppConstants.accessTokenKey);
      _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      _deviceId = prefs.getString(AppConstants.deviceIdKey);

      if (_deviceId == null) {
        _deviceId = await _generateDeviceId();
        await prefs.setString(AppConstants.deviceIdKey, _deviceId!);
      }

      _isLoggedIn = _accessToken != null && _userId != null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Auth initialization error: $e');
      }
    }
  }

  // 디바이스 ID 생성
  Future<String> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = 'android_${androidInfo.id}_${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = 'ios_${iosInfo.identifierForVendor}_${iosInfo.model}';
      }

      return '${packageInfo.packageName}_$deviceId';
    } catch (e) {
      // 기본값 반환
      return '${AppConstants.packageName}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // 로그인
  Future<bool> login(String username, String password) async {
    _setLoading(true);

    try {
      final response = await _apiService.post(
        AppConstants.authEndpoint + '/login',
        data: {
          'username': username,
          'password': password,
          'device_id': _deviceId,
          'app_version': AppConstants.appVersion,
        },
      );

      if (response['success'] == true) {
        final data = response['data'];
        await _saveAuthData(
          userId: data['user']['id'].toString(),
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      } else {
        throw Exception(response['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      throw Exception('로그인 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 토큰 갱신
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _apiService.post(
        AppConstants.authEndpoint + '/refresh',
        data: {
          'refresh_token': _refreshToken,
          'device_id': _deviceId,
        },
      );

      if (response['success'] == true) {
        final data = response['data'];
        await _saveAuthData(
          userId: _userId!,
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? _refreshToken!,
        );
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh error: $e');
      }
    }

    return false;
  }

  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);

    try {
      // 서버에 로그아웃 요청
      if (_accessToken != null) {
        await _apiService.post(
          AppConstants.authEndpoint + '/logout',
          data: {
            'device_id': _deviceId,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Logout API error: $e');
      }
    } finally {
      await _clearAuthData();
      _setLoading(false);
    }
  }

  // 인증 데이터 저장
  Future<void> _saveAuthData({
    required String userId,
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _userId = userId;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isLoggedIn = true;

    await prefs.setString(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);

    notifyListeners();
  }

  // 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    _userId = null;
    _accessToken = null;
    _refreshToken = null;
    _isLoggedIn = false;

    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);

    notifyListeners();
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 디바이스 정보 가져오기
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> info = {
        'device_id': _deviceId,
        'app_version': packageInfo.version,
        'app_build': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'platform': 'android',
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'os_version': androidInfo.version.release,
          'device_id_android': androidInfo.id,
        });
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'platform': 'ios',
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'os_version': iosInfo.systemVersion,
          'device_id_ios': iosInfo.identifierForVendor,
        });
      }

      return info;
    } catch (e) {
      if (kDebugMode) {
        print('Device info error: $e');
      }
      return {
        'device_id': _deviceId,
        'app_version': AppConstants.appVersion,
        'platform': 'unknown',
      };
    }
  }

  // 토큰 유효성 검사
  Future<bool> validateToken() async {
    if (_accessToken == null) return false;

    try {
      final response = await _apiService.get(
        AppConstants.authEndpoint + '/validate',
      );
      return response['success'] == true;
    } catch (e) {
      // 토큰이 만료된 경우 갱신 시도
      return await refreshAccessToken();
    }
  }
}