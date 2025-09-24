class FaceRecognitionResult {
  final String requestId;
  final int elapsedTotal;
  final List<FaceInfo> faces;
  final ImageSize? imageSize;

  FaceRecognitionResult({
    required this.requestId,
    required this.elapsedTotal,
    required this.faces,
    this.imageSize,
  });

  bool get isSuccess => faces.isNotEmpty;

  String? get faceId {
    if (faces.isNotEmpty && faces.first.faceId != 'Unknown') {
      return faces.first.faceId;
    }
    return null;
  }

  int? get similarity {
    if (faces.isNotEmpty) {
      return faces.first.similarity;
    }
    return null;
  }

  factory FaceRecognitionResult.fromJson(Map<String, dynamic> json) {
    final facesList = <FaceInfo>[];

    if (json['Faces'] != null && json['Faces'] is List) {
      for (final faceData in json['Faces']) {
        if (faceData is Map<String, dynamic>) {
          facesList.add(FaceInfo.fromJson(faceData));
        }
      }
    }

    return FaceRecognitionResult(
      requestId: json['RequestId'] ?? '',
      elapsedTotal: json['ElapsedTotal'] ?? 0,
      faces: facesList,
      imageSize: json['ImageSize'] != null
          ? ImageSize.fromJson(json['ImageSize'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RequestId': requestId,
      'ElapsedTotal': elapsedTotal,
      'Faces': faces.map((face) => face.toJson()).toList(),
      'ImageSize': imageSize?.toJson(),
    };
  }
}

class FaceInfo {
  final String faceId;
  final int similarity;
  final FaceRect? faceRect;
  final int age;
  final Gender? gender;
  final bool masked;
  final List<Point>? landmarks;
  final Pose? pose;
  final Emotion? emotion;

  FaceInfo({
    required this.faceId,
    required this.similarity,
    this.faceRect,
    this.age = 0,
    this.gender,
    this.masked = false,
    this.landmarks,
    this.pose,
    this.emotion,
  });

  bool get isKnown => faceId != 'Unknown';

  factory FaceInfo.fromJson(Map<String, dynamic> json) {
    final landmarksList = <Point>[];
    if (json['Landmarks'] != null && json['Landmarks'] is List) {
      for (final pointData in json['Landmarks']) {
        if (pointData is Map<String, dynamic>) {
          landmarksList.add(Point.fromJson(pointData));
        }
      }
    }

    return FaceInfo(
      faceId: json['FaceId'] ?? 'Unknown',
      similarity: json['Similarity'] ?? 0,
      faceRect: json['FaceRect'] != null
          ? FaceRect.fromJson(json['FaceRect'])
          : null,
      age: json['Age'] ?? 0,
      gender: json['Gender'] != null
          ? Gender.fromJson(json['Gender'])
          : null,
      masked: json['Masked'] ?? false,
      landmarks: landmarksList.isNotEmpty ? landmarksList : null,
      pose: json['Pose'] != null
          ? Pose.fromJson(json['Pose'])
          : null,
      emotion: json['Emotion'] != null
          ? Emotion.fromJson(json['Emotion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FaceId': faceId,
      'Similarity': similarity,
      'FaceRect': faceRect?.toJson(),
      'Age': age,
      'Gender': gender?.toJson(),
      'Masked': masked,
      'Landmarks': landmarks?.map((point) => point.toJson()).toList(),
      'Pose': pose?.toJson(),
      'Emotion': emotion?.toJson(),
    };
  }
}

class FaceRect {
  final int x;
  final int y;
  final int width;
  final int height;

  FaceRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory FaceRect.fromJson(Map<String, dynamic> json) {
    return FaceRect(
      x: json['X'] ?? 0,
      y: json['Y'] ?? 0,
      width: json['Width'] ?? 0,
      height: json['Height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'X': x,
      'Y': y,
      'Width': width,
      'Height': height,
    };
  }
}

class Gender {
  final double male;
  final double female;

  Gender({
    required this.male,
    required this.female,
  });

  String get dominantGender => male > female ? 'Male' : 'Female';
  double get confidence => male > female ? male : female;

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      male: (json['Male'] ?? 0.0).toDouble(),
      female: (json['Female'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Male': male,
      'Female': female,
    };
  }
}

class Point {
  final int x;
  final int y;

  Point({
    required this.x,
    required this.y,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: json['X'] ?? 0,
      y: json['Y'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'X': x,
      'Y': y,
    };
  }
}

class Pose {
  final double pitch;
  final double roll;
  final double yaw;

  Pose({
    required this.pitch,
    required this.roll,
    required this.yaw,
  });

  factory Pose.fromJson(Map<String, dynamic> json) {
    return Pose(
      pitch: (json['Pitch'] ?? 0.0).toDouble(),
      roll: (json['Roll'] ?? 0.0).toDouble(),
      yaw: (json['Yaw'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Pitch': pitch,
      'Roll': roll,
      'Yaw': yaw,
    };
  }
}

class Emotion {
  final int neutral;
  final int happy;
  final int sad;
  final int surprise;
  final int anger;

  Emotion({
    required this.neutral,
    required this.happy,
    required this.sad,
    required this.surprise,
    required this.anger,
  });

  String get dominantEmotion {
    final emotions = {
      'neutral': neutral,
      'happy': happy,
      'sad': sad,
      'surprise': surprise,
      'anger': anger,
    };

    return emotions.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int get maxConfidence {
    return [neutral, happy, sad, surprise, anger]
        .reduce((a, b) => a > b ? a : b);
  }

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      neutral: json['Neutral'] ?? 0,
      happy: json['Happy'] ?? 0,
      sad: json['Sad'] ?? 0,
      surprise: json['Surprise'] ?? 0,
      anger: json['Anger'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Neutral': neutral,
      'Happy': happy,
      'Sad': sad,
      'Surprise': surprise,
      'Anger': anger,
    };
  }
}

class ImageSize {
  final int width;
  final int height;

  ImageSize({
    required this.width,
    required this.height,
  });

  factory ImageSize.fromJson(Map<String, dynamic> json) {
    return ImageSize(
      width: json['Width'] ?? 0,
      height: json['Height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Width': width,
      'Height': height,
    };
  }
}

// Face API 서비스 상태
class ServiceStatus {
  final int statusCode;
  final String statusMessage;
  final String? apiToken;

  ServiceStatus({
    required this.statusCode,
    required this.statusMessage,
    this.apiToken,
  });

  bool get isSuccess => statusCode == 200;

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    return ServiceStatus(
      statusCode: json['StatusCode'] ?? 0,
      statusMessage: json['StatusMessage'] ?? '',
      apiToken: json['ApiToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusCode': statusCode,
      'StatusMessage': statusMessage,
      'ApiToken': apiToken,
    };
  }
}

// 얼굴인식 설정
class FaceRecognitionConfig {
  final double similarity;
  final int maxRetryCount;
  final bool withLandmarks;
  final bool withPose;
  final bool withAgeGender;
  final bool withEmotions;
  final bool withMasked;
  final bool multiDetection;

  FaceRecognitionConfig({
    this.similarity = 70.0,
    this.maxRetryCount = 10,
    this.withLandmarks = false,
    this.withPose = false,
    this.withAgeGender = false,
    this.withEmotions = false,
    this.withMasked = false,
    this.multiDetection = false,
  });

  factory FaceRecognitionConfig.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionConfig(
      similarity: (json['similarity'] ?? 70.0).toDouble(),
      maxRetryCount: json['maxRetryCount'] ?? 10,
      withLandmarks: json['withLandmarks'] ?? false,
      withPose: json['withPose'] ?? false,
      withAgeGender: json['withAgeGender'] ?? false,
      withEmotions: json['withEmotions'] ?? false,
      withMasked: json['withMasked'] ?? false,
      multiDetection: json['multiDetection'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'similarity': similarity,
      'maxRetryCount': maxRetryCount,
      'withLandmarks': withLandmarks,
      'withPose': withPose,
      'withAgeGender': withAgeGender,
      'withEmotions': withEmotions,
      'withMasked': withMasked,
      'multiDetection': multiDetection,
    };
  }

  FaceRecognitionConfig copyWith({
    double? similarity,
    int? maxRetryCount,
    bool? withLandmarks,
    bool? withPose,
    bool? withAgeGender,
    bool? withEmotions,
    bool? withMasked,
    bool? multiDetection,
  }) {
    return FaceRecognitionConfig(
      similarity: similarity ?? this.similarity,
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      withLandmarks: withLandmarks ?? this.withLandmarks,
      withPose: withPose ?? this.withPose,
      withAgeGender: withAgeGender ?? this.withAgeGender,
      withEmotions: withEmotions ?? this.withEmotions,
      withMasked: withMasked ?? this.withMasked,
      multiDetection: multiDetection ?? this.multiDetection,
    );
  }
}