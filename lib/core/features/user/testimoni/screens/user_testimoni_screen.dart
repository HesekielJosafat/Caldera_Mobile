import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

// IMPORT API, NAVBAR, DAN HALAMAN TERKAIT
import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';

import 'write_review_screen.dart';

class UserTestimoniScreen extends StatefulWidget {
  const UserTestimoniScreen({Key? key}) : super(key: key);

  @override
  State<UserTestimoniScreen> createState() => _UserTestimoniScreenState();
}

// 1. TAMBAHKAN 'with WidgetsBindingObserver' DI SINI
class _UserTestimoniScreenState extends State<UserTestimoniScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  List<dynamic> allReviews = [];
  bool isLoading = true;
  
  // State untuk Filter
  String selectedFilter = 'all'; 
  String filterDisplayText = 'Filter Reviews';

  // ==========================================
  // STATE NOTIFIKASI
  // ==========================================
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', IdMessages());
     // 2. DAFTARKAN OBSERVER SAAT HALAMAN DIBUKA
    WidgetsBinding.instance.addObserver(this); 
    _fetchTestimonials();
    _fetchNotifications();
  }

  @override
  void dispose() {
    // 3. CABUT OBSERVER SAAT HALAMAN DITUTUP
    WidgetsBinding.instance.removeObserver(this); 
    super.dispose();
  }

  // 👇 4. INI ADALAH FUNGSI SAKTINYA (Deteksi aplikasi dibuka kembali) 👇
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Jika aplikasi kembali dibuka dari background, otomatis ambil data terbaru!
      print("Aplikasi dibuka kembali! Auto-refresh Beranda...");
      _fetchTestimonials();
    }
  }

  // ==========================================
  // FUNGSI DATA TESTIMONI & KALKULASI
  // ==========================================
  Future<void> _fetchTestimonials() async {
    try {
      final List<dynamic> data = await _apiService.getTestimonials();
      if (mounted) {
        setState(() {
          allReviews = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double _calculateAverageRating() {
    if (allReviews.isEmpty) return 0.0;
    double sum = 0;
    for (var review in allReviews) {
      sum += double.tryParse(review['rating']?.toString() ?? '5') ?? 5.0;
    }
    return sum / allReviews.length;
  }

  // Menghitung jumlah masing-masing bintang untuk Progress Bar
  List<int> _calculateRatingDistribution() {
    List<int> counts = [0, 0, 0, 0, 0]; // index 0 = bintang 5, index 4 = bintang 1
    for (var review in allReviews) {
      int rating = int.tryParse(review['rating']?.toString() ?? '5') ?? 5;
      if (rating >= 1 && rating <= 5) {
        counts[5 - rating]++; // Membalik index agar bintang 5 di atas
      }
    }
    return counts;
  }

  // ==========================================
  // FUNGSI NOTIFIKASI (SAMA SEPERTI SEBELUMNYA)
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
    Navigator.of(context).pop(); 

    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read';
      }
    });

    bool success = await _apiService.markAllNotificationsAsRead();
    if (success) {
      await _fetchNotifications();
    }
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

  void _showNotificationPopup() {
    _fetchNotifications();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
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
                              GestureDetector(onTap: _markAllAsRead, child: Text("Tandai semua dibaca", style: GoogleFonts.sora(fontSize: 10, color: const Color(0xFF14334C), fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                      Flexible(
                        child: _notifications.isEmpty
                            ? Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Column(children: [Icon(Icons.notifications_off_outlined, size: 32, color: Colors.grey.shade400), const SizedBox(height: 8), Text("Belum ada notifikasi", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 11))]))
                            : ListView.separated(
                                shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _notifications.length > 4 ? 4 : _notifications.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final notif = _notifications[index];
                                  bool isUnread = notif['read_at'] == null;
                                  return Container(
                                    color: isUnread ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(backgroundColor: const Color(0xFF14334C).withOpacity(0.1), child: const Icon(Icons.notifications, color: Color(0xFF14334C), size: 18)),
                                      title: Row(children: [Expanded(child: Text(notif['title'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal))), if (isUnread) const Icon(Icons.circle, size: 8, color: Colors.red)]),
                                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text(notif['body'] ?? '', style: GoogleFonts.sora(fontSize: 10, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text(_formatTime(notif['created_at']), style: GoogleFonts.sora(fontSize: 9, color: Colors.grey))]),
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
                        child: Container(width: double.infinity, padding: const EdgeInsets.all(12), child: Text("Lihat semua notifikasi →", textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 11, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
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
  }

  // ==========================================
  // RENDER WIDGET PROGRESS BAR BINTANG
  // ==========================================
  Widget _buildRatingBarRow(String label, int count, int total) {
    double percentage = total == 0 ? 0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(label, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(count.toString(), textAlign: TextAlign.right, style: GoogleFonts.sora(fontSize: 11, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RENDER BODY UTAMA
  // ==========================================
  Widget _buildBody() {
    const Color primaryNavy = Color(0xFF14334C);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryNavy));
    }

    // LOGIKA FILTER
    List<dynamic> filteredReviews = allReviews.where((review) {
      int rating = int.tryParse(review['rating']?.toString() ?? '5') ?? 5;
      String serviceType = (review['service_type'] ?? review['service'] ?? '').toString().toLowerCase();

      if (selectedFilter == 'all') return true;
      if (selectedFilter == '5_star') return rating == 5;
      if (selectedFilter == '4_star') return rating == 4;
      if (selectedFilter == '3_star') return rating == 3;
      if (selectedFilter == '2_star') return rating == 2;
      if (selectedFilter == '1_star') return rating == 1;
      
      if (selectedFilter == 'restaurant') return serviceType.contains('restaurant');
      if (selectedFilter == 'pool') return serviceType.contains('pool');
      if (selectedFilter == 'event') return serviceType.contains('event');

      return true;
    }).toList();

    double averageRating = _calculateAverageRating();
    List<int> ratingCounts = _calculateRatingDistribution();

    // 1. TAMBAHKAN REFRESH INDICATOR DI SINI
    return RefreshIndicator(
      color: primaryNavy, // Warna panah loading
      backgroundColor: Colors.white, // Warna background lingkaran panah
      onRefresh: _fetchTestimonials, // Panggil API saat layar ditarik
      child: SingleChildScrollView(
        // 2. TAMBAHKAN PHYSICS INI AGAR SELALU BISA DITARIK MESKI LAYAR KOSONG
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. JUDUL & SUBJUDUL ALA WEB
              const SizedBox(height: 10),
              Text(
                "What Our Customers Say", 
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: primaryNavy)
              ),
              const SizedBox(height: 8),
              Text(
                "Real experiences from real people", 
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // 2. KARTU STATISTIK (AVERAGE + PROGRESS BARS)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4))],
                ),
                child: Column(
                  children: [
                    // Rata-rata Bintang
                    Text(
                      averageRating.toStringAsFixed(1), 
                      style: GoogleFonts.sora(fontSize: 56, fontWeight: FontWeight.bold, color: primaryNavy)
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Icon(
                        index < averageRating.round() ? Icons.star : Icons.star_border, 
                        color: const Color(0xFFD4AF37), size: 24
                      )),
                    ),
                    const SizedBox(height: 8),
                    Text("Average Rating", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text("Based on ${allReviews.length} reviews", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.black12)),

                    // Grafik Batang
                    _buildRatingBarRow("5 Star", ratingCounts[0], allReviews.length),
                    _buildRatingBarRow("4 Star", ratingCounts[1], allReviews.length),
                    _buildRatingBarRow("3 Star", ratingCounts[2], allReviews.length),
                    _buildRatingBarRow("2 Star", ratingCounts[3], allReviews.length),
                    _buildRatingBarRow("1 Star", ratingCounts[4], allReviews.length),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. ROW BUTTONS (TULIS REVIEW & FILTER)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 16),
                      label: Text("Write a Review", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const WriteReviewScreen()));
                        _fetchTestimonials();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // CUSTOM POPUP MENU FILTER (Sesuai Gambar Web)
                  Expanded(
                    child: PopupMenuButton<String>(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      offset: const Offset(0, 50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryNavy),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_list, color: primaryNavy, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                filterDisplayText, 
                                style: GoogleFonts.sora(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              )
                            ),
                            const Icon(Icons.arrow_drop_down, color: primaryNavy, size: 18),
                          ],
                        ),
                      ),
                      onSelected: (String value) {
                        setState(() {
                          selectedFilter = value;
                          switch(value) {
                            case 'all': filterDisplayText = 'All Reviews'; break;
                            case '5_star': filterDisplayText = '5 Star'; break;
                            case '4_star': filterDisplayText = '4 Star'; break;
                            case '3_star': filterDisplayText = '3 Star'; break;
                            case '2_star': filterDisplayText = '2 Star'; break;
                            case '1_star': filterDisplayText = '1 Star'; break;
                            case 'restaurant': filterDisplayText = 'Restaurant'; break;
                            case 'pool': filterDisplayText = 'Pool'; break;
                            case 'event': filterDisplayText = 'Event'; break;
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        _buildPopupItem('all', 'All Reviews', null),
                        const PopupMenuDivider(),
                        _buildPopupItem('5_star', '5 Star', Icons.star),
                        _buildPopupItem('4_star', '4 Star', Icons.star),
                        _buildPopupItem('3_star', '3 Star', Icons.star),
                        _buildPopupItem('2_star', '2 Star', Icons.star),
                        _buildPopupItem('1_star', '1 Star', Icons.star),
                        const PopupMenuDivider(),
                        _buildPopupItem('restaurant', 'Restaurant', Icons.restaurant),
                        _buildPopupItem('pool', 'Pool', Icons.pool),
                        _buildPopupItem('event', 'Event', Icons.calendar_today),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. LIST REVIEW
              filteredReviews.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Belum ada ulasan untuk filter ini", style: GoogleFonts.sora(color: Colors.grey))))
                  : ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), // Biarkan never karena sudah di dalam SingleChildScrollView
                      itemCount: filteredReviews.length,
                      itemBuilder: (context, index) {
                        final review = filteredReviews[index];
                        return _buildTestimonialCard(
                          name: review['name'] ?? review['customer_name'] ?? 'User',
                          comment: review['comment'] ?? review['review'] ?? '',
                          rating: int.tryParse(review['rating']?.toString() ?? '5') ?? 5,
                          imageUrl: review['image_url'] ?? review['customer_photo'] ?? '',
                          date: review['created_at'] ?? review['visit_date'] ?? '',
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk Item Popup
  PopupMenuItem<String> _buildPopupItem(String value, String text, IconData? icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
             Icon(icon, size: 16, color: icon == Icons.star ? const Color(0xFFD4AF37) : Colors.grey.shade700),
             const SizedBox(width: 12),
          ],
          Text(text, style: GoogleFonts.sora(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  // Helper Card Review
  Widget _buildTestimonialCard({required String name, required String comment, required int rating, required String imageUrl, required String date}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5), // Warna background kekuningan muda
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF14334C),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: const Color(0xFFD4AF37), size: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('"$comment"', style: GoogleFonts.sora(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic, height: 1.5)),
          const SizedBox(height: 16),
          if (date.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text("Visited: ${date.length > 10 ? date.substring(0, 10) : date}", style: GoogleFonts.sora(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, height: 80, width: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox()),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // ==========================================
      // APP HEADER CALDERA DGN NOTIFIKASI
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

      body: _buildBody(), 

      // ==========================================
      // BOTTOM NAVBAR
      // ==========================================
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, // Disesuaikan, jika testimoni ada di tab Home, index = 0
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