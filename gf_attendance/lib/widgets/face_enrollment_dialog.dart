import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../models/student_vo.dart';
import '../services/gaon_face_service.dart';
import '../services/audio_service.dart';

class FaceEnrollmentDialog extends StatefulWidget {
  final StudentVO student;

  const FaceEnrollmentDialog({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<FaceEnrollmentDialog> createState() => _FaceEnrollmentDialogState();
}

class _FaceEnrollmentDialogState extends State<FaceEnrollmentDialog> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isEnrolling = false;
  String _statusMessage = '카메라를 초기화하는 중...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = '사용 가능한 카메라가 없습니다.';
          _isInitializing = false;
        });
        return;
      }

      // 전면 카메라 우선 선택
      _currentCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0; // 전면 카메라가 없으면 첫 번째 카메라
      }

      await _setupCamera();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() {
        _statusMessage = '카메라 초기화에 실패했습니다.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupCamera() async {
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
        setState(() {
          _isInitializing = false;
          _statusMessage = '얼굴을 카메라 중앙에 맞춰주세요.';
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
      setState(() {
        _statusMessage = '카메라 설정에 실패했습니다.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    setState(() {
      _isInitializing = true;
      _statusMessage = '카메라를 전환하는 중...';
    });

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupCamera();
  }

  Future<void> _captureAndEnroll() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _isEnrolling) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _statusMessage = '얼굴을 촬영하는 중...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // 이미지 처리 (회전, 리사이징)
      final processedBytes = await _processImage(imageBytes);

      setState(() {
        _isCapturing = false;
        _isEnrolling = true;
        _statusMessage = '얼굴을 등록하는 중...';
      });

      // 가온 서버에 얼굴 등록
      final result = await GaonFaceService.enrollFace(
        widget.student.studentId,
        processedBytes,
      );

      if (result != null && result.faces.isNotEmpty) {
        setState(() {
          _statusMessage = '얼굴 등록이 완료되었습니다!';
        });

        await AudioService.speak(
          '${widget.student.studentName}님의 얼굴 등록이 완료되었습니다.'
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pop(true); // 성공 결과 반환
        }
      } else {
        setState(() {
          _statusMessage = '얼굴 등록에 실패했습니다. 다시 시도해주세요.';
          _isEnrolling = false;
        });

        await AudioService.playFail('얼굴 등록에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      debugPrint('Face enrollment error: $e');
      setState(() {
        _statusMessage = '얼굴 등록 중 오류가 발생했습니다.';
        _isCapturing = false;
        _isEnrolling = false;
      });

      await AudioService.playFail('얼굴 등록 중 오류가 발생했습니다.');
    }
  }

  Future<Uint8List> _processImage(Uint8List originalBytes) async {
    try {
      // 이미지 디코딩
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) return originalBytes;

      // 카메라 방향에 따른 회전 처리
      img.Image rotatedImage;
      final camera = _cameras[_currentCameraIndex];

      if (camera.lensDirection == CameraLensDirection.front) {
        // 전면 카메라: 좌우 반전 + 회전
        rotatedImage = img.flipHorizontal(originalImage);
        rotatedImage = img.copyRotate(rotatedImage, angle: 90);
      } else {
        // 후면 카메라: 회전만
        rotatedImage = img.copyRotate(originalImage, angle: 90);
      }

      // 크기 조정 (가온 서버 권장 사이즈)
      final resizedImage = img.copyResize(
        rotatedImage,
        width: 640,
        height: 480,
      );

      // JPEG로 인코딩
      final processedBytes = img.encodeJpg(resizedImage, quality: 85);
      return Uint8List.fromList(processedBytes);
    } catch (e) {
      debugPrint('Image processing error: $e');
      return originalBytes; // 처리 실패 시 원본 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        width: screenSize.width * 0.7,
        height: screenSize.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.face, size: 32, color: Color(0xff215968)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '얼굴 등록',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff215968),
                        ),
                      ),
                      Text(
                        '학생: ${widget.student.studentName} (${widget.student.studentId})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isEnrolling)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // 카메라 프리뷰
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isInitializing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('카메라를 초기화하는 중...'),
                          ],
                        ),
                      )
                    : _cameraController != null &&
                            _cameraController!.value.isInitialized
                        ? Stack(
                            children: [
                              // 카메라 프리뷰
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: _cameraController!.value.aspectRatio,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),

                              // 얼굴 가이드 원형
                              Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isEnrolling
                                          ? Colors.blue
                                          : _isCapturing
                                              ? Colors.orange
                                              : const Color(0xff219189),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),

                              // 카메라 전환 버튼
                              if (_cameras.length > 1)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: FloatingActionButton(
                                    mini: true,
                                    onPressed: _isCapturing || _isEnrolling
                                        ? null
                                        : _switchCamera,
                                    backgroundColor: Colors.white,
                                    child: const Icon(
                                      Icons.flip_camera_ios,
                                      color: Color(0xff215968),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _statusMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),

            // 상태 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEnrolling
                    ? Colors.blue.shade50
                    : _isCapturing
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isEnrolling
                      ? Colors.blue.shade200
                      : _isCapturing
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  if (_isCapturing || _isEnrolling)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade700,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isEnrolling
                            ? Colors.blue.shade700
                            : _isCapturing
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 액션 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 취소 버튼
                if (!_isEnrolling)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCapturing ? null : () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                if (!_isEnrolling) const SizedBox(width: 16),

                // 촬영/등록 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitializing ||
                            _isCapturing ||
                            _isEnrolling ||
                            _cameraController == null ||
                            !_cameraController!.value.isInitialized
                        ? null
                        : _captureAndEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff219189),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                    ),
                    child: Text(
                      _isEnrolling
                          ? '등록 중...'
                          : _isCapturing
                              ? '촬영 중...'
                              : '얼굴 등록',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}