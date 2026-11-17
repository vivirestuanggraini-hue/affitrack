import 'dart:ui';
import 'analytics_page.dart';
import 'settings_page.dart';
import 'affiliate_links_page.dart';
import 'notification_page.dart';
import 'calendar_page.dart';
import 'target_page.dart';
import 'commission_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/affiliate_product.dart';
import 'content_page.dart';
import 'login_page.dart';
import 'products_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _floatingController;

  int selectedMenu = 0;

  final List<String> menuItems = [
    'Dashboard',
    'Produk Affiliate',
    'Konten',
    'Link Affiliate',
    'Komisi',
    'Analitik',
    'Target',
    'Kalender',
    'Notifikasi',
    'Pengaturan',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_rounded,
    Icons.shopping_bag_rounded,
    Icons.movie_creation_rounded,
    Icons.link_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.analytics_rounded,
    Icons.flag_rounded,
    Icons.calendar_month_rounded,
    Icons.notifications_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get userName {
    final email = currentUser?.email ?? 'Affiliate Creator';

    if (!email.contains('@')) {
      return 'Affiliate Creator';
    }

    final name = email.split('@').first;

    if (name.isEmpty) {
      return 'Affiliate Creator';
    }

    return name[0].toUpperCase() + name.substring(1);
  }

  Stream<List<AffiliateProduct>> _productsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return AffiliateProduct.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      products.sort((a, b) {
        return a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            );
      });

      return products;
    });
  }

  Stream<int> _contentsCountStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('contents')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void showComingSoon(String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF29222D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFF8FB8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title sedang dipersiapkan ✨',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductsPage(),
      ),
    );
  }

  void openContents({
    bool autoOpenForm = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentPage(
          autoOpenForm: autoOpenForm,
        ),
      ),
    );
  }

  void openCommission() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CommissionPage(),
      ),
    );
  }
  void openAffiliateLinks() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AffiliateLinksPage(),
    ),
  );
}
void openAnalytics() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AnalyticsPage(),
    ),
  );
}
void openTarget() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const TargetPage(),
    ),
  );
}
void openCalendar() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CalendarPage(),
    ),
  );
}
void openNotifications() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NotificationPage(),
    ),
  );
}
void openSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SettingsPage(),
    ),
  );
}
  void handleMenuTap(int index) {
    setState(() {
      selectedMenu = index;
    });

    if (index == 0) {
      return;
    }

    if (index == 1) {
      openProducts();
      return;
    }

    if (index == 2) {
      openContents();
      return;
    }
    if (index == 3) {
    openAffiliateLinks();
    return;
  }

    if (index == 4) {
      openCommission();
      return;
    }
    if (index == 5) {
  openAnalytics();
  return;
}
if (index == 6) {
  openTarget();
  return;
}
if (index == 7) {
  openCalendar();
  return;
}
if (index == 8) {
  openNotifications();
  return;
}
if (index == 9) {
  openSettings();
  return;
}
    showComingSoon(menuItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AffiliateProduct>>(
      stream: _productsStream(),
      builder: (context, productSnapshot) {
        final products = productSnapshot.data ?? [];

        return StreamBuilder<int>(
          stream: _contentsCountStream(),
          builder: (context, contentSnapshot) {
            final contentCount =
                contentSnapshot.data ?? 0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth < 700;

                final isTablet =
                    constraints.maxWidth >= 700 &&
                        constraints.maxWidth < 1050;

                return Scaffold(
                  backgroundColor:
                      const Color(0xFFFFF8FC),
                  drawer:
                      (isMobile || isTablet)
                          ? _buildDrawer()
                          : null,
                  body: Stack(
                    children: [
                      _buildBackground(),
                      SafeArea(
                        child: Row(
                          children: [
                            if (!isMobile && !isTablet)
                              _buildSidebar(),
                            Expanded(
                              child: _buildMainContent(
                                products: products,
                                contentCount:
                                    contentCount,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isLoading:
                                    productSnapshot
                                            .connectionState ==
                                        ConnectionState
                                            .waiting &&
                                    !productSnapshot
                                        .hasData,
                                hasError:
                                    productSnapshot
                                        .hasError,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    _floatingController.value * 20,
                  ),
                  child: child,
                );
              },
              child: _glowCircle(
                260,
                const Color(0xFFFFB6D2)
                    .withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -_floatingController.value * 15,
                  ),
                  child: child,
                );
              },
              child: _glowCircle(
                300,
                const Color(0xFFE9C8FF)
                    .withOpacity(0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 40,
          sigmaY: 40,
        ),
        child: const SizedBox(),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 270,
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFF4DFE9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D4268)
                .withOpacity(0.08),
            blurRadius: 35,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 26),
          _buildLogo(),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              physics:
                  const BouncingScrollPhysics(),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(
                  index,
                  menuItems[index],
                  menuIcons[index],
                );
              },
            ),
          ),
          _buildLogoutButton(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 300,
      backgroundColor:
          const Color(0xFFFFF8FC),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(),
            const SizedBox(height: 25),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                physics:
                    const BouncingScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildDrawerMenuItem(
                    index,
                    menuItems[index],
                    menuIcons[index],
                  );
                },
              ),
            ),
            _buildLogoutButton(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFFF76A8),
                  Color(0xFFE83E7C),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFFE83E7C)
                          .withOpacity(0.25),
                  blurRadius: 15,
                  offset:
                      const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AffiTrack',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF302632),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Affiliate Manager',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF9B8D98),
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    String title,
    IconData icon,
  ) {
    final selected =
        selectedMenu == index;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          onTap: () =>
              handleMenuTap(index),
          borderRadius:
              BorderRadius.circular(16),
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFFF77A9),
                        Color(0xFFE94782),
                      ],
                    )
                  : null,
              borderRadius:
                  BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            const Color(
                          0xFFE94782,
                        ).withOpacity(0.20),
                        blurRadius: 14,
                        offset:
                            const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF8E7D8A,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(
                              0xFF625563,
                            ),
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(
    int index,
    String title,
    IconData icon,
  ) {
    final selected =
        selectedMenu == index;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);

            if (index == 0) {
              setState(() {
                selectedMenu = 0;
              });
              return;
            }

            if (index == 1) {
              setState(() {
                selectedMenu = 1;
              });

              Future.delayed(
                const Duration(
                  milliseconds: 180,
                ),
                openProducts,
              );
              return;
            }

            if (index == 2) {
              setState(() {
                selectedMenu = 2;
              });

              Future.delayed(
                const Duration(
                  milliseconds: 180,
                ),
                openContents,
              );
              return;
            }
            if (index == 3) {
  setState(() {
    selectedMenu = 3;
  });

  Future.delayed(
    const Duration(milliseconds: 180),
    openAffiliateLinks,
  );
  return;
}

            if (index == 4) {
              setState(() {
                selectedMenu = 4;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openCommission,
              );

              return;
            }
            if (index == 5) {
              setState(() {
                selectedMenu = 5;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openAnalytics,
              );

              return;
            }
            if (index == 6) {
              setState(() {
                selectedMenu = 6;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openTarget,
              );

              return;
            }
            if (index == 7) {
              setState(() {
                selectedMenu = 7;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openCalendar,
              );

              return;
            }
            if (index == 8) {
              setState(() {
                selectedMenu = 8;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openNotifications,
              );

              return;
            }
            if (index == 9) {
              setState(() {
                selectedMenu = 9;
              });

              Future.delayed(
                const Duration(milliseconds: 180),
                openSettings,
              );

              return;
            }
            setState(() {
              selectedMenu = index;
            });

            Future.delayed(
              const Duration(
                milliseconds: 180,
              ),
              () => showComingSoon(
                menuItems[index],
              ),
            );
          },
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFFF77A9),
                        Color(0xFFE94782),
                      ],
                    )
                  : null,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF8E7D8A,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(
                              0xFF625563,
                            ),
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: logout,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF0F5),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 21,
                  color: Color(0xFFE45A8A),
                ),
                SizedBox(width: 13),
                Text(
                  'Keluar',
                  style: TextStyle(
                    color:
                        Color(0xFFE45A8A),
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required List<AffiliateProduct> products,
    required int contentCount,
    required bool isMobile,
    required bool isTablet,
    required bool isLoading,
    required bool hasError,
  }) {
    final horizontalPadding =
        isMobile
            ? 14.0
            : isTablet
                ? 20.0
                : 28.0;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final animation =
            CurvedAnimation(
          parent: _pageController,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
              begin:
                  const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),
        padding:
            EdgeInsets.fromLTRB(
          horizontalPadding,
          isMobile ? 12 : 20,
          horizontalPadding,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildTopBar(
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            SizedBox(
              height: isMobile ? 18 : 25,
            ),
            _buildWelcomeCard(
              isMobile,
              products.length,
            ),
            SizedBox(
              height: isMobile ? 16 : 22,
            ),
            _buildStatsGrid(
              isMobile,
              products,
              contentCount,
              isLoading,
            ),
            SizedBox(
              height: isMobile ? 16 : 22,
            ),
            _buildMiddleSection(
              isMobile: isMobile,
              isTablet: isTablet,
              products: products,
            ),
            SizedBox(
              height: isMobile ? 16 : 22,
            ),
            _buildBottomSection(
              isMobile: isMobile,
              isTablet: isTablet,
              products: products,
              hasError: hasError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required bool isMobile,
    required bool isTablet,
  }) {
    return Row(
      children: [
        if (isMobile || isTablet)
          Builder(
            builder: (drawerContext) {
              return Material(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(14),
                  onTap: () {
                    Scaffold.of(
                      drawerContext,
                    ).openDrawer();
                  },
                  child: const SizedBox(
                    width: 45,
                    height: 45,
                    child: Icon(
                      Icons.menu_rounded,
                      color:
                          Color(0xFF403541),
                    ),
                  ),
                ),
              );
            },
          ),
        if (isMobile || isTablet)
          const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize:
                      isMobile ? 23 : 29,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      const Color(0xFF302632),
                ),
              ),
              if (!isMobile)
                const SizedBox(height: 4),
              if (!isMobile)
                const Text(
                  'Kelola perjalanan affiliate kamu dengan lebih mudah.',
                  style: TextStyle(
                    color:
                        Color(0xFF91818D),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        _buildNotificationButton(),
        const SizedBox(width: 8),
        _buildProfileMini(
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          showComingSoon('Notifikasi');
        },
        child: SizedBox(
          width: 45,
          height: 45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons
                    .notifications_none_rounded,
                color:
                    Color(0xFF655565),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFFF5E96),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMini({
    required bool isMobile,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFF2DFE8),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                const Color(0xFFFFD5E4),
            child: Text(
              userName.isNotEmpty
                  ? userName[0].toUpperCase()
                  : 'A',
              style:
                  const TextStyle(
                color:
                    Color(0xFFD83D76),
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 100,
              ),
              child: Text(
                userName,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12,
                  color:
                      Color(0xFF403541),
                ),
              ),
            ),
          ],
          const SizedBox(width: 2),
          const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            size: 18,
            color:
                Color(0xFF8D7E89),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(
    bool isMobile,
    int productCount,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8DB7),
            Color(0xFFE94B84),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          isMobile ? 22 : 28,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFE94B84)
                    .withOpacity(0.24),
            blurRadius: 25,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .wb_sunny_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Selamat datang kembali',
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hai, $userName! 👋',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      isMobile ? 24 : 29,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMobile
                    ? 'Saatnya cek perkembangan affiliate kamu hari ini.'
                    : 'Saatnya cek perkembangan affiliate kamu\nhari ini dan capai target berikutnya.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      isMobile ? 12 : 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _smallInfo(
                    Icons
                        .shopping_bag_rounded,
                    '$productCount',
                    'produk aktif',
                  ),
                  _smallInfo(
                    Icons
                        .local_fire_department_rounded,
                    productCount > 0
                        ? 'Aktif'
                        : 'Mulai',
                    'minggu ini',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
          0.14,
        ),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.85),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    bool isMobile,
    List<AffiliateProduct> products,
    int contentCount,
    bool isLoading,
  ) {
    final totalProducts =
        products.length;

    final totalCommission =
        products.fold<double>(
      0,
      (sum, product) =>
          sum +
          product.estimatedCommission,
    );

    final totalFavorites =
        products
            .where(
              (product) =>
                  product.isFavorite,
            )
            .length;

    final stats = [
      _StatData(
        'Total Produk',
        isLoading
            ? '...'
            : '$totalProducts',
        totalProducts == 0
            ? 'Belum ada produk'
            : '$totalFavorites favorit',
        Icons.shopping_bag_rounded,
        const Color(0xFFFF6FA6),
      ),
      _StatData(
        'Total Konten',
        '$contentCount',
        contentCount == 0
            ? 'Belum ada konten'
            : 'Konten tersimpan',
        Icons.video_library_rounded,
        const Color(0xFF9C7BFF),
      ),
      _StatData(
        'Total Komisi',
        isLoading
            ? '...'
            : _formatCompactRupiah(
                totalCommission,
              ),
        totalCommission > 0
            ? 'Estimasi produk'
            : 'Belum ada komisi',
        Icons
            .account_balance_wallet_rounded,
        const Color(0xFF4EC9A0),
      ),
      _StatData(
        'Klik Link',
        '0',
        'Belum tersedia',
        Icons.ads_click_rounded,
        const Color(0xFFFFA34D),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth < 520) {
          columns = 1;
        } else if (constraints.maxWidth <
            850) {
          columns = 2;
        } else {
          columns = 4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                columns == 1
                    ? 3.0
                    : 1.55,
          ),
          itemBuilder:
              (context, index) {
            return _buildStatCard(
              stats[index],
              index,
            );
          },
        );
      },
    );
  }

  String _formatCompactRupiah(
    double value,
  ) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} Jt';
    }

    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} Rb';
    }

    return 'Rp ${value.toStringAsFixed(0)}';
  }

  Widget _buildStatCard(
    _StatData data,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            450 + (index * 100),
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      curve: Curves.easeOutBack,
      builder:
          (context, value, child) {
        return Transform.translate(
          offset: Offset(
            0,
            18 * (1 - value),
          ),
          child: Opacity(
            opacity:
                value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                const Color(0xFFF3E3EA),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF8C526A)
                      .withOpacity(0.05),
              blurRadius: 18,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                color:
                    data.color
                        .withOpacity(0.11),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    data.title,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF958792),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF342A35),
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.change,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleSection({
    required bool isMobile,
    required bool isTablet,
    required List<AffiliateProduct>
        products,
  }) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          _buildTargetCard(products),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child:
              _buildTargetCard(products),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: _buildQuickActions(),
        ),
      ],
    );
  }

  Widget _buildBottomSection({
    required bool isMobile,
    required bool isTablet,
    required List<AffiliateProduct>
        products,
    required bool hasError,
  }) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          _buildActivityCard(
            products,
            hasError,
          ),
          const SizedBox(height: 16),
          _buildPerformanceCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildActivityCard(
            products,
            hasError,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _buildPerformanceCard(),
        ),
      ],
    );
  }

  Widget _buildTargetCard(
    List<AffiliateProduct> products,
  ) {
    final totalCommission =
        products.fold<double>(
      0,
      (sum, product) =>
          sum +
          product.estimatedCommission,
    );

    const target = 6000000.0;

    final progress =
        (totalCommission / target)
            .clamp(0.0, 1.0);

    final remaining =
        (target - totalCommission)
            .clamp(0.0, target);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8C526A)
                    .withOpacity(0.05),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
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
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFE8F0,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color:
                      Color(0xFFE84983),
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Target Bulanan',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF372D38),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'November 2026',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF9B8B96),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(
                  color:
                      Color(0xFFE84983),
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                TweenAnimationBuilder<
                    double>(
              tween: Tween(
                begin: 0,
                end: progress,
              ),
              duration:
                  const Duration(
                milliseconds: 1200,
              ),
              curve:
                  Curves.easeOutCubic,
              builder:
                  (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 11,
                  backgroundColor:
                      const Color(
                    0xFFFFEAF2,
                  ),
                  valueColor:
                      const AlwaysStoppedAnimation(
                    Color(0xFFE84983),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                _formatCompactRupiah(
                  totalCommission,
                ),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF403541),
                  fontSize: 13,
                ),
              ),
              const Text(
                'dari Rp 6.000.000',
                style:
                    TextStyle(
                  color:
                      Color(0xFF9A8A95),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFF6F9),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .auto_awesome_rounded,
                  color:
                      Color(0xFFE84983),
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    remaining <= 0
                        ? 'Target bulan ini sudah tercapai. Keren! 🎉'
                        : 'Tinggal ${_formatCompactRupiah(remaining)} lagi untuk mencapai target bulan ini.',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF745C68),
                      fontSize: 10,
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

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8C526A)
                    .withOpacity(0.05),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF372D38),
            ),
          ),
          const SizedBox(height: 15),
          _quickAction(
            Icons
                .add_shopping_cart_rounded,
            'Tambah Produk',
            const Color(0xFFE84983),
            openProducts,
          ),
          _quickAction(
            Icons.video_call_rounded,
            'Tambah Konten',
            const Color(0xFF9C7BFF),
            () => openContents(
              autoOpenForm: true,
            ),
          ),
          _quickAction(
            Icons.add_link_rounded,
            'Tambah Link',
            const Color(0xFFFFA34D),
            () => showComingSoon(
              'Tambah Link',
            ),
          ),
          _quickAction(
            Icons
                .flag_circle_rounded,
            'Atur Target',
            const Color(0xFF4EC9A0),
            () => showComingSoon(
              'Atur Target',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Material(
        color:
            color.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      BoxDecoration(
                    color: color
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF504250),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 11,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    List<AffiliateProduct> products,
    bool hasError,
  ) {
    final latestProducts =
        products.reversed
            .take(4)
            .toList();

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8C526A)
                    .withOpacity(0.05),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF372D38),
                  ),
                ),
              ),
              InkWell(
                onTap: openProducts,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                child:
                    const Padding(
                  padding:
                      EdgeInsets.all(5),
                  child: Text(
                    'Lihat produk',
                    style:
                        TextStyle(
                      color:
                          Color(0xFFE84983),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (hasError)
            _activityEmpty(
              Icons
                  .error_outline_rounded,
              'Gagal mengambil data produk',
              'Periksa koneksi atau Firestore.',
              const Color(0xFFE84983),
            )
          else if (latestProducts.isEmpty)
            _activityEmpty(
              Icons
                  .shopping_bag_outlined,
              'Belum ada aktivitas produk',
              'Tambahkan produk affiliate pertama kamu.',
              const Color(0xFF9C7BFF),
            )
          else
            ...latestProducts.map(
              (product) {
                return _activityItem(
                  Icons
                      .shopping_bag_rounded,
                  'Produk affiliate',
                  product.name,
                  'Tersimpan di Firestore',
                  const Color(0xFFE84983),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _activityEmpty(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF7FA),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF4A3D4B),
              fontWeight:
                  FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF9B8D98),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration:
                BoxDecoration(
              color:
                  color.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF4A3D4B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF9B8D98),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              time,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    Color(0xFFB1A4AE),
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final values = [
      0.45,
      0.62,
      0.51,
      0.78,
      0.68,
      0.88,
      0.72,
    ];

    final days = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xFFF3E3EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8C526A)
                    .withOpacity(0.05),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Performa Mingguan',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF372D38),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  showComingSoon(
                    'Analitik',
                  );
                },
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                child:
                    const Padding(
                  padding:
                      EdgeInsets.all(5),
                  child: Icon(
                    Icons
                        .more_horiz_rounded,
                    color:
                        Color(0xFF9C8D98),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Performa klik affiliate',
            style:
                TextStyle(
              color:
                  Color(0xFF9B8D98),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 155,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children:
                  List.generate(
                values.length,
                (index) {
                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment:
                                  Alignment
                                      .bottomCenter,
                              child:
                                  TweenAnimationBuilder<
                                      double>(
                                tween:
                                    Tween(
                                  begin: 0,
                                  end:
                                      values[
                                          index],
                                ),
                                duration:
                                    Duration(
                                  milliseconds:
                                      700 +
                                          (index *
                                              100),
                                ),
                                curve:
                                    Curves
                                        .easeOutCubic,
                                builder: (
                                  context,
                                  value,
                                  child,
                                ) {
                                  return FractionallySizedBox(
                                    heightFactor:
                                        value,
                                    widthFactor:
                                        0.75,
                                    child:
                                        Container(
                                      decoration:
                                          BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                          begin:
                                              Alignment
                                                  .topCenter,
                                          end:
                                              Alignment
                                                  .bottomCenter,
                                          colors: [
                                            Color(
                                              0xFFFF83B0,
                                            ),
                                            Color(
                                              0xFFE84983,
                                            ),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          8,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            days[index],
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF9C8D98,
                              ),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  _StatData(
    this.title,
    this.value,
    this.change,
    this.icon,
    this.color,
  );
}