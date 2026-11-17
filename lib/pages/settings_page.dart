import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _nameController =
      TextEditingController();

  bool _notificationsEnabled = true;
  bool _calendarReminder = true;
  bool _targetReminder = true;
  bool _emailNotification = false;
  bool _darkMode = false;

  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>>
      get _settingsReference {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final snapshot =
          await _settingsReference.get();

      final data = snapshot.data();

      _nameController.text =
          data?['name']?.toString() ??
          user.displayName ??
          '';

      _notificationsEnabled =
          data?['notificationsEnabled'] ?? true;

      _calendarReminder =
          data?['calendarReminder'] ?? true;

      _targetReminder =
          data?['targetReminder'] ?? true;

      _emailNotification =
          data?['emailNotification'] ?? false;

      _darkMode =
          data?['darkMode'] ?? false;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat pengaturan: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
    });

    try {
      final name =
          _nameController.text.trim();

      await _settingsReference.set({
        'name': name,
        'notificationsEnabled':
            _notificationsEnabled,
        'calendarReminder':
            _calendarReminder,
        'targetReminder':
            _targetReminder,
        'emailNotification':
            _emailNotification,
        'darkMode': _darkMode,
        'updatedAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final user = _auth.currentUser;

      if (user != null &&
          name.isNotEmpty &&
          name != user.displayName) {
        await user.updateDisplayName(name);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengaturan berhasil disimpan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan pengaturan: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final controller =
        TextEditingController();

    bool obscure = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              title: const Text(
                'Ubah Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  hintText:
                      'Minimal 6 karakter',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        obscure = !obscure;
                      });
                    },
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final password =
                        controller.text.trim();

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password minimal 6 karakter.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final user =
                          _auth.currentUser;

                      if (user == null) {
                        throw Exception(
                          'User belum login.',
                        );
                      }

                      await user.updatePassword(
                        password,
                      );

                      if (!mounted) return;

                      Navigator.pop(
                        dialogContext,
                      );

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password berhasil diubah.',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ??
                                'Gagal mengubah password.',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF4F9A),
                    foregroundColor:
                        Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) return;

    if (user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email kamu sudah terverifikasi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    try {
      await user.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email verifikasi berhasil dikirim.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim email verifikasi: $e',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Kamu akan keluar dari akun AffiTrack.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF4F9A),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFFDF7FA),
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF242424),
        elevation: 0,
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE8F2),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color:
                          Color(0xFFE91E63),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pengaturan',
                      style: TextStyle(
                        color:
                            Color(0xFFE91E63),
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 1050,
            ),
            child: Column(
              children: [
                _buildProfileHero(user),
                const SizedBox(height: 20),
                _buildAccountOverview(user),
                const SizedBox(height: 20),
                _buildProfileSection(user),
                const SizedBox(height: 20),
                _buildNotificationSection(),
                const SizedBox(height: 20),
                _buildAppearanceSection(),
                const SizedBox(height: 20),
                _buildSecuritySection(user),
                const SizedBox(height: 20),
                _buildAboutSection(),
                const SizedBox(height: 20),
                _buildLogoutSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(User? user) {
    final name =
        _nameController.text.trim().isEmpty
            ? 'Pengguna AffiTrack'
            : _nameController.text.trim();

    final verified =
        user?.emailVerified ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF3F91),
            Color(0xFFFF72B1),
            Color(0xFFFFA0CA),
          ],
        ),
        borderRadius:
            BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4F9A)
                .withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white
                    .withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Saya',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.85),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ??
                      'Email tidak tersedia',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.18),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons
                                .info_outline_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        verified
                            ? 'Email Terverifikasi'
                            : 'Email Belum Terverifikasi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOverview(User? user) {
    return Row(
      children: [
        Expanded(
          child: _overviewCard(
            icon: Icons.verified_user_rounded,
            title: 'Status Akun',
            value: user?.emailVerified == true
                ? 'Terverifikasi'
                : 'Belum',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _overviewCard(
            icon: Icons.notifications_active_rounded,
            title: 'Notifikasi',
            value: _notificationsEnabled
                ? 'Aktif'
                : 'Nonaktif',
            color:
                const Color(0xFFE91E63),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _overviewCard(
            icon: Icons.palette_rounded,
            title: 'Tampilan',
            value: _darkMode
                ? 'Gelap'
                : 'Terang',
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(User? user) {
    return _section(
      icon: Icons.person_outline_rounded,
      title: 'Informasi Profil',
      subtitle:
          'Kelola informasi dasar akun kamu.',
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(
              label: 'Nama',
              icon:
                  Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller:
                TextEditingController(
              text: user?.email ?? '',
            ),
            decoration: _inputDecoration(
              label: 'Email',
              icon:
                  Icons.email_outlined,
            ).copyWith(
              suffixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _section(
      icon: Icons.notifications_none_rounded,
      title: 'Notifikasi',
      subtitle:
          'Atur informasi apa saja yang ingin kamu terima.',
      child: Column(
        children: [
          _settingTile(
            icon:
                Icons.notifications_active_rounded,
            title: 'Notifikasi Aplikasi',
            subtitle:
                'Terima pemberitahuan aktivitas AffiTrack.',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          _settingTile(
            icon:
                Icons.calendar_today_rounded,
            title: 'Pengingat Kalender',
            subtitle:
                'Ingatkan saya tentang agenda yang akan datang.',
            value: _calendarReminder,
            onChanged: (value) {
              setState(() {
                _calendarReminder = value;
              });
            },
          ),
          const Divider(height: 1),
          _settingTile(
            icon: Icons.flag_rounded,
            title: 'Pengingat Target',
            subtitle:
                'Berikan pengingat ketika target belum tercapai.',
            value: _targetReminder,
            onChanged: (value) {
              setState(() {
                _targetReminder = value;
              });
            },
          ),
          const Divider(height: 1),
          _settingTile(
            icon: Icons.email_outlined,
            title: 'Notifikasi Email',
            subtitle:
                'Terima informasi penting melalui email.',
            value: _emailNotification,
            onChanged: (value) {
              setState(() {
                _emailNotification = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _section(
      icon: Icons.palette_outlined,
      title: 'Tampilan',
      subtitle:
          'Atur pengalaman visual aplikasi.',
      child: Column(
        children: [
          _settingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Mode Gelap',
            subtitle:
                'Simpan preferensi mode tampilan.',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF3F8),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color:
                      Color(0xFFE91E63),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tema AffiTrack menggunakan warna pink sebagai identitas utama aplikasi.',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(User? user) {
    final verified =
        user?.emailVerified ?? false;

    return _section(
      icon: Icons.shield_outlined,
      title: 'Keamanan Akun',
      subtitle:
          'Jaga keamanan dan akses akun AffiTrack.',
      child: Column(
        children: [
          _actionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            subtitle:
                'Perbarui password akun kamu.',
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          _actionTile(
            icon: verified
                ? Icons.verified_rounded
                : Icons.mark_email_unread_outlined,
            title: verified
                ? 'Email Terverifikasi'
                : 'Verifikasi Email',
            subtitle: verified
                ? 'Email akun sudah terverifikasi.'
                : 'Kirim ulang email verifikasi.',
            color: verified
                ? Colors.green
                : const Color(0xFFE91E63),
            onTap: verified
                ? null
                : _sendVerificationEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _section(
      icon: Icons.info_outline_rounded,
      title: 'Tentang AffiTrack',
      subtitle:
          'Informasi aplikasi.',
      child: Column(
        children: [
          _infoRow(
            'Versi Aplikasi',
            '1.0.0',
          ),
          _infoRow(
            'Platform',
            'Flutter + Firebase',
          ),
          _infoRow(
            'Fungsi',
            'Affiliate Management',
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keluar dari sesi AffiTrack di perangkat ini.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            _saving ? null : _saveSettings,
        icon: const Icon(
          Icons.save_rounded,
        ),
        label: Text(
          _saving
              ? 'Menyimpan Pengaturan...'
              : 'Simpan Semua Pengaturan',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFFF4F9A),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor:
              const Color(0xFFFF4F9A)
                  .withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE7F1),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF1F6),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFFE91E63),
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor:
                const Color(0xFFFF4F9A),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color color =
        const Color(0xFFE91E63),
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding:
            const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          const Color(0xFFFFFBFD),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFFF4F9A),
          width: 1.5,
        ),
      ),
    );
  }
}