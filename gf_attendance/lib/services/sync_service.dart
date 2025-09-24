import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/lms_student_state.dart';
import '../services/lms_api_service.dart';
import '../utils/database_helper.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static const Duration _syncInterval = Duration(seconds: 10);
  static int _maxRetries = 10;

  // 동기화 상태 스트림
  static final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get statusStream => _statusController.stream;

  // 백그라운드 동기화 시작
  static void startBackgroundSync() {
    if (_syncTimer != null && _syncTimer!.isActive) {
      return; // 이미 실행 중
    }

    debugPrint('Starting background sync service');
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (!_isSyncing) {
        _syncPendingStates();
      }
    });

    // 즉시 한 번 실행
    _syncPendingStates();
  }

  // 백그라운드 동기화 중지
  static void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Background sync service stopped');
  }

  // 대기중인 상태 동기화
  static Future<void> _syncPendingStates() async {
    if (_isSyncing) return;

    _isSyncing = true;
    final dbHelper = DatabaseHelper.instance;

    try {
      // LMS 서비스 초기화 확인
      if (!LmsApiService.isInitialized) {
        await LmsApiService.initialize();
      }

      // 대기중인 상태 조회 (한 번에 최대 10개)
      final pendingStates = await dbHelper.getPendingStates(limit: 10);

      if (pendingStates.isEmpty) {
        _statusController.add(SyncStatus.idle());
        return;
      }

      _statusController.add(SyncStatus.syncing(pendingStates.length));
      debugPrint('Syncing ${pendingStates.length} pending states');

      int successCount = 0;
      int failCount = 0;

      for (final stateMap in pendingStates) {
        final id = stateMap['id'] as int;
        final retryCount = stateMap['retryCount'] as int;

        // 최대 재시도 횟수 초과 시 건너뛰기
        if (retryCount >= _maxRetries) {
          debugPrint('Max retries exceeded for pending state $id, skipping');
          await dbHelper.deletePendingState(id);
          failCount++;
          continue;
        }

        // LmsStudentState 객체 생성
        final state = LmsStudentState(
          studentId: stateMap['studentId'] ?? '',
          state: stateMap['state'] ?? 1,
          timestamp: stateMap['timestamp'] ?? DateTime.now().toIso8601String(),
          isKeypad: (stateMap['isKeypad'] ?? 0) == 1,
          isForced: (stateMap['isForced'] ?? 0) == 1,
          recognizeLogs: stateMap['recognizeLogs'] ?? '',
          hasThumbnail: (stateMap['hasThumbnail'] ?? 0) == 1,
          thumbnailImage: stateMap['thumbnailImage'],
        );

        try {
          // 서버로 출결 상태 전송
          final response = await LmsApiService.setStudentState(state);

          if (response.success) {
            // 썸네일이 있는 경우 업로드
            if (state.hasThumbnail && state.thumbnailImage != null) {
              final thumbnailResponse = await LmsApiService.uploadThumbnail(
                state.studentId,
                state.thumbnailImage!,
              );

              if (!thumbnailResponse.success) {
                debugPrint('Thumbnail upload failed: ${thumbnailResponse.message}');
                // 썸네일 업로드 실패는 전체 동기화를 실패로 보지 않음
              }
            }

            // 성공 시 로컬 데이터 삭제
            await dbHelper.deletePendingState(id);
            successCount++;
            debugPrint('Successfully synced pending state $id');
          } else {
            // 실패 시 재시도 횟수 증가
            await dbHelper.updatePendingStateRetry(id, response.message);
            failCount++;
            debugPrint('Failed to sync pending state $id: ${response.message}');
          }
        } catch (e) {
          // 네트워크 오류 등 예외 처리
          await dbHelper.updatePendingStateRetry(id, e.toString());
          failCount++;
          debugPrint('Exception while syncing pending state $id: $e');
        }

        // 동기화 간 짧은 지연
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 동기화 결과 알림
      if (successCount > 0 || failCount > 0) {
        _statusController.add(SyncStatus.completed(successCount, failCount));
        debugPrint('Sync completed: $successCount success, $failCount failed');
      }

      // 오래된 실패 항목 정리
      await dbHelper.cleanupFailedPendingStates(maxRetries: _maxRetries);

    } catch (e) {
      debugPrint('Sync service error: $e');
      _statusController.add(SyncStatus.error(e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  // 수동 동기화 실행
  static Future<void> manualSync() async {
    debugPrint('Manual sync requested');
    if (!_isSyncing) {
      await _syncPendingStates();
    } else {
      debugPrint('Sync already in progress, skipping manual sync');
    }
  }

  // 출결 상태를 안전하게 처리 (오프라인 지원)
  static Future<bool> processStudentState(LmsStudentState state) async {
    final dbHelper = DatabaseHelper.instance;

    try {
      // 온라인 상태에서 바로 전송 시도
      if (LmsApiService.isInitialized) {
        final response = await LmsApiService.setStudentState(state);

        if (response.success) {
          // 썸네일 업로드 (있는 경우)
          if (state.hasThumbnail && state.thumbnailImage != null) {
            final thumbnailResponse = await LmsApiService.uploadThumbnail(
              state.studentId,
              state.thumbnailImage!,
            );

            if (!thumbnailResponse.success) {
              debugPrint('Thumbnail upload failed: ${thumbnailResponse.message}');
            }
          }

          debugPrint('Student state processed successfully: ${state.studentId}');
          return true;
        }
      }

      // 전송 실패 또는 오프라인 상태 시 로컬에 저장
      await dbHelper.insertPendingState(state);
      debugPrint('Student state saved locally for later sync: ${state.studentId}');

      // 백그라운드 동기화가 실행 중이 아니면 시작
      if (_syncTimer == null || !_syncTimer!.isActive) {
        startBackgroundSync();
      }

      return false; // 로컬 저장만 성공
    } catch (e) {
      debugPrint('Error processing student state: $e');

      // 예외 발생 시에도 로컬에 저장 시도
      try {
        await dbHelper.insertPendingState(state);
        debugPrint('Student state saved locally after error: ${state.studentId}');
      } catch (dbError) {
        debugPrint('Failed to save state locally: $dbError');
      }

      return false;
    }
  }

  // 대기중인 항목 개수 조회
  static Future<int> getPendingCount() async {
    final dbHelper = DatabaseHelper.instance;
    final pendingStates = await dbHelper.getPendingStates();
    return pendingStates.length;
  }

  // 동기화 설정 변경
  static void updateSyncSettings({
    int? maxRetries,
    Duration? syncInterval,
  }) {
    if (maxRetries != null) {
      _maxRetries = maxRetries;
    }

    if (syncInterval != null && syncInterval != _syncInterval) {
      // 타이머 재시작
      final wasActive = _syncTimer?.isActive ?? false;
      stopBackgroundSync();

      if (wasActive) {
        _syncTimer = Timer.periodic(syncInterval, (_) {
          if (!_isSyncing) {
            _syncPendingStates();
          }
        });
      }
    }
  }

  // 서비스 정리
  static void dispose() {
    stopBackgroundSync();
    _statusController.close();
  }

  // 동기화 강제 실행 (즉시)
  static Future<void> forceSyncNow() async {
    _isSyncing = false; // 기존 동기화 강제 중단
    await _syncPendingStates();
  }
}

// 동기화 상태 클래스
class SyncStatus {
  final SyncState state;
  final String message;
  final int? pendingCount;
  final int? successCount;
  final int? failCount;

  SyncStatus._({
    required this.state,
    required this.message,
    this.pendingCount,
    this.successCount,
    this.failCount,
  });

  factory SyncStatus.idle() {
    return SyncStatus._(
      state: SyncState.idle,
      message: '대기 중',
    );
  }

  factory SyncStatus.syncing(int count) {
    return SyncStatus._(
      state: SyncState.syncing,
      message: '동기화 중...',
      pendingCount: count,
    );
  }

  factory SyncStatus.completed(int success, int fail) {
    return SyncStatus._(
      state: SyncState.completed,
      message: '동기화 완료',
      successCount: success,
      failCount: fail,
    );
  }

  factory SyncStatus.error(String error) {
    return SyncStatus._(
      state: SyncState.error,
      message: '동기화 오류: $error',
    );
  }

  @override
  String toString() {
    return 'SyncStatus{state: $state, message: $message}';
  }
}

enum SyncState {
  idle,
  syncing,
  completed,
  error,
}