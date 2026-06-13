import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// PASTIKAN SEMUA IMPORT INI SESUAI DENGAN LOKASI FILE ANDA
import 'package:caldera_app/core/services/api_service.dart';
import 'user_promo_detail_screen.dart'; 

import '../../../../widgets/custom_bottom_nav.dart'; 
import '../../notification/screens/user_notification_screen.dart';
import '../../main_user_screen.dart'; 

class UserPromoScreen extends StatefulWidget {
  const UserPromoScreen({Key? key}) : super(key: key);

  @override
  State<UserPromoScreen> createState() => _UserPromoScreenState();
}


// 1. TAMBAHKAN 'with WidgetsBindingObserver' DI SINI
class _UserPromoScreenState extends State<UserPromoScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  List<dynamic> _promos = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchPromos();
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
      _fetchPromos();
    }
  }

  Future<void> _fetchPromos() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getPromos();
    if (mounted) {
      setState(() {
        _promos = data;
        _isLoading = false;
      });
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
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  // 👇 FUNGSI BARU UNTUK MERAPIKAN FORMAT DISKON (Contoh: "40.00" -> "40% OFF") 👇
  String _formatDiscount(dynamic discountValue) {
    if (discountValue == null) return "Special Price";
    
    // Ubah jadi string
    String strValue = discountValue.toString();
    
    // Jika ada desimal ".00", potong bagian desimalnya
    if (strValue.endsWith(".00")) {
      strValue = strValue.substring(0, strValue.length - 3);
    }
    
    return "$strValue% OFF";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);
    
    final activePromos = _promos.where((p) => p['is_active'] == 1 || p['is_active'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: primaryNavy,
        elevation: 0,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserNotificationScreen()),
              ).then((_) => _fetchNotifications());
            },
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
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
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
              onRefresh: () async {
                await _fetchPromos();
                await _fetchNotifications();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text("Special Promos", style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: primaryNavy)),
                          const SizedBox(height: 8),
                          Text("Get exciting discounts and offers", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    activePromos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Text("Tidak ada promo aktif saat ini.", style: GoogleFonts.sora(color: Colors.grey)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activePromos.length,
                            itemBuilder: (context, index) {
                              final promo = activePromos[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => UserPromoDetailScreen(promo: promo)));
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                    border: Border.all(color: Colors.grey.shade200), // Tambahan border halus karena tidak ada gambar
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Baris Atas: Badge Tipe & Badge Promo Code
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                (promo['promo_type'] ?? 'Promo').toString().toUpperCase(), 
                                                style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                              ),
                                            ),
                                            if (promo['promo_code'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: Text(
                                                  "Code: ${promo['promo_code']}", 
                                                  style: GoogleFonts.sora(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Judul
                                        Text(promo['title'] ?? '', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(height: 8),
                                        
                                        // Deskripsi Singkat
                                        Text(promo['description'] ?? '', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 16),
                                        
                                        // Baris Bawah: Diskon & Tombol Lihat Detail
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              // 👇 MEMANGGIL FUNGSI FORMAT DISKON 👇
                                              _formatDiscount(promo['discount_value']), 
                                              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade600)
                                            ),
                                            Row(
                                              children: [
                                                Text("Lihat Detail", style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: activeGold)),
                                                const Icon(Icons.arrow_forward_ios, size: 12, color: activeGold),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, 
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pop(context); 
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainUserScreen(initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}