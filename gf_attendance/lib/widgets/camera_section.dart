import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../screens/main_attendance_screen.dart';

class CameraSection extends StatelessWidget {
  final CameraController? cameraController;
  final bool isProcessing;
  final AppState currentState;
  final VoidCallback onSwitchCamera;

  const CameraSection({
    Key? key,
    required this.cameraController,
    required this.isProcessing,
    required this.currentState,
    required this.onSwitchCamera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff1a4a52),
            Color(0xff215968),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 카메라 프리뷰
          if (cameraController != null && cameraController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            )
          else
            _buildCameraPlaceholder(),

          // 얼굴 가이드 원형
          if (currentState != AppState.stateRest) _buildFaceGuide(),

          // 카메라 전환 FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              mini: true,
              onPressed: isProcessing ? null : onSwitchCamera,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.flip_camera_ios,
                color: Color(0xff215968),
              ),
            ),
          ),

          // 상태 표시기
          if (isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 120,
            color: Colors.white54,
          ),
          SizedBox(height: 24),
          Text(
            '카메라를 초기화하는 중...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceGuide() {
    Color guideColor;
    double guideSize = 250;

    switch (currentState) {
      case AppState.stateRecognizeIn:
        guideColor = Colors.green;
        break;
      case AppState.stateRecognizeOut:
        guideColor = Colors.blue;
        break;
      case AppState.stateRecognizeTempout:
        guideColor = Colors.orange;
        break;
      case AppState.stateRecognizeReturn:
        guideColor = Colors.purple;
        break;
      case AppState.stateRecognizeEarlyout:
        guideColor = Colors.red;
        break;
      case AppState.stateRegist:
        guideColor = const Color(0xff219189);
        guideSize = 300;
        break;
      default:
        guideColor = const Color(0xff219189);
    }

    return Center(
      child: Container(
        width: guideSize,
        height: guideSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: guideColor,
            width: isProcessing ? 4 : 3,
          ),
        ),
        child: isProcessing
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: guideColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.face,
                  size: 60,
                  color: guideColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff219189)),
              strokeWidth: 6,
            ),
            SizedBox(height: 24),
            Text(
              '처리 중...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}