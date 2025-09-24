import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../models/lms_student_state.dart';
import '../services/gaon_face_service.dart';
import '../services/lms_api_service.dart';
import '../services/audio_service.dart';
import '../services/sync_service.dart';
import '../utils/database_helper.dart';
import '../widgets/camera_section.dart';
import '../widgets/menu_section.dart';
import '../widgets/student_management_dialog.dart';

// AppState enum (Android 앱과 동일)
enum AppState {
  stateRest,              // 대기 상태
  stateRecognizeIn,       // 등원 인식
  stateRecognizeOut,      // 하원 인식
  stateRecognizeTempout,  // 외출 인식
  stateRecognizeReturn,   // 복귀 인식
  stateRecognizeEarlyout, // 조퇴 인식
  stateRegist,           // 얼굴 등록
}

class MainAttendanceScreen extends StatefulWidget {
  const MainAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<MainAttendanceScreen> createState() => _MainAttendanceScreenState();
}

class _MainAttendanceScreenState extends State<MainAttendanceScreen> with WidgetsBindingObserver {
  // 상태 관리
  AppState _currentState = AppState.stateRest;
  bool _isProcessing = false;
  String _statusMessage = '대기 중...';
  String _keypadInput = '';
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _currentCameraIndex = 0;
  int _recognitionAttempts = 0;
  static const int _maxAttempts = 5;

  // 색상 테마
  static const Color _primaryColor = Color(0xff215968);
  static const Color _accentColor = Color(0xff219189);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeApp() async {
    await _initializeCamera();
    await _checkServiceStatus();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCamera();
      } else {
        setState(() {
          _statusMessage = '카메라를 사용할 수 없습니다.';
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() {
        _statusMessage = '카메라 초기화 실패';
      });
    }
  }

