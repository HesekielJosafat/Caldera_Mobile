import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
 
import '../../../../widgets/custom_bottom_nav.dart';
import '../../notification/screens/user_notification_screen.dart';
import '../../main_user_screen.dart';
 
import '../../menu/screens/user_menu_screen.dart';
import '../../reservation/screens/user_reservation_screen.dart';
import '../../pool/screens/user_facility_screen.dart';
 
class UserPromoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promo;
 
  const UserPromoDetailScreen({Key? key, required this.promo}) : super(key: key);
 
  @override
  State<UserPromoDetailScreen> createState() => _UserPromoDetailScreenState();
}
 
class _UserPromoDetailScreenState extends State<UserPromoDetailScreen> {
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
 
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
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
 
  IconData _getNotificationIcon(String? title) {
    if (title == null) return Icons.notifications;
    final lower = title.toLowerCase();
    if (lower.contains('tiket') || lower.contains('kolam')) return Icons.confirmation_num;
    if (lower.contains('reservasi') || lower.contains('meja')) return Icons.event_available;
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
                          // HEADER POPUP
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
 
                          // ISI NOTIFIKASI
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
 
                          // FOOTER — LIHAT SEMUA
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
 
    final promo = widget.promo;
 
    // Format diskon dengan % atau Rp sesuai discount_type
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
 
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
 
      // APP HEADER
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
 
      // BODY
      body: SingleChildScrollView(
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
                // 1. BADGE TIPE
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
 
                // 5. KODE PROMO
                if (promo['promo_code'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.sora(color: Colors.black87, fontSize: 14),
                        children: [
                          const TextSpan(text: "Promo Code: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: promo['promo_code']),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
 
                // 6. TANGGAL VALID
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.sora(color: Colors.black87, fontSize: 14),
                      children: [
                        const TextSpan(text: "Valid until: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: promo['end_date']?.toString().split('T')[0] ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
 
                // 7. TOMBOL ORDER NOW
                // SizedBox(
                //   width: 150,
                //   height: 45,
                //   child: ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.blue.shade600,
                //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                //     ),
                //     onPressed: () {
                //       if (promoType.contains('menu') || promoType.contains('food')) {
                //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserMenuScreen()));
                //       } else if (promoType.contains('reservation')) {
                //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserReservationScreen()));
                //       } else {
                //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserPoolScreen()));
                //       }
                //     },
                //     child: Text("Order Now",
                //         style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
                //   ),
                // ),
              ],
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