import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/utils/auth/admin_session_store.dart';

import '../../vm/admin_auth_api.dart';
import '../admin_main_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String notice = '';
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String normalizedEmail(String value) {
    return value.trim().toLowerCase();
  }

  bool isValidEmail(String value) {
    final regex = RegExp(r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(value);
  }

  Future<void> login() async {
    final email = normalizedEmail(emailController.text);
    final password = passwordController.text;

    if (!isValidEmail(email)) {
      setState(() {
        notice = '이메일 형식을 확인해 주세요.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        notice = '비밀번호를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      notice = '';
    });

    try {
      final session = await AdminAuthApi.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      await AdminSessionStore.save(
        adminId: session.adminId,
        adminEmail: session.adminEmail,
        adminName: session.adminName,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '${session.adminEmail} 로그인되었습니다.';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminMainPage()),
      );
    } on AdminAuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '요청 처리에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF63C9F2), Color(0xFF75B992)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height - 48,
              ),
              child: Center(
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AdminParkingHeaderArtwork(),
                      const SizedBox(height: 20),
                      const Text(
                        '관리자 로그인',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF304763),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '관리자 계정으로 로그인해 주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _roundedInput(
                        controller: emailController,
                        hintText: '관리자 이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _roundedInput(
                        controller: passwordController,
                        hintText: '비밀번호',
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '관리자 전용 계정만 접근할 수 있습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      if (notice.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            notice,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3387F5), Color(0xFF2678E6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3387F5,
                                ).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              isSubmitting ? '로그인 중...' : '로그인',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundedInput({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: !obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _AdminParkingHeaderArtwork extends StatelessWidget {
  const _AdminParkingHeaderArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 112,
      child: Image.asset(
        'images/Logo.png',
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }
}
