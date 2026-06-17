import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// IMPORT SERVICE
import '../../../../services/api_service.dart';

// IMPORT HALAMAN NAVIGASI DALAM BERANDA
import '../../menu/screens/user_menu_screen.dart'; 
import '../../about/screens/user_about_screen.dart';
import '../../gallery/screens/user_gallery_screen.dart';
import '../../event_promo/screens/user_promo_screen.dart';
import '../../testimoni/screens/user_testimoni_screen.dart';
import '../../event_promo/screens/user_promo_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);

  bool _isLoading = true;
  List<dynamic> _promos = [];
  List<dynamic> _menus = [];
  List<dynamic> _testimonials = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    _fetchAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAllData(showLoading: false);
    }
  }

  Future<void> _fetchAllData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _apiService.getPromos(),
      _apiService.getMenus(),
      _apiService.getTestimonials(),
    ]);

    if (mounted) {
      setState(() {
        _promos = results[0];
        _menus = results[1];
        _testimonials = results[2];
        _isLoading = false;
      });
    }
  }

  String _formatDiscount(dynamic discountValue) {
    if (discountValue == null) return "Special Price";
    String strValue = discountValue.toString();
    if (strValue.endsWith(".00")) {
      strValue = strValue.substring(0, strValue.length - 3);
    }
    return "$strValue% OFF";
  }

  String _formatCurrency(String priceString) {
    try {
      double price = double.parse(priceString);
      return NumberFormat('#,###', 'id_ID').format(price);
    } catch (e) {
      return priceString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? Center(child: CircularProgressIndicator(color: primaryNavy))
      : RefreshIndicator(
          color: activeGold,
          onRefresh: () => _fetchAllData(showLoading: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                _buildQuickActions(),
                
                // SECTION PROMO (HANYA YANG MASIH AKTIF, TANPA TOMBOL LIHAT SEMUA)
                _buildSectionHeader("Spesial Untukmu", "Exclusive deals every week at Caldera"),
                _buildPromoCarousel(),

                // SECTION MENU REKOMENDASI (TANPA TOMBOL LIHAT SEMUA)
                _buildSectionHeader("Menu Pilihan", "Fresh flavors, new creations, and fan favorites"),
                _buildFeaturedMenuCarousel(),

                // SECTION TESTIMONI (HANYA BINTANG 4-5, TANPA TOMBOL LIHAT SEMUA)
                _buildSectionHeader("Kata Mereka", "Real experiences from real people"),
                _buildTestimonialCarousel(),

                // Footer Plan Your Visit sudah dipindahkan ke layar About Us.
                const SizedBox(height: 40), 
              ],
            ),
          ),
        );
  }

  // ==========================================
  // WIDGET COMPONENTS 
  // ==========================================

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        image: const DecorationImage(
          image: AssetImage('assets/images/home.jpeg'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [primaryNavy.withOpacity(0.8), Colors.transparent],
          )
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selamat Datang di",
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              "Caldera\nResto & Pool",
              style: GoogleFonts.playfairDisplay(color: activeGold, fontSize: 26, fontWeight: FontWeight.bold, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(Icons.info_outline, "About", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAboutScreen()))),
          _buildActionItem(Icons.local_offer_outlined, "Promo", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserPromoScreen()))),
          _buildActionItem(Icons.photo_library_outlined, "Gallery", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGalleryScreen()))),
          _buildActionItem(Icons.star_outline, "Ulasan", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserTestimoniScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade100)
            ),
            child: Icon(icon, color: primaryNavy, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  // Header dimodifikasi (tanpa tombol lihat semua)
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.sora(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel() {
    // 👈 FILTER: HANYA PROMO AKTIF (MASIH BERLAKU) DAN BUKAN EVENT 👇
    final activeOffers = _promos.where((p) {
      bool isActive = p['is_active'] == 1 || p['is_active'] == true;
      bool isNotEvent = p['promo_type'] != 'event';
      
      // Tambahan opsional: Cek end_date jika Anda ingin lebih ketat memfilter dari sisi mobile
      bool isNotExpired = true;
      if (p['end_date'] != null) {
        DateTime endDate = DateTime.parse(p['end_date'].toString());
        isNotExpired = endDate.isAfter(DateTime.now());
      }
      
      return isActive && isNotEvent && isNotExpired;
    }).toList();

    if (activeOffers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Text("Belum ada promo aktif saat ini.", style: GoogleFonts.sora(color: Colors.grey, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activeOffers.length,
        itemBuilder: (context, index) {
          final promo = activeOffers[index];
          String type = promo['promo_type'] == 'ticket' ? 'Tiket' : 'Menu';

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPromoDetailScreen(promo: promo))),
            child: Container(
              width: 240, margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), 
                    child: Text("Promo $type", style: GoogleFonts.sora(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold))
                  ),
                  const Spacer(),
                  Text(promo['title'] ?? '', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_formatDiscount(promo['discount_value']), style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: activeGold)),
                  const SizedBox(height: 4),
                  Text("Gunakan kode: ${promo['promo_code'] ?? '-'}", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedMenuCarousel() {
    // 👈 FILTER: HANYA MENU YANG DIREKOMENDASIKAN ADMIN 👇
    final featuredMenus = _menus.where((m) => m['is_recommended'] == 1 || m['is_recommended'] == true).take(6).toList();

    if (featuredMenus.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Text("Belum ada menu rekomendasi.", style: GoogleFonts.sora(color: Colors.grey, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        itemCount: featuredMenus.length,
        itemBuilder: (context, index) {
          final menu = featuredMenus[index];
          
          String imgUrl = menu['image_url'] ?? menu['image'] ?? '';
          if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
            imgUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imgUrl';
          }

          return Container(
            width: 150, margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), 
                  child: imgUrl.isNotEmpty 
                      ? Image.network(imgUrl, width: 150, height: 110, fit: BoxFit.cover, errorBuilder: (c,e,s) => _fallbackMenuImage()) 
                      : _fallbackMenuImage()
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu['name'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text("Rp ${_formatCurrency(menu['price']?.toString() ?? '0')}", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: primaryNavy)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackMenuImage() {
    return Container(
      width: 150, height: 110, color: Colors.grey.shade100,
      child: Icon(Icons.fastfood, size: 30, color: Colors.grey.shade300),
    );
  }

  Widget _buildTestimonialCarousel() {
    // 👈 FILTER: HANYA TESTIMONI APPROVED & BINTANG 4-5 SAJA 👇
    final bestTesti = _testimonials.where((t) {
      bool isApproved = t['is_approved'] == 1 || t['is_approved'] == true;
      int rating = int.tryParse(t['rating'].toString()) ?? 0;
      return isApproved && rating >= 4; // Hanya bintang 4 dan 5
    }).take(6).toList();

    if (bestTesti.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Text("Belum ada ulasan terbaik.", style: GoogleFonts.sora(color: Colors.grey, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16), 
        itemCount: bestTesti.length,
        itemBuilder: (context, index) {
          final testi = bestTesti[index];
          int rating = int.tryParse(testi['rating'].toString()) ?? 5;

          return Container(
            width: 280, margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: activeGold, size: 14))),
                const SizedBox(height: 12),
                Expanded(child: Text('"${testi['comment'] ?? ''}"', style: GoogleFonts.sora(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700, height: 1.4), overflow: TextOverflow.fade)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(backgroundColor: primaryNavy, radius: 14, child: Text((testi['customer_name'] ?? 'U')[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(testi['customer_name'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)), Text("Caldera Guest", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey))])
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}