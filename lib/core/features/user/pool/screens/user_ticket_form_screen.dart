import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';
import 'user_ticket_success_screen.dart';

class UserTicketFormScreen extends StatefulWidget {
  const UserTicketFormScreen({Key? key}) : super(key: key);

  @override
  State<UserTicketFormScreen> createState() => _UserTicketFormScreenState();
}

class _UserTicketFormScreenState extends State<UserTicketFormScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '08');
  final _qtyCtrl = TextEditingController(text: '1');

  DateTime? _selectedDate;
  String _selectedType = 'adult'; // adult, child, family

  final Map<String, int> _prices = {
    'adult': 35000,
    'child': 25000,
    'family': 100000
  };

  // STATE NOTIFIKASI
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());
    _fetchNotifications();

    _loadUserData();
    
    // Otomatis update total harga saat qty diketik
    _qtyCtrl.addListener(() {
      setState(() {}); 
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
  void _showNotificationPopup() async { // 1. Diubah menjadi async
    
    // Tampilkan loading kecil jika diperlukan, atau langsung tunggu datanya siap
    await _fetchNotifications(); // 2. Ditambahkan await agar data list stabil sebelum popup terbuka

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        // STATEFULBUILDER UNTUK POPUP REAL-TIME DI HALAMAN FORM TIKET
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
                                          // TOMBOL CENTANG DENGAN DIALOG SETSTATE DI HALAMAN FORM TIKET
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

  // ==========================================
  // LOGIKA FORM PEMBELIAN TIKET
  // ==========================================
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        _nameCtrl.text = userData['name'] ?? '';
        _emailCtrl.text = userData['email'] ?? '';
        _phoneCtrl.text = userData['phone'] ?? '08';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF14334C))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Tanggal Kunjungan", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> payload = {
      'customer_name': _nameCtrl.text,
      'customer_email': _emailCtrl.text,
      'customer_phone': _phoneCtrl.text,
      'visit_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'ticket_type': _selectedType,
      'number_of_tickets': int.parse(_qtyCtrl.text),
    };

    final result = await _apiService.buyTicket(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        // Pindah ke halaman sukses dan kirim data tiket
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserTicketSuccessScreen(ticketData: result['data'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Gagal memesan tiket"), backgroundColor: Colors.red));
      }
    }
  }

  int get _totalPrice {
    int qty = int.tryParse(_qtyCtrl.text) ?? 0;
    return (_prices[_selectedType] ?? 0) * qty;
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

      // BODY UTAMA (FORM TIKET)
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryNavy))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.local_activity, color: Color(0xFFD4AF37), size: 40),
                          const SizedBox(height: 8),
                          Text("Beli Tiket Kolam Renang", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                          Text("Isi form berikut untuk membeli tiket", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Divider(height: 40),

                    _buildLabel("Nama Lengkap *", Icons.person),
                    _buildTextField(_nameCtrl, "Nama Anda"),
                    const SizedBox(height: 16),

                    _buildLabel("Email *", Icons.email),
                    _buildTextField(_emailCtrl, "Email Anda", type: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    _buildLabel("Nomor Telepon *", Icons.phone),
                    _buildTextField(_phoneCtrl, "0812...", type: TextInputType.phone),
                    const SizedBox(height: 16),

                    _buildLabel("Tanggal Kunjungan *", Icons.calendar_today),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        height: 48, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedDate == null ? "mm/dd/yyyy" : DateFormat('dd/MM/yyyy').format(_selectedDate!), style: GoogleFonts.sora(fontSize: 13, color: _selectedDate == null ? Colors.grey : Colors.black87)),
                            const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel("Tipe *", Icons.confirmation_number),
                          Container(
                            height: 48, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true, value: _selectedType,
                                items: [
                                  DropdownMenuItem(value: 'adult', child: Text("Dewasa - Rp 35.000", style: GoogleFonts.sora(fontSize: 11))),
                                  DropdownMenuItem(value: 'child', child: Text("Anak-anak - Rp 25.000", style: GoogleFonts.sora(fontSize: 11))),
                                  DropdownMenuItem(value: 'family', child: Text("Keluarga (2 Dewasa + 2 Anak) - Rp 100.000", style: GoogleFonts.sora(fontSize: 11))),
                                ],
                                onChanged: (v) => setState(() => _selectedType = v!),
                              ),
                            ),
                          ),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel("Jumlah *", Icons.shopping_cart),
                          _buildTextField(_qtyCtrl, "1", type: TextInputType.number),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // TOTAL HARGA
                    _buildLabel("Total Harga", Icons.payments),
                    Text(formatCurrency.format(_totalPrice), style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryNavy), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                            onPressed: () => Navigator.pop(context), 
                            child: Text("Batal", style: GoogleFonts.sora(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 13))
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                            onPressed: _submitForm, 
                            icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 16), 
                            label: Text("Beli Tiket", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                          )
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
        selectedIndex: 1, 
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

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4AF37)), 
          const SizedBox(width: 6), 
          Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF14334C)))
        ]
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: ctrl, 
        keyboardType: type, 
        style: GoogleFonts.sora(fontSize: 13),
        validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
        decoration: InputDecoration(
          hintText: hint, 
          hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), 
          contentPadding: const EdgeInsets.symmetric(horizontal: 12)
        ),
      ),
    );
  }
}