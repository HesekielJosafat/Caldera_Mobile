import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';
import 'user_ticket_detail_screen.dart';
import 'package:caldera_app/core/utils/notification_service.dart';

class UserMyTicketsScreen extends StatefulWidget {
  const UserMyTicketsScreen({Key? key}) : super(key: key);

  @override
  State<UserMyTicketsScreen> createState() => _UserMyTicketsScreenState();
}

class _UserMyTicketsScreenState extends State<UserMyTicketsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _tickets = [];

  // STATE NOTIFIKASI
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  StreamSubscription<RemoteMessage>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());
    _fetchNotifications();
    _fetchMyTickets();

    _notifSubscription = NotificationService.onMessageStream.stream.listen((message) {
      print("Ada notifikasi masuk di foreground! Auto-refresh data tiket...");
      _fetchMyTickets();     // <--- Mengambil ulang data tiket terbaru secara otomatis!
      _fetchNotifications(); // <--- Mengambil ulang jumlah lonceng merah otomatis!
    });
  }

  // ==========================================
  // FUNGSI NOTIFIKASI
  // ==========================================
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
  void _showNotificationPopup() async { 
    await _fetchNotifications(); 

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          // TOMBOL CENTANG DENGAN DIALOG SETSTATE DI HALAMAN TIKET
                                          trailing: isUnread 
                                            ? IconButton(
                                                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                                tooltip: 'Tandai dibaca',
                                                onPressed: () async {
                                                  // 1. Update Layar Belakang (Angka Lonceng Atas)
                                                  setState(() {
                                                    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
                                                  });
                                                  // 2. Update Isi Popup Instan Seketika (Real-Time)
                                                  dialogSetState(() {
                                                    notif['read_at'] = DateTime.now().toIso8601String();
                                                  });
                                                  // 3. Panggil API Background
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

  // ==========================================
  // FUNGSI TIKET (DENGAN REFRESH & URUTAN FIX)
  // ==========================================
  Future<void> _fetchMyTickets() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getTickets();
    if (mounted) {
      setState(() {
        _tickets = List<dynamic>.from(data); 
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '-';
    String str = dateString.toString();
    if (str.contains('T')) {
      return str.split('T')[0];
    }
    return str;
  }

  @override
  void dispose() {
    _notifSubscription?.cancel(); // Membatalan langganan agar tidak boros baterai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);
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
            onPressed: _showNotificationPopup, 
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

      // ==========================================
      // BODY (MY TICKETS) DENGAN PULL-TO-REFRESH
      // ==========================================
      body: RefreshIndicator(
        color: primaryNavy,
        onRefresh: () async {
          await _fetchMyTickets();
          await _fetchNotifications();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryNavy))
            : _tickets.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Memaksa agar tetap bisa ditarik
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: Text("Belum ada riwayat tiket.", style: GoogleFonts.sora(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      
                      // Ambil status dari database API
                      String status = (ticket['status'] ?? 'active').toString().toLowerCase();
                      String paymentStatus = (ticket['payment_status'] ?? 'unpaid').toString().toLowerCase();
                      
                      String ticketType = (ticket['ticket_type_label'] ?? ticket['ticket_type'] ?? 'Adult').toString();
                      int qty = int.tryParse(ticket['number_of_tickets']?.toString() ?? '1') ?? 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 1. 👇 BUNGKUS KOLOM KIRI DENGAN EXPANDED AGAR MENGALAH JIKA LAYAR SEMPIT 👇
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("TICKET CODE", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.qr_code, size: 14, color: Color(0xFFD4AF37)),
                                        const SizedBox(width: 6),
                                        // 2. 👇 BUNGKUS TEKS KODE DENGAN EXPANDED AGAR JIKA TERLALU PANJANG AKAN JADI '...' 👇
                                        Expanded(
                                          child: Text(
                                            ticket['ticket_code'] ?? '-', 
                                            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy),
                                            overflow: TextOverflow.ellipsis, // Mencegah teks jebol ke kanan
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12), // Beri sedikit jarak pemisah antara kiri dan kanan
                              
                              // Kolom kanan untuk lencana status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildStatusBadge(status),
                                  const SizedBox(height: 6),
                                  _buildPaymentStatusBadge(paymentStatus),
                                ],
                              ),
                            ],
                          ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("VISIT DATE", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _formatDate(ticket['visit_date']), 
                                              style: GoogleFonts.sora(fontSize: 12, color: Colors.black87),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("TYPE & QTY", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Icon(Icons.local_activity, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text("$ticketType ($qty)", style: GoogleFonts.sora(fontSize: 12, color: Colors.black87)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("TOTAL AMOUNT", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatCurrency.format(double.tryParse(ticket['total_amount']?.toString() ?? '0')), 
                                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryNavy), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  onPressed: () async {
                                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => UserTicketDetailScreen(ticket: ticket)));
                                    if (result == true) _fetchMyTickets(); // Refresh
                                  },
                                  icon: const Icon(Icons.visibility, size: 14, color: primaryNavy),
                                  label: Text("Details", style: GoogleFonts.sora(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 11)),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),

      // ==========================================
      // BOTTOM NAVBAR
      // ==========================================
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 1, // Menggunakan index 1 yang merujuk pada histori / tiket
        onItemTapped: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainUserScreen(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }

  // WIDGET HELPER 1: Status Tiket (Aktif/Digunakan/Batal)
  Widget _buildStatusBadge(String status) {
    Color badgeColor = Colors.orange;
    String label = "PENDING";

    if (status == 'active' || status == 'aktif') {
      badgeColor = Colors.green;
      label = "AKTIF";
    } else if (status == 'used' || status == 'digunakan') {
      badgeColor = Colors.blue;
      label = "DIGUNAKAN";
    } else if (status == 'expired' || status == 'cancelled' || status == 'batal') {
      badgeColor = Colors.red;
      label = "BATAL";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Diubah ke 8
      decoration: BoxDecoration(color: badgeColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)), // Diubah ke 9
    );
  }

  // WIDGET HELPER 2: Status Pembayaran (Belum Bayar/Menunggu Verifikasi/Lunas)
  Widget _buildPaymentStatusBadge(String status) {
    Color badgeColor = Colors.red;
    String label = "BELUM BAYAR";

    if (status == 'paid' || status == 'lunas') {
      badgeColor = Colors.green;
      label = "LUNAS";
    } else if (status == 'payment_verified' || status == 'menunggu verifikasi') {
      badgeColor = Colors.blue;
      label = "MENUNGGU VERIFIKASI";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Diubah ke 8
      decoration: BoxDecoration(color: badgeColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)), // Diubah ke 9
    );
  }
}