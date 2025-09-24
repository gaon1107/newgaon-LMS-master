import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/student_vo.dart';
import '../models/lms_student_state.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'gf_attendance.db';
  static const int _dbVersion = 1;

  // 테이블 이름
  static const String _studentsTable = 'students';
  static const String _pendingStatesTable = 'pending_states';
  static const String _settingsTable = 'settings';

  // 싱글톤 패턴
  static DatabaseHelper? _instance;
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();
  DatabaseHelper._();

  // 데이터베이스 초기화
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    // 학생 정보 테이블
    await db.execute('''
      CREATE TABLE $_studentsTable (
        studentId TEXT PRIMARY KEY,
        studentName TEXT NOT NULL,
        branchId TEXT NOT NULL,
        classId TEXT NOT NULL,
        className TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        profileImage TEXT,
        contactNumber TEXT,
        parentContact TEXT,
        birthDate TEXT,
        address TEXT,
        notes TEXT,
        lastUpdated TEXT,
        syncStatus INTEGER DEFAULT 1
      )
    ''');

    // 대기중인 출결 상태 테이블 (오프라인 지원)
    await db.execute('''
      CREATE TABLE $_pendingStatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT NOT NULL,
        state INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        isKeypad INTEGER DEFAULT 0,
        isForced INTEGER DEFAULT 0,
        recognizeLogs TEXT,
        hasThumbnail INTEGER DEFAULT 0,
        thumbnailImage BLOB,
        createdAt TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        lastRetryAt TEXT,
        errorMessage TEXT
      )
    ''');

    // 설정 테이블
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 인덱스 생성
    await db.execute('CREATE INDEX idx_students_branch ON $_studentsTable(branchId)');
    await db.execute('CREATE INDEX idx_students_class ON $_studentsTable(classId)');
    await db.execute('CREATE INDEX idx_pending_states_student ON $_pendingStatesTable(studentId)');
    await db.execute('CREATE INDEX idx_pending_states_timestamp ON $_pendingStatesTable(timestamp)');
  }

  // 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 향후 스키마 변경 시 구현
  }

  // === 학생 관리 ===

  // 학생 정보 저장/업데이트
  Future<void> insertOrUpdateStudent(StudentVO student) async {
    final db = await database;

    await db.insert(
      _studentsTable,
      {
        'studentId': student.studentId,
        'studentName': student.studentName,
        'branchId': student.branchId,
        'classId': student.classId,
        'className': student.className,
        'isActive': student.isActive ? 1 : 0,
        'profileImage': student.profileImage,
        'contactNumber': student.contactNumber,
        'parentContact': student.parentContact,
        'birthDate': student.birthDate?.toIso8601String(),
        'address': student.address,
        'notes': student.notes,
        'lastUpdated': DateTime.now().toIso8601String(),
        'syncStatus': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 여러 학생 정보 일괄 저장
  Future<void> insertOrUpdateStudents(List<StudentVO> students) async {
    final db = await database;
    final batch = db.batch();

    for (final student in students) {
      batch.insert(
        _studentsTable,
        {
          'studentId': student.studentId,
          'studentName': student.studentName,
          'branchId': student.branchId,
          'classId': student.classId,
          'className': student.className,
          'isActive': student.isActive ? 1 : 0,
          'profileImage': student.profileImage,
          'contactNumber': student.contactNumber,
          'parentContact': student.parentContact,
          'birthDate': student.birthDate?.toIso8601String(),
          'address': student.address,
          'notes': student.notes,
          'lastUpdated': DateTime.now().toIso8601String(),
          'syncStatus': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // 모든 학생 정보 조회
  Future<List<StudentVO>> getAllStudents() async {
    final db = await database;
    final maps = await db.query(
      _studentsTable,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'studentName ASC',
    );

    return maps.map((map) => _studentFromMap(map)).toList();
  }

  // 학생 ID로 조회
  Future<StudentVO?> getStudentById(String studentId) async {
    final db = await database;
    final maps = await db.query(
      _studentsTable,
      where: 'studentId = ?',
      whereArgs: [studentId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _studentFromMap(maps.first);
    }
    return null;
  }

  // 브랜치별 학생 조회
  Future<List<StudentVO>> getStudentsByBranch(String branchId) async {
    final db = await database;
    final maps = await db.query(
      _studentsTable,
      where: 'branchId = ? AND isActive = ?',
      whereArgs: [branchId, 1],
      orderBy: 'className ASC, studentName ASC',
    );

    return maps.map((map) => _studentFromMap(map)).toList();
  }

  // 학생 정보 삭제
  Future<void> deleteStudent(String studentId) async {
    final db = await database;
    await db.update(
      _studentsTable,
      {'isActive': 0, 'lastUpdated': DateTime.now().toIso8601String()},
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
  }

  // === 대기중인 출결 상태 관리 (오프라인 지원) ===

  // 출결 상태 임시 저장 (서버 전송 실패 시)
  Future<int> insertPendingState(LmsStudentState state) async {
    final db = await database;

    return await db.insert(_pendingStatesTable, {
      'studentId': state.studentId,
      'state': state.state,
      'timestamp': state.timestamp,
      'isKeypad': state.isKeypad ? 1 : 0,
      'isForced': state.isForced ? 1 : 0,
      'recognizeLogs': state.recognizeLogs,
      'hasThumbnail': state.hasThumbnail ? 1 : 0,
      'thumbnailImage': state.thumbnailImage,
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
      'lastRetryAt': null,
      'errorMessage': null,
    });
  }

  // 대기중인 출결 상태 조회
  Future<List<Map<String, dynamic>>> getPendingStates({int? limit}) async {
    final db = await database;

    return await db.query(
      _pendingStatesTable,
      orderBy: 'createdAt ASC',
      limit: limit,
    );
  }

  // 출결 상태 재시도 횟수 업데이트
  Future<void> updatePendingStateRetry(int id, String? errorMessage) async {
    final db = await database;

    await db.update(
      _pendingStatesTable,
      {
        'retryCount': 'retryCount + 1',
        'lastRetryAt': DateTime.now().toIso8601String(),
        'errorMessage': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 성공적으로 전송된 출결 상태 삭제
  Future<void> deletePendingState(int id) async {
    final db = await database;
    await db.delete(
      _pendingStatesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 재시도 횟수 초과한 항목 삭제
  Future<void> cleanupFailedPendingStates({int maxRetries = 10}) async {
    final db = await database;
    await db.delete(
      _pendingStatesTable,
      where: 'retryCount >= ?',
      whereArgs: [maxRetries],
    );
  }

  // === 설정 관리 ===

  // 설정값 저장
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      _settingsTable,
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 설정값 조회
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // 설정값 삭제
  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // === 데이터베이스 관리 ===

  // 모든 데이터 삭제
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_studentsTable);
    await db.delete(_pendingStatesTable);
    await db.delete(_settingsTable);
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 통계 정보 조회
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final studentsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_studentsTable WHERE isActive = 1')
    ) ?? 0;

    final pendingCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_pendingStatesTable')
    ) ?? 0;

    final settingsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_settingsTable')
    ) ?? 0;

    return {
      'students': studentsCount,
      'pendingStates': pendingCount,
      'settings': settingsCount,
    };
  }

  // 헬퍼 메서드: Map을 StudentVO로 변환
  StudentVO _studentFromMap(Map<String, dynamic> map) {
    return StudentVO(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      branchId: map['branchId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      isActive: (map['isActive'] ?? 1) == 1,
      profileImage: map['profileImage'],
      contactNumber: map['contactNumber'],
      parentContact: map['parentContact'],
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'])
          : null,
      address: map['address'],
      notes: map['notes'],
    );
  }

  // 헬퍼 메서드: Map을 LmsStudentState로 변환
  LmsStudentState _pendingStateFromMap(Map<String, dynamic> map) {
    return LmsStudentState(
      studentId: map['studentId'] ?? '',
      state: map['state'] ?? 1,
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      isKeypad: (map['isKeypad'] ?? 0) == 1,
      isForced: (map['isForced'] ?? 0) == 1,
      recognizeLogs: map['recognizeLogs'] ?? '',
      hasThumbnail: (map['hasThumbnail'] ?? 0) == 1,
      thumbnailImage: map['thumbnailImage'] as Uint8List?,
    );
  }
}