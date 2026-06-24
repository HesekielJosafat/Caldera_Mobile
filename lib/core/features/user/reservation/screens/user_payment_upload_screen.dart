import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:caldera_app/core/services/api_service.dart';
// import 'package:url_launcher/url_launcher.dart'; // (opsional jika tidak dipakai di file ini)
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // (opsional jika tidak dipakai di file ini)
import 'user_reservation_whatsapp_screen.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

// IMPORT NAVBAR DAN HALAMAN TERKAIT
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';

class UserPaymentUploadScreen extends StatefulWidget {
  final String bookingCode;
  final double amount;

  const UserPaymentUploadScreen({Key? key, required this.bookingCode, required this.amount}) : super(key: key);

  @override
  State<UserPaymentUploadScreen> createState() => _UserPaymentUploadScreenState();
}

class _UserPaymentUploadScreenState extends State<UserPaymentUploadScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  String? _selectedBank;
  final TextEditingController _accountNameCtrl = TextEditingController();
  final TextEditingController _trxIdCtrl = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // STATE NOTIFIKASI
  // ==========================================
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());
    _fetchNotifications();
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
          const SnackBar(
            content: Text("Semua notifikasi ditandai dibaca"), 
            backgroundColor: Colors.green, 
            duration: Duration(seconds: 2),
          ),
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
  // POPUP NOTIFIKASI
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
                                              _getNotificationIcon(notif['title']),
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
  // FUNGSI UPLOAD IMAGE
  // ==========================================
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadPayment() async {
    if (_selectedBank == null || _accountNameCtrl.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon lengkapi Bank, Nama, dan Bukti Transfer!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> payload = {
      'bank_from': _selectedBank,
      'account_name': _accountNameCtrl.text,
      'transaction_id': _trxIdCtrl.text,
    };

    final result = await _apiService.uploadTablePayment(widget.bookingCode, payload, _selectedImage!);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bukti transfer berhasil diunggah!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => UserReservationWhatsappScreen(
              waUrl: result['wa_url'] ?? "https://wa.me/6285272997806",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Gagal upload"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
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

      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryNavy))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.credit_card, size: 40, color: Color(0xFFD4AF37)),
                        const SizedBox(height: 12),
                        Text("Upload Bukti Transfer", style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
                        Text("Booking Code: ${widget.bookingCode}", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Divider(height: 40),

                  _buildLabel("Bank Asal Transfer *"),
                  Container(
                    height: 48, padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text("Pilih Bank", style: GoogleFonts.sora(fontSize: 13, color: Colors.grey)),
                        value: _selectedBank,
                        items: ['BCA', 'MANDIRI', 'BRI', 'BNI', 'CIMB', 'Lainnya'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.sora(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _selectedBank = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel("Nama Pemilik Rekening *"),
                  _buildTextField(_accountNameCtrl, "Masukkan nama pengirim"),
                  const SizedBox(height: 16),

                  _buildLabel("ID Transaksi (Opsional)"),
                  _buildTextField(_trxIdCtrl, "Masukkan kode unik jika ada"),
                  const SizedBox(height: 16),

                  _buildLabel("Bukti Transfer *"),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity, height: 120,
                      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                      child: _selectedImage != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text("Klik untuk memilih foto (JPG, PNG)", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: _uploadPayment,
                      icon: const Icon(Icons.upload, color: Colors.white, size: 16),
                      label: Text("Upload & Lanjutkan", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  )
                ],
              ),
            ),
          ),
          
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

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF14334C))));
  Widget _buildTextField(TextEditingController ctrl, String hint) => SizedBox(height: 48, child: TextField(controller: ctrl, style: GoogleFonts.sora(fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 12))));
}