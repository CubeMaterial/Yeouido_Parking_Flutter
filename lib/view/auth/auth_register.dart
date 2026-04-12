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
  final TextEditingController emailOrIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String notice = '';
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    emailOrIdController.text = normalizedEmail(widget.prefilledEmail);
    passwordController.text = widget.prefilledPassword;
    confirmPasswordController.text = widget.prefilledPassword;
  }

  @override
  void dispose() {
    emailOrIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  String normalizedEmail(String value) {
    return value.trim().toLowerCase();
  }

  bool isValidEmail(String value) {
    final regex = RegExp(
      r'^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    return regex.hasMatch(value.trim());
  }

  Future<void> signup() async {
    final email = normalizedEmail(emailOrIdController.text);
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty) {
      setState(() {
        notice = '이메일을 입력해 주세요.';
      });
      return;
    }

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

    if (confirmPassword.isEmpty) {
      setState(() {
        notice = '비밀번호 확인을 입력해 주세요.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        notice = '비밀번호가 일치하지 않습니다.';
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
        name: name,
      );
      final session = await AuthApi.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        notice = '${session.userEmail} 회원가입 및 로그인 완료';
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

  void goToLogin() {
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
                  width: 390,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SignupTopIllustration(),
                      const SizedBox(height: 24),
                      const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '계정을 만들고 서비스를 이용해 보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),
                      RoundedInputField(
                        controller: emailOrIdController,
                        hintText: '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      RoundedInputField(
                        controller: passwordController,
                        hintText: '비밀번호',
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      RoundedInputField(
                        controller: confirmPasswordController,
                        hintText: '비밀번호 확인',
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      RoundedInputField(
                        controller: nameController,
                        hintText: '이름',
                      ),
                      if (notice.isNotEmpty) ...[
                        const SizedBox(height: 14),
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withValues(alpha: 0.95),
                                Colors.blue.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: Text(
                              isSubmitting ? '회원가입 중...' : '회원가입',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Divider(
                        color: Colors.grey.withValues(alpha: 0.30),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '이미 계정이 있으신가요?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: goToLogin,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.blue,
                            ),
                            child: const Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
}

class RoundedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const RoundedInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.03),
          width: 1,
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class SignupTopIllustration extends StatelessWidget {
  const SignupTopIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FB),
                shape: BoxShape.circle,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 42,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'P',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 50,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.90),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 10,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
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
