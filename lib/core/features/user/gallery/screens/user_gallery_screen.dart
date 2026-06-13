import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

// IMPORT API, NAVBAR, DAN HALAMAN TERKAIT
import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:caldera_app/core/utils/notification_service.dart';

class UserGalleryScreen extends StatefulWidget {
  const UserGalleryScreen({Key? key}) : super(key: key);

  @override
  State<UserGalleryScreen> createState() => _UserGalleryScreenState();
}

class _UserGalleryScreenState extends State<UserGalleryScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  List<dynamic> galleryImages = [];
  bool isLoading = true;

  // 👇 PERBAIKAN: Kategori diperbanyak sesuai permintaan 👇
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Pool', 'Restaurant', 'Event', 'Exterior', 'Interior', 'Room'];

  // STATE NOTIFIKASI
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  StreamSubscription<RemoteMessage>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', IdMessages());
    WidgetsBinding.instance.addObserver(this); 
    
    _fetchGallery();
    _fetchNotifications();

    _notifSubscription = NotificationService.onMessageStream.stream.listen((message) {
      _fetchGallery();
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
      _fetchGallery();
      _fetchNotifications();
    }
  }

  Future<void> _fetchGallery() async {
    try {
      final data = await _apiService.getGallery();
      if (mounted) {
        setState(() {
          galleryImages = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
    Navigator.of(context).pop(); 

    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read';
      }
    });

    bool success = await _apiService.markAllNotificationsAsRead();
    if (success) await _fetchNotifications();
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '-';
    try {
      String formattedString = createdAt.replaceAll(' ', 'T');
      if (!formattedString.endsWith('Z')) formattedString = formattedString + 'Z';
      final dateTime = DateTime.parse(formattedString).toLocal();
      return timeago.format(dateTime, locale: 'id');
    } catch (e) {
      return createdAt;
    }
  }

  IconData _getNotificationIcon(String? title) {
    if (title == null) return Icons.notifications;
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('tiket') || lowerTitle.contains('kolam')) return Icons.confirmation_num;
    if (lowerTitle.contains('reservasi') || lowerTitle.contains('meja')) return Icons.event_available;
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
                                                onPressed: () async {
                                                  setState(() { _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0; });
                                                  dialogSetState(() { notif['read_at'] = DateTime.now().toIso8601String(); });
                                                  await _apiService.markNotificationAsRead(notif['id'].toString());
                                                },
                                              ) 
                                            : null,
                                          onTap: () async {
                                            if (isUnread) {
                                              setState(() { _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0; });
                                              dialogSetState(() { notif['read_at'] = DateTime.now().toIso8601String(); });
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
  // LOGIKA LAYOUT (FEATURED VS NORMAL)
  // ==========================================
  List<Widget> _buildGalleryLayout(List<dynamic> items) {
    List<Widget> widgets = [];
    List<dynamic> normalItemsBuffer = [];

    // Fungsi pembantu untuk membuat 2 item berjejer (Row)
    void flushNormalItems() {
      if (normalItemsBuffer.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildGalleryCard(normalItemsBuffer[0], isFeatured: false)),
                const SizedBox(width: 16),
                Expanded(
                  child: normalItemsBuffer.length > 1 
                      ? _buildGalleryCard(normalItemsBuffer[1], isFeatured: false) 
                      : const SizedBox(), // Kosong jika ganjil
                ),
              ],
            ),
          ),
        );
        normalItemsBuffer.clear();
      }
    }

    for (var item in items) {
      bool isFeatured = item['is_featured'] == 1 || item['is_featured'] == true;

      if (isFeatured) {
        flushNormalItems(); // Jika ada item kecil, render dulu
        
        // Render item besar (Full Width)
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildGalleryCard(item, isFeatured: true),
          )
        );
      } else {
        normalItemsBuffer.add(item);
        if (normalItemsBuffer.length == 2) {
          flushNormalItems(); // Render 2 item bersebelahan
        }
      }
    }
    
    // Habiskan sisa item jika ada
    flushNormalItems();

    return widgets;
  }

  // WIDGET CARD UNTUK FOTO/VIDEO
  Widget _buildGalleryCard(dynamic item, {required bool isFeatured}) {
    String imageUrl = item['image_url'] ?? item['url'] ?? item['file_path'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imageUrl';
    }

    String title = item['title'] ?? '';
    String type = (item['type'] ?? 'image').toString().toLowerCase(); // image atau video

    return Container(
      height: isFeatured ? 220 : 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gambar Background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),

          // Layer Hitam Gradasi (Agar teks putih terbaca)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          // Tanda Video (Jika tipe video)
          if (type == 'video')
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ),

          // Judul di pojok kiri bawah
          if (title.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                title,
                style: GoogleFonts.sora(color: Colors.white, fontSize: isFeatured ? 16 : 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // RENDER BODY 
  // ==========================================
  Widget _buildBody() {
    const Color primaryNavy = Color(0xFF14334C);

    List<dynamic> displayedImages = galleryImages;
    if (_selectedCategory != 'All') {
      displayedImages = galleryImages.where((item) {
        String cat = (item['category'] ?? '').toString().toLowerCase();
        return cat == _selectedCategory.toLowerCase();
      }).toList();
    }

    return Column(
      children: [
        const SizedBox(height: 32),
        Text("Our Gallery", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: primaryNavy)),
        const SizedBox(height: 8),
        Text("Moments captured at Caldera Resto & Pool", style: GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade600), textAlign: TextAlign.center),
        const SizedBox(height: 24),

        // FILTER KATEGORI 
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categories.map((category) {
              bool isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryNavy : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? primaryNavy : Colors.grey.shade300),
                    ),
                    child: Text(category, style: GoogleFonts.sora(color: isSelected ? Colors.white : Colors.grey.shade600, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // KONTEN DENGAN PULL-TO-REFRESH
        Expanded(
          child: RefreshIndicator(
            color: primaryNavy,
            onRefresh: () async {
              await _fetchGallery();
              await _fetchNotifications();
            },
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryNavy))
              : displayedImages.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), 
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("Belum ada media di kategori ini", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  // 👇 MENGGUNAKAN LAYOUT DINAMIS (Featured / Normal) 👇
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildGalleryLayout(displayedImages),
                      ),
                    ),
          ),
        ),
      ],
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

      body: _buildBody(),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, 
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