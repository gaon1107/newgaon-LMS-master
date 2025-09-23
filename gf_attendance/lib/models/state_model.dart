import '../utils/app_constants.dart';

// 출결 상태 모델 (백엔드 StateVO와 동일)
class StateModel {
  final String? id;
  final String studentId;
  final int state; // 0,1,3: 출석상태, 2,4: 퇴실상태
  final DateTime? taggedAt;
  final bool isKeypad;
  final String? deviceId;
  final String? appId;
  final String? appVersion;
  final bool isForced;
  final bool isModified;
  final bool isDelayed;
  final String? comment;
  final String? thumbnail;
  final List<RecognizeLogModel>? recognizeLog;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final String? modifiedBy;

  // 조인 결과 필드
  final String? studentName;
  final String? stateDescription;
  final String? identifier;
  final bool? sms;

  StateModel({
    this.id,
    required this.studentId,
    required this.state,
    this.taggedAt,
    this.isKeypad = false,
    this.deviceId,
    this.appId,
    this.appVersion,
    this.isForced = false,
    this.isModified = false,
    this.isDelayed = false,
    this.comment,
    this.thumbnail,
    this.recognizeLog,
    this.createdAt,
    this.modifiedAt,
    this.modifiedBy,
    this.studentName,
    this.stateDescription,
    this.identifier,
    this.sms,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id']?.toString(),
      studentId: json['studentId']?.toString() ?? json['student_id']?.toString() ?? '',
      state: json['state'] ?? 0,
      taggedAt: json['taggedAt'] != null ? DateTime.parse(json['taggedAt']) : null,
      isKeypad: json['isKeypad'] ?? false,
      deviceId: json['deviceId'],
      appId: json['appId'],
      appVersion: json['appVersion'],
      isForced: json['isForced'] ?? false,
      isModified: json['isModified'] ?? false,
      isDelayed: json['isDelayed'] ?? false,
      comment: json['comment'],
      thumbnail: json['thumbnail'],
      recognizeLog: json['recognizeLog'] != null
          ? (json['recognizeLog'] as List)
              .map((log) => RecognizeLogModel.fromJson(log))
              .toList()
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt']) : null,
      modifiedBy: json['modifiedBy'],
      studentName: json['studentName'],
      stateDescription: json['stateDescription'],
      identifier: json['identifier'],
      sms: json['sms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'state': state,
      'taggedAt': taggedAt?.toIso8601String(),
      'isKeypad': isKeypad,
      'deviceId': deviceId,
      'appId': appId,
      'appVersion': appVersion,
      'isForced': isForced,
      'isModified': isModified,
      'isDelayed': isDelayed,
      'comment': comment,
      'thumbnail': thumbnail,
      'recognizeLog': recognizeLog?.map((log) => log.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'modifiedBy': modifiedBy,
      'studentName': studentName,
      'stateDescription': stateDescription,
      'identifier': identifier,
      'sms': sms,
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
  String get statusText {
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

  StateModel copyWith({
    String? id,
    String? studentId,
    int? state,
    DateTime? taggedAt,
    bool? isKeypad,
    String? deviceId,
    String? appId,
    String? appVersion,
    bool? isForced,
    bool? isModified,
    bool? isDelayed,
    String? comment,
    String? thumbnail,
    List<RecognizeLogModel>? recognizeLog,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? modifiedBy,
    String? studentName,
    String? stateDescription,
    String? identifier,
    bool? sms,
  }) {
    return StateModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      state: state ?? this.state,
      taggedAt: taggedAt ?? this.taggedAt,
      isKeypad: isKeypad ?? this.isKeypad,
      deviceId: deviceId ?? this.deviceId,
      appId: appId ?? this.appId,
      appVersion: appVersion ?? this.appVersion,
      isForced: isForced ?? this.isForced,
      isModified: isModified ?? this.isModified,
      isDelayed: isDelayed ?? this.isDelayed,
      comment: comment ?? this.comment,
      thumbnail: thumbnail ?? this.thumbnail,
      recognizeLog: recognizeLog ?? this.recognizeLog,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      studentName: studentName ?? this.studentName,
      stateDescription: stateDescription ?? this.stateDescription,
      identifier: identifier ?? this.identifier,
      sms: sms ?? this.sms,
    );
  }
}

// 인식 로그 모델
class RecognizeLogModel {
  final String? id;
  final String? stateId;
  final DateTime recognizedAt;
  final double confidence;
  final String? recognitionData;
  final bool success;

  RecognizeLogModel({
    this.id,
    this.stateId,
    required this.recognizedAt,
    required this.confidence,
    this.recognitionData,
    required this.success,
  });

  factory RecognizeLogModel.fromJson(Map<String, dynamic> json) {
    return RecognizeLogModel(
      id: json['id']?.toString(),
      stateId: json['stateId']?.toString(),
      recognizedAt: DateTime.parse(json['recognizedAt']),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recognitionData: json['recognitionData'],
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stateId': stateId,
      'recognizedAt': recognizedAt.toIso8601String(),
      'confidence': confidence,
      'recognitionData': recognitionData,
      'success': success,
    };
  }
}