import 'package:flutter/material.dart';

import '../../vm/auth_api.dart';
import 'auth_register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    final regex = RegExp(
      r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
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

    if (password.length < 8) {
      setState(() {
        notice = '비밀번호는 8자 이상 입력해 주세요.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      notice = '';
    });

    try {
      final session = await AuthApi.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '${session.userEmail} 로그인되었습니다.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = error.isNotRegistered ? '' : error.message;
      });

      if (error.isNotRegistered) {
        await showSignupPrompt(email: email, password: password);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '요청 처리에 실패했습니다.';
      });
    }
  }

  void goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupPage(
          prefilledEmail: normalizedEmail(emailController.text),
          prefilledPassword: passwordController.text,
        ),
      ),
    );
  }

  void findAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아이디 찾기 / 비밀번호 찾기')),
    );
  }

  Future<void> showSignupPrompt({
    required String email,
    required String password,
  }) async {
    final shouldSignup = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('존재하지 않는 회원입니다.'),
          content: const Text('회원 가입 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('아니요'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('네'),
            ),
          ],
        );
      },
    );

    if (shouldSignup == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupPage(
            prefilledEmail: email,
            prefilledPassword: password,
          ),
        ),
      );
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
            colors: [
              Color(0xFF63C9F2),
              Color(0xFF75B992),
            ],
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
                      const ParkingHeaderArtwork(),
                      const SizedBox(height: 20),
                      const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF304763),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '서비스를 이용하려면 로그인해 주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _roundedInput(
                        controller: emailController,
                        hintText: '아이디 또는 이메일',
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
                          '비밀번호는 8자 이상 가능합니다.',
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
                              colors: [
                                Color(0xFF3387F5),
                                Color(0xFF2678E6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3387F5).withValues(alpha: 0.25),
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
                      const SizedBox(height: 22),
                      Divider(
                        color: Colors.grey.withValues(alpha: 0.30),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: goToSignup,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF566377),
                                ),
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: findAccount,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF566377),
                                ),
                                child: const Text(
                                  '아이디 찾기 / 비밀번호 찾기',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
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
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class ParkingHeaderArtwork extends StatelessWidget {
  const ParkingHeaderArtwork({super.key});

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
