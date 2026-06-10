import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/notification_service.dart';

// PACKAGE TIMEAGO 
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

// WIDGETS
import '../../widgets/custom_bottom_nav.dart';
import '../../services/api_service.dart';

// HALAMAN BAWAH (BOTTOM NAV)
import 'home/screens/user_home_screen.dart';
import 'pool/screens/user_facility_screen.dart';
import 'reservation/screens/user_reservation_screen.dart';
import 'menu/screens/user_menu_screen.dart';
import 'profile/screens/user_profile_screen.dart';
import '../auth/screens/otp_verification_screen.dart';

import '../auth/screens/login_screen.dart';
import 'notification/screens/user_notification_screen.dart';

class MainUserScreen extends StatefulWidget {
  final int initialIndex;
  const MainUserScreen({super.key, this.initialIndex = 0});

  @override
  State<MainUserScreen> createState() => _MainUserScreenState();
}

class _MainUserScreenState extends State<MainUserScreen> {
  final ApiService _apiService = ApiService();

  int _selectedIndex = 0;
  String _userName = "User";
  String _userEmail = "user@caldera.com";

  // STATE NOTIFIKASI
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  bool _isLoadingNotif = false;

  @override
  void initState() {
    super.initState();
    
    _selectedIndex = widget.initialIndex;
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());

    _loadUserData();
    _fetchNotifications();

