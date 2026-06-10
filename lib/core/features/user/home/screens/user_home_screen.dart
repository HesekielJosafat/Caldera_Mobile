import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORT SERVICE & GLOBAL WIDGETS
import '../../../../services/api_service.dart';
import '../../../../widgets/app_footer.dart';
// (Import app_header SUDAH DIHAPUS DARI SINI KARENA BIKIN DOBEL)

// IMPORT HALAMAN NAVIGASI DALAM BERANDA
import '../../pool/screens/user_facility_screen.dart'; 
import '../../reservation/screens/user_reservation_screen.dart'; 
import '../../menu/screens/user_menu_screen.dart'; 
import '../../about/screens/user_about_screen.dart';
import '../../gallery/screens/user_gallery_screen.dart';
import '../../event_promo/screens/user_promo_screen.dart';
import '../../testimoni/screens/user_testimoni_screen.dart';
import '../../testimoni/screens/write_review_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
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
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    
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

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? Center(child: CircularProgressIndicator(color: primaryNavy))
      : RefreshIndicator(
          color: activeGold,
          onRefresh: _fetchAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER GANDA SUDAH DIHAPUS DARI SINI. 
                // Langsung mulai dari Hero Section.
                _buildHeroSection(),
                _buildQuickLinks(),
                _buildSectionHeader("Special Offers", "Exclusive deals every week at Caldera"),
                _buildOffersSection(),
                _buildAtmosphereSection(),
                _buildSectionHeader("Discover What's New", "Fresh flavors, new creations, and fan favorites"),
                _buildFeaturedMenuSection(),
                _buildSectionHeader("What Our Customers Say", "Real experiences from real people"),
                _buildTestimonialSection(),
                // _buildSectionHeader("Events Not to Be Missed", "Get in on the action at Caldera"),
                // _buildEventsSection(),
                _buildSectionHeader("Plan Your Visit", "Location, operational hours, and contact"),
                const GlobalAppFooter(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
  }

  // ==========================================
  // WIDGET COMPONENTS 
  // ==========================================

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home.jpeg'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF14334C).withOpacity(0.5), const Color(0xFF14334C).withOpacity(0.8)],
          )
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Caldera ', style: TextStyle(color: activeGold)),
                  const TextSpan(text: 'Resto & Pool', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Experience the perfect blend of culinary delight and refreshing pool experience",
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 30),
            // Row(
            //   children: [
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         style: ElevatedButton.styleFrom(backgroundColor: activeGold, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            //         onPressed: () {
            //           Navigator.push(context, MaterialPageRoute(builder: (context) => const UserReservationScreen()));
            //         },
            //         icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            //         label: Text("Book a Table", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: OutlinedButton.icon(
            //         style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white, width: 2), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            //         onPressed: () {
            //           Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPoolScreen()));
            //         },
            //         icon: const Icon(Icons.confirmation_number, color: Colors.white, size: 16),
            //         label: Text("Pool Ticket", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            //       ),
            //     ),
            //   ],
            // )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Container(
      transform: Matrix4.translationValues(0.0, -20.0, 0.0), 
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGridItem(Icons.info_outline, "About Us", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAboutScreen()));
            }),
            _buildGridItem(Icons.local_offer, "Promo", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPromoScreen()));
            }),
            _buildGridItem(Icons.photo_library, "Gallery", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGalleryScreen()));
            }),
            _buildGridItem(Icons.star_outline, "Testimoni", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserTestimoniScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: primaryNavy, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: primaryNavy)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Center(
        child: Column(
          children: [
            Text(title, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
            Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 50, height: 3, decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(2))),
            Text(subtitle, style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection() {
    final offers = _promos.where((p) => p['is_active'] == 1 && p['promo_type'] != 'event').toList();

    if (offers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text("No active promos at the moment", style: GoogleFonts.sora(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPromoScreen()));
              },
              child: Text("Lihat Semua Promo", style: GoogleFonts.sora(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final promo = offers[index];
              return Container(
                width: 280, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border(top: BorderSide(color: activeGold, width: 3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(20)), child: Text(promo['promo_type'] == 'ticket' ? 'Ticket Promo' : 'Food Promo', style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    Text(promo['title'] ?? '', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(promo['discount_value'] != null ? '${promo['discount_value']} OFF' : 'Special Price', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: activeGold)),
                    const SizedBox(height: 8),
                    Text(promo['description'] ?? '', style: GoogleFonts.sora(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide(color: activeGold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPromoScreen()));
            },
            child: Text("View All Promos", style: GoogleFonts.sora(color: activeGold, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildAtmosphereSection() {
    return Container(
      margin: const EdgeInsets.only(top: 40), padding: const EdgeInsets.all(24), color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Legendary Atmosphere", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 50, height: 3, decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Text("There's nothing better than spending time with family and friends in the best atmosphere.", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          Text("Whether you're looking for a relaxing swim, a delicious meal with loved ones, or a place to celebrate special occasions, Caldera offers the perfect setting.", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAboutScreen()));
            }, 
            child: Text("Learn More", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMenuSection() {
    final featuredMenus = _menus.where((m) => m['is_recommended'] == 1 || m['is_recommended'] == true).take(5).toList();

    if (featuredMenus.isEmpty) return Center(child: Text("No featured menus available", style: GoogleFonts.sora(color: Colors.grey)));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: featuredMenus.length,
            itemBuilder: (context, index) {
              final menu = featuredMenus[index];
              String imgUrl = menu['image_url'] ?? menu['image'] ?? '';
              if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) imgUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imgUrl';

              return Container(
                width: 160, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(50), child: imgUrl.isNotEmpty ? Image.network(imgUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.fastfood, size: 40, color: activeGold)) : Icon(Icons.fastfood, size: 40, color: activeGold)),
                    const SizedBox(height: 16),
                    Text(menu['name'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: primaryNavy), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text("Rp ${menu['price']}", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: activeGold)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserMenuScreen()));
            },
            child: Text("View Full Menu", style: GoogleFonts.sora(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildTestimonialSection() {
    final approvedTesti = _testimonials.where((t) => t['is_approved'] == 1 || t['is_approved'] == true).take(5).toList();

    if (approvedTesti.isEmpty) return Center(child: Text("No testimonials yet.", style: GoogleFonts.sora(color: Colors.grey)));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: approvedTesti.length,
            itemBuilder: (context, index) {
              final testi = approvedTesti[index];
              int rating = int.tryParse(testi['rating'].toString()) ?? 5;

              return Container(
                width: 280, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: activeGold, size: 14))),
                    const SizedBox(height: 12),
                    Expanded(child: Text('"${testi['comment'] ?? ''}"', style: GoogleFonts.sora(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700), overflow: TextOverflow.fade)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: primaryNavy, radius: 16, child: Text((testi['customer_name'] ?? 'U')[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(testi['customer_name'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)), Text("Visitor", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey))])
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: BorderSide(color: activeGold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserTestimoniScreen()));
              },
              child: Text("Read All Reviews", style: GoogleFonts.sora(color: activeGold, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WriteReviewScreen()));
              },
              icon: const Icon(Icons.star, size: 14, color: Colors.white),
              label: Text("Write a Review", style: GoogleFonts.sora(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEventsSection() {
    final events = _promos.where((p) => p['is_active'] == 1 && p['promo_type'] == 'event').toList();

    // if (events.isEmpty) {
    //   return Center(
    //     child: Container(
    //       width: 250,
    //       padding: const EdgeInsets.all(20),
    //       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           Icon(Icons.music_note, size: 40, color: activeGold),
    //           const SizedBox(height: 16),
    //           Text("Live Music Every Friday", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy), textAlign: TextAlign.center),
    //           const SizedBox(height: 8),
    //           Text("Enjoy live acoustic performances\n7 PM - 10 PM", style: GoogleFonts.sora(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
    //           const SizedBox(height: 12),
    //           Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(20)), child: Text("Free Entry", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
    //         ],
    //       ),
    //     ),
    //   );
    // }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Container(
            width: 250, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 40, color: activeGold),
                const SizedBox(height: 16),
                Text(event['title'] ?? '', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy), textAlign: TextAlign.center, maxLines: 1),
                const SizedBox(height: 8),
                Text(event['description'] ?? '', style: GoogleFonts.sora(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center, maxLines: 2),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPromoScreen()));
                  },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(20)), child: Text("Lihat Detail", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                )
              ],
            ),
          );
        },
      ),
    );
  }
}