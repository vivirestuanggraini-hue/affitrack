import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  bool checking = false;
  bool sending = false;
  bool loggingOut = false;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // CEK VERIFIKASI EMAIL
  // ============================================================

  Future<void> checkVerification() async {
    if (checking) return;

    setState(() {
      checking = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan.');
      }

      // Ambil status terbaru dari Firebase
      await user.reload();

      user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Session user tidak ditemukan.');
      }

      // ========================================================
      // EMAIL SUDAH TERVERIFIKASI
      // ========================================================

      if (user.emailVerified) {
        if (!mounted) return;

        setState(() {
          checking = false;
        });

        // Tampilkan popup
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                28,
                30,
                28,
                28,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ICON BERHASIL
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE58CB2),
                          Color(0xFFC95788),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD96C9D)
                              .withOpacity(0.28),
                          blurRadius: 25,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Selamat! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF38242D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Akun Anda Berhasil Diverifikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC95788),
                    ),
                  ),

                  const SizedBox(height: 13),

                  Text(
                    'Email Anda sudah berhasil diverifikasi. '
                    'Silakan login menggunakan akun yang baru saja '
                    'Anda daftarkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL LANJUT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD76599),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Text(
                        'Lanjut ke Login',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // ========================================================
        // SETELAH POPUP DITUTUP → LOGOUT → LOGIN
        // ========================================================

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // EMAIL BELUM TERVERIFIKASI
      // ========================================================

      if (!mounted) return;

      showMessage(
        'Email belum terverifikasi.\n\n'
        'Silakan buka Gmail dan klik link verifikasi '
        'yang dikirim oleh Firebase.',
        isError: true,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showMessage(
        'Firebase Error\n\n${e.message ?? e.code}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal mengecek verifikasi akun.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          checking = false;
        });
      }
    }
  }

  // ============================================================
  // KIRIM ULANG EMAIL
  // ============================================================

  Future<void> resendEmail() async {
    if (sending) return;

    setState(() {
      sending = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User tidak ditemukan.');
      }

      await user.reload();

      user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Session user tidak ditemukan.');
      }

      if (user.emailVerified) {
        if (!mounted) return;

        showMessage(
          'Email kamu sudah terverifikasi.',
        );

        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;

      showMessage(
        'Email verifikasi berhasil dikirim ulang.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'too-many-requests') {
        message =
            'Terlalu banyak permintaan.\nSilakan tunggu beberapa saat.';
      } else if (e.code == 'network-request-failed') {
        message =
            'Tidak ada koneksi internet.\nPeriksa koneksi kamu.';
      } else {
        message =
            'Gagal mengirim email.\n${e.message ?? e.code}';
      }

      showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal mengirim email verifikasi.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  // ============================================================
  // GUNAKAN AKUN LAIN
  // ============================================================

  Future<void> useAnotherAccount() async {
    if (loggingOut) return;

    setState(() {
      loggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loggingOut = false;
      });

      showMessage(
        'Gagal keluar dari akun.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFB83B68)
            : const Color(0xFF4CAF80),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Email tidak ditemukan';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFDE6F0),
              Color(0xFFF8D5E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // ICON ANIMASI
                    // ==================================================

                    AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        final scale =
                            1 + animationController.value * 0.07;

                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 110,
                        height: 110,
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
                                  .withOpacity(0.28),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
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
                      child: Column(
                        children: [
                          const Text(
                            'Verify Your Email ✨',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF38242D),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Kami perlu memverifikasi email kamu '
                            'sebelum kamu dapat menggunakan AffiTrack.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // EMAIL
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F7),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFF3C5D7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFD96C9D),
                                  ),
                                  child: const Icon(
                                    Icons.email_rounded,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF59414B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==================================================
                          // LANGKAH VERIFIKASI
                          // ==================================================

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                buildStep(
                                  '1',
                                  'Buka Gmail atau email kamu',
                                ),
                                buildStep(
                                  '2',
                                  'Cari email verifikasi dari Firebase',
                                ),
                                buildStep(
                                  '3',
                                  'Klik link verifikasi',
                                ),
                                buildStep(
                                  '4',
                                  'Kembali ke AffiTrack',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // SAYA SUDAH VERIFIKASI
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  checking ? null : checkVerification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFD76599),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: const Color(0xFFD76599)
                                    .withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              child: checking
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                        ),
                                        SizedBox(width: 9),
                                        Text(
                                          'Saya Sudah Verifikasi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ==================================================
                          // KIRIM ULANG EMAIL
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed:
                                  sending ? null : resendEmail,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFFC95788),
                                side: const BorderSide(
                                  color: Color(0xFFE58EB2),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              child: sending
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color: Color(0xFFC95788),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Kirim Ulang Email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ==================================================
                          // GUNAKAN AKUN LAIN
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: TextButton(
                              onPressed: loggingOut
                                  ? null
                                  : useAnotherAccount,
                              child: loggingOut
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        color: Color(0xFFC95788),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Gunakan akun lain',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF96677D),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'AffiTrack • Secure Account Verification',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP
  // ============================================================

  Widget buildStep(
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD76599),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF59414B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}