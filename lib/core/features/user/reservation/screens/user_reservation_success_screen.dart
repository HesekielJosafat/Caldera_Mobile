import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

import 'package:caldera_app/core/services/api_service.dart'; // Import API Service
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';
import 'user_payment_upload_screen.dart';
import 'user_my_reservations_screen.dart';

class UserReservationSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> reservationData;

  const UserReservationSuccessScreen({Key? key, required this.reservationData}) : super(key: key);

  @override
  State<UserReservationSuccessScreen> createState() => _UserReservationSuccessScreenState();
}

class _UserReservationSuccessScreenState extends State<UserReservationSuccessScreen> {
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
        // STATEFULBUILDER UNTUK POPUP REAL-TIME DI HALAMAN SUKSES RESERVASI
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
                                          // TOMBOL CENTANG DENGAN DIALOG SETSTATE DI HALAMAN SUKSES RESERVASI
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

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    // KARENA INI STATEFUL WIDGET, AMBIL DATA DARI "widget."
    final String bookingCode = widget.reservationData['booking_code'] ?? 'RES-XXXXXX';
    final String name = widget.reservationData['customer_name'] ?? '-';
    final String date = widget.reservationData['reservation_date'] ?? '-';
    final String time = widget.reservationData['reservation_time'] ?? '-';
    final String guests = widget.reservationData['number_of_guests']?.toString() ?? '0';
    final double dpAmount = double.tryParse(widget.reservationData['down_payment']?.toString() ?? '50000') ?? 50000.0;
    
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
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
            onPressed: _showNotificationPopup, // MEMANGGIL FUNGSI POPUP NOTIFIKASI DI SINI
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // KARTU UTAMA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  ),
                  const SizedBox(height: 20),
                  Text("Reservasi Berhasil!", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                  const SizedBox(height: 8),
                  Text("Terima kasih telah melakukan reservasi di Caldera Resto & Pool.", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // KODE BOOKING
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text("Kode Booking Anda", style: GoogleFonts.sora(fontSize: 10, color: Colors.blue.shade800)),
                        const SizedBox(height: 4),
                        Text(bookingCode, style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DETAIL RESERVASI
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Detail Reservasi:", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14, color: primaryNavy)),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow("Nama", name),
                  _buildDetailRow("Tanggal", date),
                  _buildDetailRow("Jam", time),
                  _buildDetailRow("Jumlah Tamu", "$guests Orang"),
                  const Divider(height: 24),
                  _buildDetailRow("DP Harus Dibayar", formatCurrency.format(dpAmount), isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // INFO PEMBAYARAN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: Colors.orange.shade400, width: 4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                      const SizedBox(width: 8),
                      Text("Informasi Pembayaran", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Silakan lakukan pembayaran DP sebesar ${formatCurrency.format(dpAmount)} ke rekening berikut:", style: GoogleFonts.sora(fontSize: 11, color: Colors.orange.shade900)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.black12)),
                  Text("Bank BCA: 1234567890 a.n. Caldera Resto\nBank Mandiri: 0987654321 a.n. Caldera Resto", style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // TOMBOL UPLOAD BUKTI
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UserPaymentUploadScreen(bookingCode: bookingCode, amount: dpAmount)));
                },
                icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                label: Text("Upload Bukti Pembayaran", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserMyReservationsScreen()),
                );
              },
              child: Text("Lihat Reservasi Saya", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
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

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: GoogleFonts.sora(fontSize: 12, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: isHighlight ? const Color(0xFF14334C) : Colors.black87))),
        ],
      ),
    );
  }
}