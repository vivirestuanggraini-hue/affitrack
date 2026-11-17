import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }

    return user;
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return credential.user;
  }

  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User Firebase tidak ditemukan.');
    }

    // Ambil data user terbaru dari Firebase
    await user.reload();

    // Ambil kembali user setelah reload
    user = _auth.currentUser;

    if (user == null) {
      throw Exception('Session user sudah tidak tersedia.');
    }

    // Paksa refresh token Firebase
    await user.getIdToken(true);

    // Reload sekali lagi setelah token diperbarui
    await user.reload();

    user = _auth.currentUser;

    return user?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User Firebase tidak ditemukan.');
    }

    await user.reload();

    user = _auth.currentUser;

    if (user == null) {
      throw Exception('Session user tidak ditemukan.');
    }

    if (user.emailVerified) {
      return;
    }

    await user.sendEmailVerification();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}