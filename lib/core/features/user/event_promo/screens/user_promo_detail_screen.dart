import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/utils/notification_service.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:intl/intl.dart'; // 👈 Wajib ada untuk format Rupiah (Rp)

import '../../../../widgets/custom_bottom_nav.dart';
import '../../notification/screens/user_notification_screen.dart';
import '../../main_user_screen.dart';

import '../../menu/screens/user_menu_screen.dart';
import '../../reservation/screens/user_reservation_screen.dart';
import '../../pool/screens/user_facility_screen.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

class UserPromoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promo;

  const UserPromoDetailScreen({Key? key, required this.promo}) : super(key: key);

  @override
  State<UserPromoDetailScreen> createState() => _UserPromoDetailScreenState();
}

class _UserPromoDetailScreenState extends State<UserPromoDetailScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  
  Map<String, dynamic> _promoData = {}; 
  bool _isLoading = false;

  StreamSubscription<RemoteMessage>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _promoData = Map.from(widget.promo);

    timeago.setLocaleMessages('id', IdMessages());
    WidgetsBinding.instance.addObserver(this); 

    _fetchNotifications();

    _notifSubscription = NotificationService.onMessageStream.stream.listen((message) {
      _refreshPromoDetail();
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _notifSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPromoDetail();
      _fetchNotifications();
    }
  }

  Future<void> _refreshPromoDetail() async {
    setState(() => _isLoading = true);
    
    try {
      String slug = _promoData['slug'] ?? '';
      if (slug.isEmpty) return;

      final promos = await _apiService.getPromos();
      final updatedPromo = promos.firstWhere((p) => p['slug'] == slug, orElse: () => null);

      if (updatedPromo != null && mounted) {
        setState(() {
          _promoData = updatedPromo;
        });
      }
    } catch (e) {
      print("Gagal refresh detail promo: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _apiService.getUserNotifications();
      final notifications = List<dynamic>.from(data['notifications'] ?? []);
      final unreadCount = notifications.where((n) => n['read_at'] == null).length;
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    
    Navigator.of(context).pop();
    
    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read';
      }
    });
    
    await _apiService.markAllNotificationsAsRead();
    await _fetchNotifications();
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

  IconData _getNotificationIcon(String? title) {
    if (title == null) return Icons.notifications;
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('tiket') || lowerTitle.contains('kolam')) {
      return Icons.confirmation_num;
    } else if (lowerTitle.contains('reservasi') || lowerTitle.contains('meja')) {
      return Icons.event_available;
    }
    return Icons.notifications;
  }

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
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.notifications_active, size: 16, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 8),
                                  Text("Notifikasi",
                                      style: GoogleFonts.sora(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ]),
                                if (_unreadCount > 0)
                                  GestureDetector(
                                    onTap: _markAllAsRead,
                                    child: Text("Tandai semua dibaca",
                                        style: GoogleFonts.sora(
                                            fontSize: 10,
                                            color: const Color(0xFF14334C),
                                            fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          Flexible(
                            child: _notifications.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 30),
                                    child: Column(children: [
                                      Icon(Icons.notifications_off_outlined,
                                          size: 32, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text("Belum ada notifikasi",
                                          style: GoogleFonts.sora(
                                              color: Colors.grey.shade600, fontSize: 11)),
                                    ]),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _notifications.length > 4 ? 4 : _notifications.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1, color: Colors.black12),
                                    itemBuilder: (context, index) {
                                      final notif = _notifications[index];
                                      bool isUnread = notif['read_at'] == null;
                                      return Container(
                                        color: isUnread
                                            ? Colors.blue.shade50.withOpacity(0.3)
                                            : Colors.white,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                const Color(0xFF14334C).withOpacity(0.1),
                                            child: Icon(
                                                _getNotificationIcon(notif['title']),
                                                color: const Color(0xFF14334C),
                                                size: 18),
                                          ),
                                          title: Row(children: [
                                            Expanded(
                                              child: Text(notif['title'] ?? '',
                                                  style: GoogleFonts.sora(
                                                      fontSize: 12,
                                                      fontWeight: isUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.normal)),
                                            ),
                                            if (isUnread)
                                              const Icon(Icons.circle,
                                                  size: 8, color: Colors.red),
                                          ]),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(notif['body'] ?? '',
                                                  style: GoogleFonts.sora(
                                                      fontSize: 10, color: Colors.black87),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 6),
                                              Text(_formatTime(notif['created_at']),
                                                  style: GoogleFonts.sora(
                                                      fontSize: 9, color: Colors.grey)),
                                            ],
                                          ),
                                          trailing: isUnread
                                              ? IconButton(
                                                  icon: const Icon(
                                                      Icons.check_circle_outline,
                                                      color: Colors.green,
                                                      size: 20),
                                                  onPressed: () async {
                                                    setState(() => _unreadCount =
                                                        _unreadCount > 0
                                                            ? _unreadCount - 1
                                                            : 0);
                                                    dialogSetState(() => notif['read_at'] =
                                                        DateTime.now().toIso8601String());
                                                    await _apiService
                                                        .markNotificationAsRead(
                                                            notif['id'].toString());
                                                  },
                                                )
                                              : null,
                                          onTap: () async {
                                            if (isUnread) {
                                              setState(() => _unreadCount =
                                                  _unreadCount > 0 ? _unreadCount - 1 : 0);
                                              dialogSetState(() => notif['read_at'] =
                                                  DateTime.now().toIso8601String());
                                              await _apiService.markNotificationAsRead(
                                                  notif['id'].toString());
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const UserNotificationScreen()),
                              ).then((_) => _fetchNotifications());
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
                                    fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final promo = _promoData;

    // Format diskon
    String discountText;
    if (promo['discount_value'] != null) {
      final val = promo['discount_value'].toString();
      final clean = val.endsWith('.00') ? val.replaceAll('.00', '') : val;
      if (promo['discount_type'] == 'percentage') {
        discountText = "Diskon $clean%";
      } else {
        discountText = "Diskon Rp ${clean.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
      }
    } else {
      discountText = "Special Price";
    }

    String promoType = (promo['promo_type'] ?? 'Promo').toString().toLowerCase();

    // 👇 LOGIKA SYARAT & KETENTUAN DINAMIS DARI DATABASE 👇
    List<String> termsList = [];
    
    // 1. Cek Minimal Pembelian
    if (promo['min_purchase'] != null && double.tryParse(promo['min_purchase'].toString()) != null && double.parse(promo['min_purchase'].toString()) > 0) {
      termsList.add("Minimal transaksi ${formatCurrency.format(double.parse(promo['min_purchase'].toString()))}");
    } else {
      termsList.add("Tanpa minimal transaksi");
    }

    // 2. Cek Maksimal Diskon (Hanya untuk diskon persentase)
    if (promo['discount_type'] == 'percentage' && promo['max_discount'] != null && double.tryParse(promo['max_discount'].toString()) != null && double.parse(promo['max_discount'].toString()) > 0) {
      termsList.add("Maksimal potongan diskon ${formatCurrency.format(double.parse(promo['max_discount'].toString()))}");
    }

    // 3. Cek Kuota (Maksimal Penggunaan)
    if (promo['max_usage'] != null && int.tryParse(promo['max_usage'].toString()) != null && int.parse(promo['max_usage'].toString()) > 0) {
      termsList.add("Kuota terbatas untuk ${promo['max_usage']} penggunaan pertama");
    }

    // Tambahan aturan default
    termsList.add("Promo tidak dapat digabung dengan penawaran lain");
    // 👆 SAMPAI SINI 👆

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disetel false karena kita pakai custom back button di bawah
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
            children: const [
              TextSpan(text: 'Caldera ', style: TextStyle(color: activeGold)),
              TextSpan(text: 'Resto & Pool', style: TextStyle(color: Colors.white)),
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
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryNavy))
        : RefreshIndicator(
            color: activeGold,
            onRefresh: _refreshPromoDetail, 
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), 
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BADGE TIPE (Kotak Merah Menu/Ticket)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                        child: Text(promoType.toUpperCase(),
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),

                      // 2. JUDUL
                      Text(promo['title'] ?? '',
                          style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),

                      // 3. DISKON
                      Text(discountText,
                          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                      const SizedBox(height: 16),

                      // 4. DESKRIPSI
                      Text(promo['description'] ?? '',
                          style: GoogleFonts.sora(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
                      const SizedBox(height: 24),

                      // 5. KODE PROMO & TANGGAL (Dibagi menjadi 2 Kolom seperti di Web)
                      if (promo['promo_code'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Promo Code:", style: GoogleFonts.sora(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(promo['promo_code'], style: GoogleFonts.sora(color: Colors.cyan.shade800, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              // Tombol Copy 
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.cyan),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode berhasil disalin!'), duration: Duration(seconds: 1)));
                                },
                              )
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 6. SYARAT & KETENTUAN (DINAMIS DARI DATABASE)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kolom Kiri: Periode Promo
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text("Periode Promo", style: GoogleFonts.sora(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(promo['start_date']?.toString().split('T')[0] ?? '-', style: GoogleFonts.sora(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text("s/d", style: GoogleFonts.sora(color: Colors.black54, fontSize: 11)),
                                  Text(promo['end_date']?.toString().split('T')[0] ?? '-', style: GoogleFonts.sora(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Kolom Kanan: Syarat & Ketentuan Dinamis
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.assignment, size: 14, color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text("Syarat & Ketentuan", style: GoogleFonts.sora(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...termsList.map((term) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("• ", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12)),
                                        Expanded(child: Text(term, style: GoogleFonts.sora(color: Colors.grey.shade700, fontSize: 10, height: 1.4))),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 7. STATUS PROMO (JIKA SUDAH TIDAK AKTIF)
                      if (promo['is_active'] == false || promo['is_active'] == 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "⚠️ Promo ini sudah tidak aktif atau telah kadaluarsa.",
                            style: GoogleFonts.sora(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // TOMBOL KEMBALI
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Kembali", style: GoogleFonts.sora(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

      // BOTTOM NAV BAR
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, 
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainUserScreen(initialIndex: index)),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}