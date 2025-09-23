import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'NotoSans',
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앱 설정 섹션
            _buildSettingsSection(
              context,
              '앱 설정',
              [
                _buildSettingItem(
                  context,
                  '서버 URL 설정',
                  '백엔드 서버 주소 설정',
                  Icons.dns,
                  () => _showServerSettingsDialog(context),
                ),
                _buildSettingItem(
                  context,
                  '출결 모드 설정',
                  '기본 출결 등록 방식 설정',
                  Icons.settings_applications,
                  () => _showAttendanceModeDialog(context),
                ),
                _buildSettingItem(
                  context,
                  '알림 설정',
                  '출결 관련 알림 설정',
                  Icons.notifications,
                  () => _showNotificationSettingsDialog(context),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 데이터 관리 섹션
            _buildSettingsSection(
              context,
              '데이터 관리',
              [
                _buildSettingItem(
                  context,
                  '출결 데이터 내보내기',
                  '엑셀 파일로 출결 데이터 다운로드',
                  Icons.file_download,
                  () => _showExportDialog(context),
                ),
                _buildSettingItem(
                  context,
                  '캐시 삭제',
                  '앱 캐시 데이터 삭제',
                  Icons.cleaning_services,
                  () => _showCacheClearDialog(context),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 정보 섹션
            _buildSettingsSection(
              context,
              '정보',
              [
                _buildSettingItem(
                  context,
                  '앱 정보',
                  '버전 정보 및 개발자 정보',
                  Icons.info,
                  () => _showAppInfoDialog(context),
                ),
                _buildSettingItem(
                  context,
                  '도움말',
                  '앱 사용법 및 문의',
                  Icons.help,
                  () => _showHelpDialog(context),
                ),
                _buildSettingItem(
                  context,
                  '개인정보처리방침',
                  '개인정보 처리에 대한 정책',
                  Icons.privacy_tip,
                  () => _showPrivacyPolicyDialog(context),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // 로그아웃 버튼
            _buildLogoutButton(context),

            SizedBox(height: 32.h),

            // 앱 버전 정보
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.textPrimaryColor),
            fontFamily: 'NotoSans',
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: const Color(AppConstants.primaryColorValue),
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(AppConstants.textSecondaryColor),
          fontFamily: 'NotoSans',
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: const Color(AppConstants.textSecondaryColor),
        size: 20.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: Icon(Icons.logout, size: 20.sp),
        label: Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.errorColor),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(AppConstants.textSecondaryColor),
              fontFamily: 'NotoSans',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'v${AppConstants.appVersion}',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(AppConstants.textSecondaryColor),
              fontFamily: 'NotoSans',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '© 2024 가온 교육. All rights reserved.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[400],
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  // 다이얼로그 메서드들
  void _showServerSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: AppConstants.baseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서버 URL 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '백엔드 서버의 URL을 입력하세요.',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '서버 URL',
                hintText: 'http://localhost:8080',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 서버 URL 저장 로직 구현
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('서버 URL이 저장되었습니다.')),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출결 모드 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('얼굴인식 모드'),
              subtitle: const Text('기본적으로 얼굴인식으로 출결 등록'),
              leading: const Icon(Icons.face_retouching_natural),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('얼굴인식 모드로 설정되었습니다.')),
                );
              },
            ),
            ListTile(
              title: const Text('키패드 모드'),
              subtitle: const Text('기본적으로 키패드 입력으로 출결 등록'),
              leading: const Icon(Icons.dialpad),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('키패드 모드로 설정되었습니다.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('출결 완료 알림'),
              subtitle: const Text('출결이 성공적으로 등록되었을 때 알림'),
              value: true,
              onChanged: (value) {
                // TODO: 알림 설정 저장
              },
            ),
            SwitchListTile(
              title: const Text('오류 알림'),
              subtitle: const Text('출결 등록 중 오류 발생 시 알림'),
              value: true,
              onChanged: (value) {
                // TODO: 알림 설정 저장
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출결 데이터 내보내기'),
        content: const Text('출결 데이터를 엑셀 파일로 내보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 데이터 내보내기 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('데이터 내보내기 기능은 추후 구현 예정입니다.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }

  void _showCacheClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('앱의 캐시 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 캐시 삭제 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('캐시가 삭제되었습니다.')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('앱 이름', AppConstants.appName),
            _buildInfoRow('버전', AppConstants.appVersion),
            _buildInfoRow('패키지명', AppConstants.packageName),
            SizedBox(height: 16.h),
            Text(
              '가온 교육의 출결 관리 시스템입니다.\n얼굴인식과 키패드 입력을 통해 간편하고 정확한 출결 관리를 제공합니다.',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱 사용법',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 8.h),
            const Text('1. 학생 목록에서 학생을 선택하거나'),
            const Text('2. 얼굴인식 또는 키패드로 출결 등록'),
            const Text('3. 출결 이력에서 기록 확인'),
            SizedBox(height: 16.h),
            Text(
              '문의사항',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans',
              ),
            ),
            SizedBox(height: 8.h),
            const Text('이메일: support@gaonedu.co.kr'),
            const Text('전화: 02-0000-0000'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보처리방침'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인정보 수집 및 이용',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSans',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '본 앱은 출결 관리를 위해 다음 정보를 수집합니다:\n'
                '- 학생 정보 (이름, 학번, 소속)\n'
                '- 출결 기록 (시간, 방법)\n'
                '- 얼굴인식 데이터 (선택적)',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(AppConstants.textSecondaryColor),
                  fontFamily: 'NotoSans',
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '개인정보 보호',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSans',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '수집된 개인정보는 출결 관리 목적으로만 사용되며, '
                '안전하게 보호됩니다.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(AppConstants.textSecondaryColor),
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await context.read<AuthService>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('로그아웃 중 오류가 발생했습니다: $e'),
                      backgroundColor: const Color(AppConstants.errorColor),
                    ),
                  );
                }
              }
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSans',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(AppConstants.textSecondaryColor),
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}