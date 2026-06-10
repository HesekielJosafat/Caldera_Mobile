import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationScreen> createState() =>
      _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();

    // Bahasa Indonesia untuk timeago
    timeago.setLocaleMessages('id', IdMessages());

    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getUserNotifications();

      if (mounted) {
        setState(() {
          _notifications = data['notifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '-';
    }

    try {
      // 1. Ubah spasi menjadi huruf 'T' (Format standar ISO 8601)
      String formattedString = createdAt.replaceAll(' ', 'T');

      // 2. Tambahkan 'Z' di akhir string jika belum ada.
      // Huruf 'Z' memaksa Flutter mengenali waktu ini sebagai UTC (+0).
      if (!formattedString.endsWith('Z')) {
        formattedString = formattedString + 'Z';
      }

      // 3. Parse tanggalnya, lalu gunakan .toLocal() 
      // agar otomatis disesuaikan dengan jam lokal HP (WIB/WITA/WIT)
      final dateTime = DateTime.parse(formattedString).toLocal();

      return timeago.format(
        dateTime,
        locale: 'id', // Pastikan tetap bahasa Indonesia
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

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Notifikasi Saya",
          style: GoogleFonts.sora(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryNavy,
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    "Belum ada notifikasi.",
                    style: GoogleFonts.sora(
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];

                      final bool isUnread =
                          notif['read_at'] == null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(16),

                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37)
                                  .withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotificationIcon(notif['title']),
                              color: const Color(0xFFD4AF37),
                              size: 20,
                            ),
                          ),

                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'] ?? '',
                                  style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryNavy,
                                  ),
                                ),
                              ),

                              if (isUnread)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "NEW",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              Text(
                                notif['body'] ?? '',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                _formatTime(
                                  notif['created_at'],
                                ),
                                style: GoogleFonts.sora(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),

                          onTap: () async {
                            // Nanti jika sudah ada API markAsRead:
                            //
                            // await _apiService.markNotificationAsRead(
                            //   notif['id'],
                            // );
                            //
                            // _fetchNotifications();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}