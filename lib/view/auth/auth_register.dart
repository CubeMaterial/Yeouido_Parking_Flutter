import 'package:flutter/material.dart';

import '../../vm/auth_api.dart';

class SignupPage extends StatefulWidget {
  final String prefilledEmail;
  final String prefilledPassword;

  const SignupPage({
    super.key,
    this.prefilledEmail = '',
    this.prefilledPassword = '',
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String notice = '';
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.prefilledEmail;
    passwordController.text = widget.prefilledPassword;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String normalizedEmail(String value) {
    return value.trim().toLowerCase();
  }

  bool isValidEmail(String value) {
    final regex = RegExp(r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(value);
  }

  Future<void> signup() async {
    final email = normalizedEmail(emailController.text);
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (!isValidEmail(email)) {
      setState(() {
        notice = '이메일 형식을 확인해 주세요.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        notice = '비밀번호는 8자 이상 입력해 주세요.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        notice = '비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        notice = '전화번호를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      notice = '';
    });

    try {
      await AuthApi.signup(
        email: email,
        password: password,
        phone: phone,
        name: name,
      );
      final session = await AuthApi.login(email: email, password: password);

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '${session.userEmail} 회원가입이 완료되었습니다.';
      });
    } on AuthApiException catch (error) {
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

  void backToLogin() {
    Navigator.pop(context);
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
                      const _SignupHeaderArtwork(),
                      const SizedBox(height: 20),
                      const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF304763),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '서비스 이용을 위한 계정을 만들어 주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _roundedInput(
                        controller: emailController,
                        hintText: '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _roundedInput(
                        controller: passwordController,
                        hintText: '비밀번호',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _roundedInput(
                        controller: confirmPasswordController,
                        hintText: '비밀번호 확인',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _roundedInput(controller: nameController, hintText: '이름'),
                      const SizedBox(height: 12),
                      _roundedInput(
                        controller: phoneController,
                        hintText: '전화번호',
                        keyboardType: TextInputType.phone,
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
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3387F5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isSubmitting ? '가입 중...' : '회원가입',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: backToLogin,
                        child: const Text('로그인으로 돌아가기'),
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

class _SignupHeaderArtwork extends StatelessWidget {
  const _SignupHeaderArtwork();

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
