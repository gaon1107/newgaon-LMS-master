import '../utils/app_constants.dart';

class AttendanceModel {
  final String? id;
  final String studentId;
  final String? lectureId;
  final DateTime date;
  final int state; // 0: 등원, 1: 수업출석, 2: 하원, 3: 지각, 4: 조퇴
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isKeypad; // true: 키패드 인증, false: 얼굴인식
  final String? deviceId;
  final String? appId;
  final String? appVersion;
  final bool isForced; // 강제 출결 처리
  final bool isModified; // 수정된 출결
  final bool isDelayed; // 지연된 출결
  final String? comment;
  final String? thumbnail; // 얼굴인식 이미지
  final List<RecognizeLogModel>? recognizeLogs;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 추가 정보 (조인 결과)
  final String? studentName;
  final String? lectureName;

  AttendanceModel({
    this.id,
    required this.studentId,
    this.lectureId,
    required this.date,
    required this.state,
    this.checkInTime,
    this.checkOutTime,
    required this.isKeypad,
    this.deviceId,
    this.appId,
    this.appVersion,
    this.isForced = false,
    this.isModified = false,
    this.isDelayed = false,
    this.comment,
    this.thumbnail,
    this.recognizeLogs,
    required this.createdAt,
    this.updatedAt,
    this.studentName,
    this.lectureName,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString(),
      studentId: json['student_id'].toString(),
      lectureId: json['lecture_id']?.toString(),
      date: DateTime.parse(json['date']),
      state: json['state'] ?? AppConstants.stateAttendIn,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      isKeypad: json['is_keypad'] ?? false,
      deviceId: json['device_id'],
      appId: json['app_id'],
      appVersion: json['app_version'],
      isForced: json['is_forced'] ?? false,
      isModified: json['is_modified'] ?? false,
      isDelayed: json['is_delayed'] ?? false,
      comment: json['comment'],
      thumbnail: json['thumbnail'],
      recognizeLogs: json['recognize_logs'] != null
          ? (json['recognize_logs'] as List)
              .map((log) => RecognizeLogModel.fromJson(log))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      studentName: json['student_name'],
      lectureName: json['lecture_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'lecture_id': lectureId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'state': state,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'is_keypad': isKeypad,
      'device_id': deviceId,
      'app_id': appId,
      'app_version': appVersion,
      'is_forced': isForced,
      'is_modified': isModified,
      'is_delayed': isDelayed,
      'comment': comment,
      'thumbnail': thumbnail,
      'recognize_logs': recognizeLogs?.map((log) => log.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // 출석 상태인지 확인 (기존 앱 로직과 동일)
  bool get isAttendState {
    return state == AppConstants.stateAttendIn ||
           state == AppConstants.stateAttendClass ||
           state == AppConstants.stateAttendLate;
  }

  // 퇴실 상태인지 확인 (기존 앱 로직과 동일)
  bool get isOutbackState {
    return state == AppConstants.stateLeaveOut ||
           state == AppConstants.stateLeaveEarly;
  }

  // 상태 설명 텍스트
  String get stateDescription {
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

  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? lectureId,
    DateTime? date,
    int? state,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isKeypad,
    String? deviceId,
    String? appId,
    String? appVersion,
    bool? isForced,
    bool? isModified,
    bool? isDelayed,
    String? comment,
    String? thumbnail,
    List<RecognizeLogModel>? recognizeLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentName,
    String? lectureName,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      lectureId: lectureId ?? this.lectureId,
      date: date ?? this.date,
      state: state ?? this.state,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isKeypad: isKeypad ?? this.isKeypad,
      deviceId: deviceId ?? this.deviceId,
      appId: appId ?? this.appId,
      appVersion: appVersion ?? this.appVersion,
      isForced: isForced ?? this.isForced,
      isModified: isModified ?? this.isModified,
      isDelayed: isDelayed ?? this.isDelayed,
      comment: comment ?? this.comment,
      thumbnail: thumbnail ?? this.thumbnail,
      recognizeLogs: recognizeLogs ?? this.recognizeLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      lectureName: lectureName ?? this.lectureName,
    );
  }
}

class RecognizeLogModel {
  final String? id;
  final String attendanceId;
  final DateTime recognizedAt;
  final double confidence;
  final String? recognitionData;
  final bool success;

  RecognizeLogModel({
    this.id,
    required this.attendanceId,
    required this.recognizedAt,
    required this.confidence,
    this.recognitionData,
    required this.success,
  });

  factory RecognizeLogModel.fromJson(Map<String, dynamic> json) {
    return RecognizeLogModel(
      id: json['id']?.toString(),
      attendanceId: json['attendance_id'].toString(),
      recognizedAt: DateTime.parse(json['recognized_at']),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recognitionData: json['recognition_data'],
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendance_id': attendanceId,
      'recognized_at': recognizedAt.toIso8601String(),
      'confidence': confidence,
      'recognition_data': recognitionData,
      'success': success,
    };
  }
}