    NotificationService.initialize();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr != null) {
      final userData = jsonDecode(userStr);

      if (userData['email_verified_at'] == null) {
        if (mounted) {
          // Tampilkan pesan error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun Anda belum diverifikasi. Silakan verifikasi OTP.'),
              backgroundColor: Colors.red,
            ),
          );
          
          // Lempar kembali ke halaman OTP
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: userData['email'] ?? ''),
            ),
          );
        }
        return; // Hentikan proses agar halaman Home tidak dirender
      }
      // --- 👆 SELESAI PERBAIKAN 👆 ---

      if (mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? 'user@caldera.com';
        });
      }
    } else {
      // Jika tidak ada data user sama sekali, lempar ke halaman Login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _fetchNotifications() async {
    final data = await _apiService.getUserNotifications();

    final notifications =
        List<dynamic>.from(data['notifications'] ?? []);

    final unreadCount = notifications
        .where((n) => n['read_at'] == null)
        .length;

    if (mounted) {
      setState(() {
        _unreadCount = unreadCount;
        _notifications = notifications;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    // 1. LANGSUNG TUTUP POPUP SEKETIKA SAAT DIKLIK
    Navigator.of(context).pop();

    // 2. HILANGKAN TITIK MERAH DI UI SEMENTARA (Optimistic Update)
    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read'; // Beri nilai sembarang agar tidak null
      }
    });

    // 3. PANGGIL API DI BACKGROUND
    bool success = await _apiService.markAllNotificationsAsRead();

    if (success) {
      // 4. Jika sukses, ambil data terbaru dari server secara diam-diam
      await _fetchNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua notifikasi ditandai dibaca"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // 5. Jika gagal/error internet, kembalikan titik merah dengan fetch ulang
      await _fetchNotifications();
    }
  }

  // FUNGSI FORMAT WAKTU
  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '-';
    }

    try {
      String formattedString = createdAt.replaceAll(' ', 'T');

      if (!formattedString.endsWith('Z')) {
        formattedString = formattedString + 'Z';
      }

      final dateTime = DateTime.parse(formattedString).toLocal();

      return timeago.format(
        dateTime,
        locale: 'id',
      );
    } catch (e) {
      print("Error parse: $e");
      return createdAt;
    }
  }

  // --- FUNGSI IKON NOTIFIKASI DINAMIS ---
  IconData _getNotificationIcon(String? title) {
    if (title == null) return Icons.notifications;
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('tiket') || lowerTitle.contains('kolam')) {
      return Icons.confirmation_num; // Ikon Tiket
    } else if (lowerTitle.contains('reservasi') || lowerTitle.contains('meja')) {
      return Icons.event_available; // Ikon Kalender
    }
    return Icons.notifications; // Ikon Default
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const UserHomeScreen();

      case 1:
        return const UserPoolScreen();

      case 2:
        return const UserReservationScreen();

      case 3:
        return const UserMenuScreen();

      case 4:
        return const UserProfileScreen();

      default:
        return const UserHomeScreen();
    }
  }

  void _changePage(int index) {
    setState(() => _selectedIndex = index);
  }

  // ==========================================
  // POPUP NOTIFIKASI
  // ==========================================
  void _showNotificationPopup() async {
     await _fetchNotifications();
     if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        // 👇 TAMBAHAN STATEFUL BUILDER DI SINI 👇
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  top: kToolbarHeight +
                      MediaQuery.of(context).padding.top +
                      5,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 320,
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      size: 16,
                                      color: Color(0xFFD4AF37),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Notifikasi",
                                      style: GoogleFonts.sora(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_unreadCount > 0)
                                  GestureDetector(
                                    onTap: _markAllAsRead,
                                    child: Text(
                                      "Tandai semua dibaca",
                                      style: GoogleFonts.sora(
                                        fontSize: 10,
                                        color: const Color(0xFF14334C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            color: Colors.black12,
                          ),
                          Flexible(
                            child: _notifications.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 30,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.notifications_off_outlined,
                                          size: 32,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Belum ada notifikasi",
                                          style: GoogleFonts.sora(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _notifications.length > 4
                                        ? 4
                                        : _notifications.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(
                                      height: 1,
                                      color: Colors.black12,
                                    ),
                                    itemBuilder: (context, index) {
                                      final notif = _notifications[index];
                                      bool isUnread = notif['read_at'] == null;

                                      return Container(
                                        color: isUnread
                                            ? Colors.blue.shade50.withOpacity(0.3)
                                            : Colors.white,
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                const Color(0xFF14334C)
                                                    .withOpacity(0.1),
                                            child: Icon(
                                              _getNotificationIcon(notif['title']),
                                              color: const Color(0xFF14334C),
                                              size: 18,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif['title'] ?? '',
                                                  style: GoogleFonts.sora(
                                                    fontSize: 12,
                                                    fontWeight: isUnread
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                const Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: Colors.red,
                                                ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                notif['body'] ?? '',
                                                style: GoogleFonts.sora(
                                                  fontSize: 10,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatTime(notif['created_at']),
                                                style: GoogleFonts.sora(
                                                  fontSize: 9,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // 👇 KODE TOMBOL CENTANG DENGAN DIALOG SETSTATE 👇
                                          trailing: isUnread 
                                            ? IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                                tooltip: 'Tandai dibaca',
                                                onPressed: () async {
                                                  // 1. Update Layar Utama (Angka Lonceng Atas)
                                                  setState(() {
                                                    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
                                                  });
                                                  // 2. Update Isi Popup Instan (Titik merah hilang, dsb)
                                                  dialogSetState(() {
                                                    notif['read_at'] = DateTime.now().toIso8601String();
                                                  });
                                                  // 3. Panggil API Background
                                                  await _apiService.markNotificationAsRead(notif['id'].toString());
                                                },
                                              ) 
                                            : null,
                                          // 👇 JIKA KOTAK NOTIF DIKLIK 👇
                                          onTap: () async {
                                            if (isUnread) {
                                              setState(() {
                                                _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
                                              });
                                              dialogSetState(() {
                                                notif['read_at'] = DateTime.now().toIso8601String();
                                              });
                                              await _apiService.markNotificationAsRead(notif['id'].toString());
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const Divider(
                            height: 1,
                            color: Colors.black12,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const UserNotificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                "Lihat semua notifikasi →",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ); // Penutup StatefulBuilder
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryNavy,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'Caldera ',
                style: TextStyle(color: activeGold),
              ),
              const TextSpan(
                text: 'Resto & Pool',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showNotificationPopup,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _changePage,
      ),
    );
  }
}