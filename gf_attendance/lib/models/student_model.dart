class StudentModel {
  final String id;
  final String name;
  final String studentNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? grade;
  final String? className;
  final DateTime registrationDate;
  final String status;
  final String? profileImage;
  final List<String>? faceTemplates; // 얼굴인식용 템플릿
  final String? notes;
  final String? identifier; // 고유 식별자
  final String? userId; // 사용자 ID

  StudentModel({
    required this.id,
    required this.name,
    required this.studentNumber,
    this.birthDate,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.grade,
    this.className,
    required this.registrationDate,
    required this.status,
    this.profileImage,
    this.faceTemplates,
    this.notes,
    this.identifier,
    this.userId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      studentNumber: json['student_number'] ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      grade: json['grade'],
      className: json['class_name'],
      registrationDate: DateTime.parse(json['registration_date']),
      status: json['status'] ?? 'active',
      profileImage: json['profile_image'],
      faceTemplates: json['face_templates'] != null
          ? List<String>.from(json['face_templates'])
          : null,
      notes: json['notes'],
      identifier: json['identifier'],
      userId: json['userId'] ?? json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'student_number': studentNumber,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'grade': grade,
      'class_name': className,
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'profile_image': profileImage,
      'face_templates': faceTemplates,
      'notes': notes,
    };
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? studentNumber,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? grade,
    String? className,
    DateTime? registrationDate,
    String? status,
    String? profileImage,
    List<String>? faceTemplates,
    String? notes,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentNumber: studentNumber ?? this.studentNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      grade: grade ?? this.grade,
      className: className ?? this.className,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      faceTemplates: faceTemplates ?? this.faceTemplates,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'StudentModel(id: $id, name: $name, studentNumber: $studentNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel &&
        other.id == id &&
        other.name == name &&
        other.studentNumber == studentNumber;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ studentNumber.hashCode;
}