import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/attendance_provider.dart';
import '../../services/gaon_face_service.dart';
import '../../models/student_model.dart';
import '../../utils/app_constants.dart';
import '../../widgets/loading_widget.dart';
import 'package:audioplayers/audioplayers.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final String? mode;
  final StudentModel? selectedStudent;

  const FaceRecognitionScreen({
    Key? key,
    this.mode,
    this.selectedStudent,
  }) : super(key: key);

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecognizing = false;
  bool _isProcessing = false;
  int _currentCameraIndex = 1; // 전면 카메라를 기본으로
  String _statusMessage = '얼굴을 인식합니다.';
  Color _statusColor = Colors.black;
  int _recognitionCounter = 0;
  final int _maxRecognitionAttempts = 10;

  // 출결 상태별 색상
  final Map<int, Color> _stateColors = {
    AppConstants.stateAttendIn: const Color(AppConstants.successColor),
    AppConstants.stateAttendClass: const Color(AppConstants.accentColorValue),
    AppConstants.stateLeaveOut: const Color(AppConstants.primaryColorValue),
    AppConstants.stateAttendLate: Colors.orange,
    AppConstants.stateLeaveEarly: const Color(AppConstants.errorColor),
  };

  // 출결 상태별 텍스트
  final Map<int, String> _stateTexts = {
    AppConstants.stateAttendIn: '등원',
    AppConstants.stateAttendClass: '수업출석',
    AppConstants.stateLeaveOut: '하원',
    AppConstants.stateAttendLate: '지각',
    AppConstants.stateLeaveEarly: '조퇴',
  };

  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _initializeCamera();

    // 전체화면 모드로 설정
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 가로 화면 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _audioPlayer.dispose();

    // 시스템 UI와 화면 회전 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = '카메라를 찾을 수 없습니다.';
          _statusColor = Colors.red;
        });
        return;
      }

      // 전면 카메라 우선 선택
      int cameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.front) {
          cameraIndex = i;
          break;
        }
      }
      _currentCameraIndex = cameraIndex;

      _cameraController = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = '얼굴을 인식합니다.';
          _statusColor = Colors.black;
        });

        // 자동 인식 시작
        _startAutoRecognition();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '카메라 초기화에 실패했습니다.';
        _statusColor = Colors.red;
      });
    }
  }

  void _startAutoRecognition() {
    if (!mounted || _isProcessing) return;

    _recognitionCounter = 0;
    _startRecognitionLoop();
  }

  void _startRecognitionLoop() async {
    if (!mounted || _isProcessing || !_isInitialized) return;

    setState(() {
      _isRecognizing = true;
    });

    while (_recognitionCounter < _maxRecognitionAttempts &&
           !_isProcessing && mounted) {
      await _captureAndRecognize();
      _recognitionCounter++;

      if (!_isProcessing && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (_recognitionCounter >= _maxRecognitionAttempts && !_isProcessing) {
      _onRecognitionFailed();
    }
  }

  Future<void> _captureAndRecognize() async {
    if (!_isInitialized || _isProcessing || _cameraController == null) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 가온 얼굴인식 API 호출
      final result = await GaonFaceService.recognizeFace(imageBytes);

      if (result != null && result.isSuccess && result.faceId != null) {
        await _onRecognitionSuccess(result.faceId!, result.similarity ?? 0, imageBytes);
      }

      // 임시 이미지 파일 삭제
      await imageFile.delete();

    } catch (e) {
      debugPrint('Face recognition error: $e');
    }
  }

  Future<void> _onRecognitionSuccess(String faceId, int similarity, Uint8List imageBytes) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isRecognizing = false;
    });

    try {
      // 학생 정보 찾기
      final provider = context.read<AttendanceProvider>();
      final student = await provider.findStudentByFaceId(faceId);

      if (student != null) {
        // 출결 기록
        final success = await provider.recordAttendance(
          studentId: student.id,
          state: provider.currentAttendanceState,
          isKeypad: false,
          recognizeLog: '$faceId:$similarity',
          thumbnailBytes: imageBytes,
        );

        if (success) {
          setState(() {
            _statusMessage = '${student.name}님이 ${_getStateText(provider.currentAttendanceState)}처리 되었습니다.';
            _statusColor = _stateColors[provider.currentAttendanceState] ?? Colors.green;
          });

          await _playSuccessSound();
          await _showSuccessMessage(student.name, _getStateText(provider.currentAttendanceState));

          // 3초 후 화면 복귀
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          _onRecognitionFailed();
        }
      } else {
        setState(() {
          _statusMessage = '일치하는 ID가 없습니다.';
          _statusColor = Colors.red;
        });
        await _playFailSound();

        // 2초 후 다시 인식 시도
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            _startAutoRecognition();
          }
        });
      }
    } catch (e) {
      _onRecognitionFailed();
    }
  }

  void _onRecognitionFailed() {
    setState(() {
      _isRecognizing = false;
      _isProcessing = false;
      _statusMessage = '얼굴인식실패';
      _statusColor = Colors.red;
    });

    _playFailSound();

    // 3초 후 다시 시도하거나 화면을 나감
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '얼굴을 인식합니다.';
          _statusColor = Colors.black;
        });
        _startAutoRecognition();
      }
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/ok.wav'));
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  Future<void> _playFailSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/no.wav'));
    } catch (e) {
      debugPrint('Error playing fail sound: $e');
    }
  }

  Future<void> _showSuccessMessage(String studentName, String stateText) async {
    // 성공 메시지 표시 로직
    // 여기서는 간단히 상태 메시지만 업데이트
  }

  String _getStateText(int state) {
    return _stateTexts[state] ?? '출결';
  }

  void _switchCamera() {
    if (_cameras.length <= 1) return;

    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    });

    _initializeCamera();
  }

  void _manualCapture() {
    if (_isRecognizing || _isProcessing) return;

    _recognitionCounter = 0;
    _captureAndRecognize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // 카메라 프리뷰
              if (_isInitialized && _cameraController != null)
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),

              // 로딩 오버레이
              if (!_isInitialized)
                const Positioned.fill(
                  child: Center(
                    child: LoadingWidget(
                      message: '카메라를 초기화하는 중...',
                    ),
                  ),
                ),

              // 상단 상태바
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildStatusBar(),
              ),

              // 중앙 가이드 프레임
              Positioned.fill(
                child: _buildGuideFrame(),
              ),

              // 하단 컨트롤 영역
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControlArea(provider),
              ),

              // 카메라 전환 버튼
              if (_cameras.length > 1)
                Positioned(
                  top: 60.h,
                  right: 20.w,
                  child: _buildCameraSwitchButton(),
                ),

              // 뒤로가기 버튼
              Positioned(
                top: 60.h,
                left: 20.w,
                child: _buildBackButton(),
              ),

              // 인식 진행 표시
              if (_isRecognizing)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: 0,
                  right: 0,
                  child: _buildRecognitionIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 60.h,
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSans',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideFrame() {
    return Center(
      child: Container(
        width: 280.w,
        height: 350.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isRecognizing
                ? const Color(AppConstants.primaryColorValue)
                : Colors.white.withOpacity(0.5),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Icon(
            Icons.face,
            size: 80.sp,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildControlArea(AttendanceProvider provider) {
    return Container(
      height: 120.h,
      color: Colors.black.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 현재 출결 상태 표시
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '현재 상태',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontFamily: 'NotoSans',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getStateText(provider.currentAttendanceState),
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: _stateColors[provider.currentAttendanceState] ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),

          // 수동 촬영 버튼
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: _isRecognizing || _isProcessing
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: IconButton(
              onPressed: _isRecognizing || _isProcessing ? null : _manualCapture,
              icon: Icon(
                Icons.camera_alt,
                size: 32.sp,
                color: Colors.white,
              ),
            ),
          ),

          // 인식 카운터 표시
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '시도 횟수',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontFamily: 'NotoSans',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$_recognitionCounter/$_maxRecognitionAttempts',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSwitchButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _switchCamera,
      backgroundColor: Colors.black.withOpacity(0.7),
      child: Icon(
        Icons.flip_camera_ios,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }

  Widget _buildBackButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: () => Navigator.of(context).pop(),
      backgroundColor: Colors.black.withOpacity(0.7),
      child: Icon(
        Icons.arrow_back,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }

  Widget _buildRecognitionIndicator() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(AppConstants.primaryColorValue),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '얼굴을 인식하는 중...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }
}