import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        _navigateToMain();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.mediumAnimation,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),

              // 헤더 섹션
              _buildHeader(),

              SizedBox(height: 48.h),

              // 로그인 폼
              _buildLoginForm(),

              SizedBox(height: 32.h),

              // 로그인 버튼
              _buildLoginButton(),

              SizedBox(height: 24.h),

              // 추가 옵션 (필요시)
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 로고
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColorValue),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.school,
            size: 50.sp,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 24.h),

        // 앱 이름
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(AppConstants.primaryColorValue),
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8.h),

        // 설명 텍스트
        Text(
          '안녕하세요. 가온 출결관리 시스템입니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(AppConstants.textSecondaryColor),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 사용자명 입력
          CustomTextField(
            controller: _usernameController,
            labelText: '사용자명',
            hintText: '사용자명을 입력하세요',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '사용자명을 입력해주세요';
              }
              return null;
            },
          ),

          SizedBox(height: 16.h),

          // 비밀번호 입력
          CustomTextField(
            controller: _passwordController,
            labelText: '비밀번호',
            hintText: '비밀번호를 입력하세요',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(AppConstants.textSecondaryColor),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              }
              if (value.length < 4) {
                return '비밀번호는 4자 이상이어야 합니다';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return CustomButton(
      text: '로그인',
      onPressed: _isLoading ? null : _handleLogin,
      isLoading: _isLoading,
      width: double.infinity,
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // 구분선
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                '또는',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(AppConstants.textSecondaryColor),
                    ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 키패드 로그인 버튼 (기존 앱과 동일한 기능)
        OutlinedButton.icon(
          onPressed: () {
            // TODO: 키패드 로그인 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('키패드 로그인 기능은 추후 구현 예정입니다')),
            );
          },
          icon: Icon(
            Icons.dialpad,
            size: 20.sp,
            color: const Color(AppConstants.primaryColorValue),
          ),
          label: Text(
            '키패드로 로그인',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(AppConstants.primaryColorValue),
              fontFamily: 'NotoSans',
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(AppConstants.primaryColorValue),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
          ),
        ),

        SizedBox(height: 32.h),

        // 버전 정보
        Text(
          'v${AppConstants.appVersion}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
              ),
        ),
      ],
    );
  }
}