  Future<void> _setupCamera() async {
    if (_cameras.isEmpty) return;

    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '카메라를 전환하는 중...';
    });

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupCamera();

    setState(() {
      _isProcessing = false;
      _statusMessage = _getStatusMessage();
    });
  }

  Future<void> _checkServiceStatus() async {
    final gaonInitialized = GaonFaceService.isInitialized;
    final lmsInitialized = LmsApiService.isInitialized;
    final audioInitialized = AudioService.isInitialized;

    debugPrint('Service status - Gaon: $gaonInitialized, LMS: $lmsInitialized, Audio: $audioInitialized');

    if (!gaonInitialized || !lmsInitialized || !audioInitialized) {
      setState(() {
        _statusMessage = '서비스 초기화 중...';
      });

      if (!gaonInitialized) await GaonFaceService.initialize();
      if (!lmsInitialized) await LmsApiService.initialize();
      if (!audioInitialized) await AudioService.initialize();
    }

    setState(() {
      _statusMessage = _getStatusMessage();
    });
  }

  String _getStatusMessage() {
    switch (_currentState) {
      case AppState.stateRest:
        return '출결 방법을 선택해주세요.';
      case AppState.stateRecognizeIn:
        return '등원 인식 중... 얼굴을 카메라에 맞춰주세요.';
      case AppState.stateRecognizeOut:
        return '하원 인식 중... 얼굴을 카메라에 맞춰주세요.';
      case AppState.stateRecognizeTempout:
        return '외출 인식 중... 얼굴을 카메라에 맞춰주세요.';
      case AppState.stateRecognizeReturn:
        return '복귀 인식 중... 얼굴을 카메라에 맞춰주세요.';
      case AppState.stateRecognizeEarlyout:
        return '조퇴 인식 중... 얼굴을 카메라에 맞춰주세요.';
      case AppState.stateRegist:
        return '얼굴 등록 모드입니다.';
    }
  }

  Future<void> _startFaceRecognition(int stateValue) async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // AppState 설정
    switch (stateValue) {
      case 1:
        _currentState = AppState.stateRecognizeIn;
        break;
      case 2:
        _currentState = AppState.stateRecognizeOut;
        break;
      case 3:
        _currentState = AppState.stateRecognizeTempout;
        break;
      case 4:
        _currentState = AppState.stateRecognizeReturn;
        break;
      case 5:
        _currentState = AppState.stateRecognizeEarlyout;
        break;
    }

    setState(() {
      _isProcessing = true;
      _recognitionAttempts = 0;
      _statusMessage = _getStatusMessage();
    });

    await _performFaceRecognition(stateValue);
  }

  Future<void> _performFaceRecognition(int stateValue) async {
    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      if (!_isProcessing) break; // 중단된 경우

      _recognitionAttempts = attempt + 1;
      setState(() {
        _statusMessage = '${_getStatusMessage()} (${_recognitionAttempts}/$_maxAttempts 시도)';
      });

      try {
        // 카메라에서 이미지 캡처
        final image = await _cameraController!.takePicture();
        final imageBytes = await image.readAsBytes();

        // 얼굴 인식 API 호출
        final result = await GaonFaceService.recognizeFace(imageBytes);

        if (result != null && result.isSuccess && result.faceId != null) {
          // 인식 성공
          final studentId = result.faceId!;
          final similarity = result.similarity ?? 0;

          // 학생 정보 조회
          final dbHelper = DatabaseHelper.instance;
          final student = await dbHelper.getStudentById(studentId);

          if (student != null) {
            // 출결 상태 생성
            final attendanceState = LmsStudentState.fromFaceRecognition(
              studentId: studentId,
              state: stateValue,
              faceId: result.faceId!,
              similarity: similarity,
              thumbnailImage: imageBytes,
            );

            // 서버로 전송 (오프라인 지원 포함)
            final success = await SyncService.processStudentState(attendanceState);

            // 음성 피드백
            await AudioService.playStateMessage(
              studentName: student.studentName,
              state: stateValue,
              isSuccess: true,
            );

            setState(() {
              _isProcessing = false;
              _currentState = AppState.stateRest;
              _statusMessage = success
                  ? '${student.studentName}님 ${attendanceState.stateText} 완료!'
                  : '${student.studentName}님 ${attendanceState.stateText} 완료! (오프라인 저장)';
            });

            // 3초 후 초기 상태로
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _statusMessage = _getStatusMessage();
                });
              }
            });

            return; // 성공적으로 완료
          } else {
            // 등록되지 않은 학생
            await AudioService.playFail('등록되지 않은 학생입니다.');
          }
        }

        // 다음 시도까지 짧은 대기
        await Future.delayed(const Duration(milliseconds: 800));

      } catch (e) {
        debugPrint('Face recognition attempt $attempt failed: $e');
      }
    }

    // 모든 시도 실패
    await AudioService.playFail('얼굴인식에 실패했습니다. 키패드를 이용해주세요.');

    setState(() {
      _isProcessing = false;
      _currentState = AppState.stateRest;
      _statusMessage = '얼굴인식에 실패했습니다. 다시 시도하거나 키패드를 이용해주세요.';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = _getStatusMessage();
        });
      }
    });
  }

  Future<void> _processKeypadInput(int stateValue) async {
    if (_keypadInput.isEmpty) {
      await AudioService.playErrorSound();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = '학번을 확인하는 중...';
    });

    try {
      // 학생 정보 조회
      final dbHelper = DatabaseHelper.instance;
      final student = await dbHelper.getStudentById(_keypadInput);

      if (student != null) {
        // 출결 상태 생성
        final attendanceState = LmsStudentState.fromKeypadInput(
          studentId: _keypadInput,
          state: stateValue,
        );

        // 서버로 전송
        final success = await SyncService.processStudentState(attendanceState);

        // 음성 피드백
        await AudioService.playStateMessage(
          studentName: student.studentName,
          state: stateValue,
          isSuccess: true,
        );

        setState(() {
          _isProcessing = false;
          _statusMessage = success
              ? '${student.studentName}님 ${attendanceState.stateText} 완료!'
              : '${student.studentName}님 ${attendanceState.stateText} 완료! (오프라인 저장)';
          _keypadInput = '';
        });

        // 3초 후 초기 상태로
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = _getStatusMessage();
            });
          }
        });
      } else {
        await AudioService.playFail('등록되지 않은 학번입니다.');
        setState(() {
          _isProcessing = false;
          _statusMessage = '등록되지 않은 학번입니다.';
          _keypadInput = '';
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = _getStatusMessage();
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Keypad input processing error: $e');
      await AudioService.playFail('처리 중 오류가 발생했습니다.');
      setState(() {
        _isProcessing = false;
        _statusMessage = '처리 중 오류가 발생했습니다.';
        _keypadInput = '';
      });
    }
  }

  void _onKeypadInput(String key) {
    if (_isProcessing) return;

    AudioService.playKeypadSound();

    setState(() {
      if (key == 'C') {
        _keypadInput = '';
      } else if (key == 'B') {
        if (_keypadInput.isNotEmpty) {
          _keypadInput = _keypadInput.substring(0, _keypadInput.length - 1);
        }
      } else {
        if (_keypadInput.length < 10) { // 최대 10자리
          _keypadInput += key;
        }
      }
    });
  }

  void _stopCurrentProcess() {
    setState(() {
      _isProcessing = false;
      _currentState = AppState.stateRest;
      _statusMessage = _getStatusMessage();
      _keypadInput = '';
    });
  }

  Future<void> _showStudentManagement() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const StudentManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // 좌측 카메라 섹션 (70%)
          Expanded(
            flex: 7,
            child: CameraSection(
              cameraController: _cameraController,
              isProcessing: _isProcessing,
              currentState: _currentState,
              onSwitchCamera: _switchCamera,
            ),
          ),

          // 우측 메뉴 섹션 (30%)
          Expanded(
            flex: 3,
            child: MenuSection(
              currentState: _currentState,
              statusMessage: _statusMessage,
              keypadInput: _keypadInput,
              isProcessing: _isProcessing,
              onAttendanceButtonPressed: _startFaceRecognition,
              onKeypadButtonPressed: _processKeypadInput,
              onKeypadInput: _onKeypadInput,
              onStopProcess: _stopCurrentProcess,
              onShowStudentManagement: _showStudentManagement,
            ),
          ),
        ],
      ),
    );
  }
}