import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  late AnimationController animationController;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        'Semua field wajib diisi.',
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password minimal 6 karakter.',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        'Konfirmasi password tidak sama.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.register(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VerifyEmailPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal.';

      if (e.code == 'email-already-in-use') {
        message = 'Email tersebut sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah.';
      }

      showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      showMessage(
        'Terjadi kesalahan. Silakan coba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFB83B68) : const Color(0xFF4CAF80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _RegisterBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animationController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animationController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                      ),
                      child: Column(
                        children: [
                          _buildHeader(),

                          const SizedBox(height: 28),

                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius:
                                  BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFD96C9D)
                                          .withOpacity(0.12),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create Your Account',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF38242D),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Mulai kelola affiliate kamu\nsecara lebih teratur dengan AffiTrack.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),

                                const SizedBox(height: 25),

                                _label('Nama Lengkap'),

                                const SizedBox(height: 8),

                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Masukkan nama lengkap',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _label('Email'),

                                const SizedBox(height: 8),

                                TextField(
                                  controller: emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Masukkan email aktif',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _label('Password'),

                                const SizedBox(height: 8),

                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Minimal 6 karakter',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _label('Konfirmasi Password'),

                                const SizedBox(height: 8),

                                TextField(
                                  controller:
                                      confirmPasswordController,
                                  obscureText:
                                      obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Ulangi password',
                                    prefixIcon: const Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscureConfirmPassword =
                                              !obscureConfirmPassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscureConfirmPassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 26),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFD96C9D),
                                      foregroundColor:
                                          Colors.white,
                                      elevation: 0,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children: [
                                                Text(
                                                  'Buat Akun',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Container(
                                  padding:
                                      const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF2F7),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .mark_email_read_outlined,
                                        color: Color(0xFFC95788),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Setelah daftar, kamu wajib melakukan verifikasi email sebelum masuk ke dashboard.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: Colors
                                                .grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun?',
                                      style: TextStyle(
                                        color:
                                            Colors.grey.shade600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Color(0xFFC95788),
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF59414B),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEBA3C2),
                Color(0xFFC95788),
              ],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AffiTrack',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF38242D),
              ),
            ),
            Text(
              'Build • Track • Grow',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9A7182),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegisterBackground extends StatefulWidget {
  const _RegisterBackground();

  @override
  State<_RegisterBackground> createState() =>
      _RegisterBackgroundState();
}

class _RegisterBackgroundState
    extends State<_RegisterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -120 + controller.value * 35,
              right: -100,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5BBD3)
                      .withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100 + controller.value * 30,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE9C1D2)
                      .withOpacity(0.35),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}