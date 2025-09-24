import 'dart:typed_data';

class LmsStudentState {
  final String studentId;
  final int state; // 1:등원, 2:하원, 3:외출, 4:복귀, 5:조퇴
  final String timestamp; // ISO 8601 형식
  final bool isKeypad; // false: 얼굴인식, true: 키패드
  final bool isForced;
  final String recognizeLogs; // "faceId:similarity" 형식
  final bool hasThumbnail;
  final Uint8List? thumbnailImage;

  LmsStudentState({
    required this.studentId,
    required this.state,
    required this.timestamp,
    this.isKeypad = false,
    this.isForced = false,
    required this.recognizeLogs,
    this.hasThumbnail = false,
    this.thumbnailImage,
  });

  // 상태 텍스트 반환
  String get stateText {
    switch (state) {
      case 1:
        return '등원';
      case 2:
        return '하원';
      case 3:
        return '외출';
      case 4:
        return '복귀';
      case 5:
        return '조퇴';
      default:
        return '알 수 없음';
    }
  }

  // 상태별 안내 메시지 반환
  String get stateMessage {
    switch (state) {
      case 1:
        return '등원처리 되었습니다. 어서오세요.';
      case 2:
        return '하원처리 되었습니다. 안녕히 가세요.';
      case 3:
        return '외출처리 되었습니다. 조심히 다녀오세요.';
      case 4:
        return '복귀처리 되었습니다. 다시 오신 것을 환영합니다.';
      case 5:
        return '조퇴처리 되었습니다. 몸조리 잘하세요.';
      default:
        return '처리되었습니다.';
    }
  }

  factory LmsStudentState.fromJson(Map<String, dynamic> json) {
    return LmsStudentState(
      studentId: json['studentId'] ?? '',
      state: json['state'] ?? 1,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      isKeypad: json['isKeypad'] ?? false,
      isForced: json['isForced'] ?? false,
      recognizeLogs: json['recognizeLogs'] ?? '',
      hasThumbnail: json['hasThumbnail'] ?? false,
      thumbnailImage: json['thumbnailImage'] != null
          ? Uint8List.fromList((json['thumbnailImage'] as List).cast<int>())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'state': state,
      'timestamp': timestamp,
      'isKeypad': isKeypad,
      'isForced': isForced,
      'recognizeLogs': recognizeLogs,
      'hasThumbnail': hasThumbnail,
      'thumbnailImage': thumbnailImage?.toList(),
    };
  }

  // 서버 전송용 JSON (썸네일 제외)
  Map<String, dynamic> toServerJson() {
    return {
      'studentId': studentId,
      'state': state,
      'timestamp': timestamp,
      'isKeypad': isKeypad,
      'isForced': isForced,
      'recognizeLogs': recognizeLogs,
      'hasThumbnail': hasThumbnail,
    };
  }

  LmsStudentState copyWith({
    String? studentId,
    int? state,
    String? timestamp,
    bool? isKeypad,
    bool? isForced,
    String? recognizeLogs,
    bool? hasThumbnail,
    Uint8List? thumbnailImage,
  }) {
    return LmsStudentState(
      studentId: studentId ?? this.studentId,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      isKeypad: isKeypad ?? this.isKeypad,
      isForced: isForced ?? this.isForced,
      recognizeLogs: recognizeLogs ?? this.recognizeLogs,
      hasThumbnail: hasThumbnail ?? this.hasThumbnail,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
    );
  }

  // 얼굴인식 결과로 생성
  static LmsStudentState fromFaceRecognition({
    required String studentId,
    required int state,
    required String faceId,
    required int similarity,
    Uint8List? thumbnailImage,
  }) {
    return LmsStudentState(
      studentId: studentId,
      state: state,
      timestamp: DateTime.now().toIso8601String(),
      isKeypad: false,
      isForced: false,
      recognizeLogs: '$faceId:$similarity',
      hasThumbnail: thumbnailImage != null,
      thumbnailImage: thumbnailImage,
    );
  }

  // 키패드 입력으로 생성
  static LmsStudentState fromKeypadInput({
    required String studentId,
    required int state,
    bool isForced = false,
  }) {
    return LmsStudentState(
      studentId: studentId,
      state: state,
      timestamp: DateTime.now().toIso8601String(),
      isKeypad: true,
      isForced: isForced,
      recognizeLogs: 'keypad:input',
      hasThumbnail: false,
    );
  }

  @override
  String toString() {
    return 'LmsStudentState{studentId: $studentId, state: $state, timestamp: $timestamp}';
  }
}

// API 응답 래퍼 클래스
class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
    };
  }

  // 성공 응답 생성
  static ApiResponse createSuccess({
    String message = 'Success',
    Map<String, dynamic>? data,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 200,
    );
  }

  // 실패 응답 생성
  static ApiResponse error({
    required String message,
    Map<String, dynamic>? data,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      data: data,
      statusCode: statusCode ?? 400,
    );
  }
}