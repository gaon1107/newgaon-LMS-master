class StudentVO {
  final String studentId;
  final String studentName;
  final String branchId;
  final String classId;
  final String className;
  final bool isActive;
  final String? profileImage;
  final String? contactNumber;
  final String? parentContact;
  final DateTime? birthDate;
  final String? address;
  final String? notes;

  StudentVO({
    required this.studentId,
    required this.studentName,
    required this.branchId,
    required this.classId,
    required this.className,
    this.isActive = true,
    this.profileImage,
    this.contactNumber,
    this.parentContact,
    this.birthDate,
    this.address,
    this.notes,
  });

  factory StudentVO.fromJson(Map<String, dynamic> json) {
    return StudentVO(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      branchId: json['branchId'] ?? '',
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      isActive: json['isActive'] ?? true,
      profileImage: json['profileImage'],
      contactNumber: json['contactNumber'],
      parentContact: json['parentContact'],
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'])
          : null,
      address: json['address'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'branchId': branchId,
      'classId': classId,
      'className': className,
      'isActive': isActive,
      'profileImage': profileImage,
      'contactNumber': contactNumber,
      'parentContact': parentContact,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'notes': notes,
    };
  }

  StudentVO copyWith({
    String? studentId,
    String? studentName,
    String? branchId,
    String? classId,
    String? className,
    bool? isActive,
    String? profileImage,
    String? contactNumber,
    String? parentContact,
    DateTime? birthDate,
    String? address,
    String? notes,
  }) {
    return StudentVO(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      branchId: branchId ?? this.branchId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      contactNumber: contactNumber ?? this.contactNumber,
      parentContact: parentContact ?? this.parentContact,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentVO && other.studentId == studentId;
  }

  @override
  int get hashCode => studentId.hashCode;

  @override
  String toString() {
    return 'StudentVO{studentId: $studentId, studentName: $studentName, className: $className}';
  }
}