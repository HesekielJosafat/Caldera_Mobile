import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

import 'package:caldera_app/core/services/api_service.dart'; // Import API Service
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';

class UserReservationWhatsappScreen extends StatefulWidget {
  final String waUrl;

  const UserReservationWhatsappScreen({Key? key, required this.waUrl}) : super(key: key);

  @override
  State<UserReservationWhatsappScreen> createState() => _UserReservationWhatsappScreenState();
}

class _UserReservationWhatsappScreenState extends State<UserReservationWhatsappScreen> {
  final ApiService _apiService = ApiService();

  // STATE NOTIFIKASI
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());
    _fetchNotifications();
  }

  // FUNGSI MENGAMBIL NOTIFIKASI
  Future<void> _fetchNotifications() async {
    try {
      final data = await _apiService.getUserNotifications();
      final notifications = List<dynamic>.from(data['notifications'] ?? []);
      final unreadCount = notifications.where((n) => n['read_at'] == null).length;

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
          _notifications = notifications;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil notifikasi: $e");
    }
  }

  // FUNGSI TANDAI SEMUA DIBACA
  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    Navigator.of(context).pop(); // Tutup popup

    // Optimistic Update (UI langsung merespons)
    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read';
      }
    });

    bool success = await _apiService.markAllNotificationsAsRead();
    if (success) {
      await _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua notifikasi ditandai dibaca"), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }
    } else {
      await _fetchNotifications();
    }
  }

  // FUNGSI FORMAT WAKTU
  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '-';
    try {
      String formattedString = createdAt.replaceAll(' ', 'T');
      if (!formattedString.endsWith('Z')) {
        formattedString = formattedString + 'Z';
      }
      final dateTime = DateTime.parse(formattedString).toLocal();
      return timeago.format(dateTime, locale: 'id');
    } catch (e) {
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

  // ==========================================
  // POPUP NOTIFIKASI (FIXED REAL-TIME STATE SYNC)
  // ==========================================
  void _showNotificationPopup() async { // 1. Diubah menjadi async
    
    // Tampilkan loading kecil jika diperlukan, atau langsung tunggu datanya siap
    await _fetchNotifications(); // 2. Ditambahkan await agar data list stabil sebelum popup terbuka

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        // STATEFULBUILDER UNTUK POPUP REAL-TIME DI HALAMAN WHATSAPP RESERVASI
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
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 5,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 320,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
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
                                    const Icon(Icons.notifications_active, size: 16, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 8),
                                    Text("Notifikasi", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  ],
                                ),
                                if (_unreadCount > 0)
                                  GestureDetector(
                                    onTap: _markAllAsRead,
                                    child: Text("Tandai semua dibaca", style: GoogleFonts.sora(fontSize: 10, color: const Color(0xFF14334C), fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          Flexible(
                            child: _notifications.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 30),
                                    child: Column(
                                      children: [
                                        Icon(Icons.notifications_off_outlined, size: 32, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text("Belum ada notifikasi", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 11)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _notifications.length > 4 ? 4 : _notifications.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                    itemBuilder: (context, index) {
                                      final notif = _notifications[index];
                                      bool isUnread = notif['read_at'] == null;

                                      return Container(
                                        color: isUnread ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFF14334C).withOpacity(0.1),
                                            child: Icon(
                                              _getNotificationIcon(notif['title']), // MENGGUNAKAN IKON DINAMIS
                                              color: const Color(0xFF14334C),
                                              size: 18,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(notif['title'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                                              ),
                                              if (isUnread) const Icon(Icons.circle, size: 8, color: Colors.red),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(notif['body'] ?? '', style: GoogleFonts.sora(fontSize: 10, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 6),
                                              Text(_formatTime(notif['created_at']), style: GoogleFonts.sora(fontSize: 9, color: Colors.grey)),
                                            ],
                                          ),
                                          // TOMBOL CENTANG DENGAN DIALOG SETSTATE DI HALAMAN WHATSAPP RESERVASI
                                          trailing: isUnread 
                                            ? IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                                tooltip: 'Tandai dibaca',
                                                onPressed: () async {
                                                  setState(() {
                                                    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
                                                  });
                                                  dialogSetState(() {
                                                    notif['read_at'] = DateTime.now().toIso8601String();
                                                  });
                                                  await _apiService.markNotificationAsRead(notif['id'].toString());
                                                },
                                              ) 
                                            : null,
                                          // JIKA NOTIFIKASI DI-TAP / DIKLIK
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
                          const Divider(height: 1, color: Colors.black12),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserNotificationScreen()));
                            },
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(12),
                              child: Text("Lihat semua notifikasi →", textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 11, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
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
        );
      },
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse(widget.waUrl); // Menggunakan widget.waUrl karena sekarang StatefulWidget
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // ==========================================
      // APP HEADER DENGAN POPUP NOTIFIKASI
      // ==========================================
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: primaryNavy,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Caldera ', style: TextStyle(color: activeGold)),
              const TextSpan(text: 'Resto & Pool', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showNotificationPopup, // MEMANGGIL FUNGSI POPUP NOTIFIKASI
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // BODY UTAMA SCREEN WHATSAPP
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon Centang Hijau Besar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 60),
                ),
                const SizedBox(height: 20),
                
                Text("Bukti Terupload!", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF14334C))),
                const SizedBox(height: 8),
                Text("Silakan kirim konfirmasi ke WhatsApp Caldera", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 24),

                // Kotak Peringatan Hijau
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "Pesan otomatis sudah disiapkan. Klik tombol di bawah untuk mengirim ke WhatsApp Caldera.",
                    style: GoogleFonts.sora(fontSize: 11, color: Colors.green.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Kirim WhatsApp
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _launchWhatsApp(context),
                    icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
                    label: Text("Kirim ke WhatsApp Caldera", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Ke Dashboard
                SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      // Kembali ke halaman awal
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home, color: Colors.grey),
                    label: Text("Kembali ke Struk Pembayaran", style: GoogleFonts.sora(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tim Caldera akan segera mengkonfirmasi reservasi Anda setelah menerima pesan ini.",
                        style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),

      // ==========================================
      // BOTTOM NAVBAR
      // ==========================================
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 2, 
        onItemTapped: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainUserScreen(initialIndex: index,)),
            (route) => false,
          );
        },
      ),
    );
  }
}