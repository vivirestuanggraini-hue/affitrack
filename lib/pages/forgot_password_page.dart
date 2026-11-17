import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();

  final TextEditingController emailController =
      TextEditingController();

  late AnimationController animationController;

  bool loading = false;
  bool success = false;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    emailController.dispose();

    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(
        'Masukkan email terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await authService.resetPassword(email);

      if (!mounted) return;

      setState(() {
        success = true;
      });
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mengirim reset password.';

      if (e.code == 'user-not-found') {
        message = 'Email belum terdaftar.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }

      showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      showMessage(
        'Terjadi kesalahan. Coba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFCE5EF),
              Color(0xFFF8D7E6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: animationController,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.94,
                    end: 1,
                  ).animate(
                    CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD96C9D)
                                .withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: success
                          ? _successView()
                          : _formView(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      children: [
        _icon(
          Icons.lock_reset_rounded,
        ),

        const SizedBox(height: 25),

        const Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF38242D),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Masukkan email akun AffiTrack kamu.\nKami akan mengirimkan link untuk membuat password baru.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email kamu',
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
            ),
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed:
                loading ? null : resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD96C9D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Kirim Link Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Kembali ke Login',
            style: TextStyle(
              color: Color(0xFFC95788),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      children: [
        _icon(
          Icons.mark_email_read_rounded,
        ),

        const SizedBox(height: 25),

        const Text(
          'Email Terkirim ✨',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Color(0xFF38242D),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Link untuk reset password sudah dikirim ke:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          emailController.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC95788),
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 25),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F7),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Text(
            'Silakan cek inbox atau folder spam email kamu, lalu ikuti link untuk membuat password baru.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD96C9D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'Kembali ke Login',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _icon(IconData icon) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEBA3C2),
            Color(0xFFC95788),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96C9D)
                .withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}