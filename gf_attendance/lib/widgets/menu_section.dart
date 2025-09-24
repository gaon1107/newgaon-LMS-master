import 'package:flutter/material.dart';
import '../screens/main_attendance_screen.dart';

class MenuSection extends StatelessWidget {
  final AppState currentState;
  final String statusMessage;
  final String keypadInput;
  final bool isProcessing;
  final Function(int) onAttendanceButtonPressed;
  final Function(int) onKeypadButtonPressed;
  final Function(String) onKeypadInput;
  final VoidCallback onStopProcess;
  final VoidCallback onShowStudentManagement;

  const MenuSection({
    Key? key,
    required this.currentState,
    required this.statusMessage,
    required this.keypadInput,
    required this.isProcessing,
    required this.onAttendanceButtonPressed,
    required this.onKeypadButtonPressed,
    required this.onKeypadInput,
    required this.onStopProcess,
    required this.onShowStudentManagement,
  }) : super(key: key);

  // 색상 테마
  static const Color _primaryColor = Color(0xff215968);
  static const Color _accentColor = Color(0xff219189);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff2a6970),
            Color(0xff215968),
          ],
        ),
      ),
      child: Column(
        children: [
          // 상단 상태 영역
          _buildStatusSection(),

          // 출결 버튼 영역
          _buildAttendanceButtons(),

          // 키패드 영역
          Expanded(
            child: _buildKeypadSection(),
          ),

          // 하단 관리 버튼
          _buildManagementSection(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black26,
      ),
      child: Column(
        children: [
          // 로고/제목
          const Text(
            'GF KIDS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const Text(
            '출결관리시스템',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // 상태 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 키패드 입력 표시
          if (keypadInput.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentColor),
              ),
              child: Text(
                '입력: $keypadInput',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '출결 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // 5개 출결 버튼들
          Row(
            children: [
              Expanded(
                child: _buildAttendanceButton(
                  label: '등원',
                  value: 1,
                  color: Colors.green,
                  icon: Icons.login,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceButton(
                  label: '하원',
                  value: 2,
                  color: Colors.blue,
                  icon: Icons.logout,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildAttendanceButton(
                  label: '외출',
                  value: 3,
                  color: Colors.orange,
                  icon: Icons.exit_to_app,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceButton(
                  label: '복귀',
                  value: 4,
                  color: Colors.purple,
                  icon: Icons.keyboard_return,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildAttendanceButton(
            label: '조퇴',
            value: 5,
            color: Colors.red,
            icon: Icons.schedule,
          ),

          // 중지 버튼 (처리 중일 때만 표시)
          if (isProcessing) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onStopProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop),
                  SizedBox(width: 8),
                  Text('중지', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    final isActive = _getActiveState(value);

    return ElevatedButton(
      onPressed: isProcessing && !isActive
          ? null
          : () => onAttendanceButtonPressed(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color.withOpacity(0.8) : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isActive
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  bool _getActiveState(int value) {
    switch (currentState) {
      case AppState.stateRecognizeIn:
        return value == 1;
      case AppState.stateRecognizeOut:
        return value == 2;
      case AppState.stateRecognizeTempout:
        return value == 3;
      case AppState.stateRecognizeReturn:
        return value == 4;
      case AppState.stateRecognizeEarlyout:
        return value == 5;
      default:
        return false;
    }
  }

  Widget _buildKeypadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '키패드 입력',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // 키패드 그리드
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildKeypadButton('1'),
                _buildKeypadButton('2'),
                _buildKeypadButton('3'),
                _buildKeypadButton('4'),
                _buildKeypadButton('5'),
                _buildKeypadButton('6'),
                _buildKeypadButton('7'),
                _buildKeypadButton('8'),
                _buildKeypadButton('9'),
                _buildKeypadButton('C', color: Colors.red, icon: Icons.clear),
                _buildKeypadButton('0'),
                _buildKeypadButton('B', color: Colors.orange, icon: Icons.backspace),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 키패드 확인 버튼들
          Row(
            children: [
              Expanded(
                child: _buildKeypadActionButton(
                  label: '등원',
                  value: 1,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKeypadActionButton(
                  label: '하원',
                  value: 2,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildKeypadActionButton(
                  label: '외출',
                  value: 3,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKeypadActionButton(
                  label: '복귀',
                  value: 4,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildKeypadActionButton(
            label: '조퇴',
            value: 5,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {Color? color, IconData? icon}) {
    return ElevatedButton(
      onPressed: isProcessing ? null : () => onKeypadInput(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white24,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: icon != null
          ? Icon(icon, size: 20)
          : Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildKeypadActionButton({
    required String label,
    required int value,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: keypadInput.isEmpty || isProcessing
          ? null
          : () => onKeypadButtonPressed(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(
          top: BorderSide(color: Colors.white24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : onShowStudentManagement,
              icon: const Icon(Icons.people_outline),
              label: const Text('학생관리'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}