import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// PASTIKAN IMPORT INI BENAR
import '../../../../services/api_service.dart';
import '../../../../widgets/custom_bottom_nav.dart'; 
import '../../../../widgets/app_footer.dart'; // 👈 IMPORT APP FOOTER DI SINI
import '../../notification/screens/user_notification_screen.dart';

// IMPORT FILE MAIN USER SCREEN ANDA DI SINI
import '../../main_user_screen.dart'; 

class UserAboutScreen extends StatefulWidget {
  const UserAboutScreen({super.key});

  @override
  State<UserAboutScreen> createState() => _UserAboutScreenState();
}

class _UserAboutScreenState extends State<UserAboutScreen> {
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;

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
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
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

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // Padding horizontal dihapus agar gambar dan footer bisa full-width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR BANNER ATAS (Dibuat Full Width Tanpa Padding)
            Image.asset(
              'assets/images/about.jpeg',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            
            // KONTEN TEKS (Diberi Padding Dalam)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Our Story", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                  const SizedBox(height: 12),
                  Text(
                    "Caldera Resto and Pool berdiri sejak tahun 2020 dengan konsep restoran keluarga yang dilengkapi fasilitas kolam renang. Berawal dari keinginan menciptakan tempat berkumpul yang nyaman untuk keluarga dan teman, Caldera kini telah menjadi salah satu destinasi favorit di kota.",
                    style: GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade700, height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Kami berkomitmen untuk memberikan pelayanan terbaik, makanan berkualitas, dan pengalaman yang tak terlupakan bagi setiap pengunjung. Dengan suasana yang hangat dan pelayanan ramah, Caldera siap menjadi rumah kedua bagi Anda dan keluarga.",
                    style: GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade700, height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 32),

                  _buildFeatureCard(Icons.restaurant, "Delicious Cuisine", "Authentic Indonesian and international dishes prepared by our expert chefs using fresh ingredients.", activeGold),
                  _buildFeatureCard(Icons.pool, "Refreshing Pool", "Clean and well-maintained swimming pool perfect for family fun and relaxation.", activeGold),
                  _buildFeatureCard(Icons.music_note, "Live Entertainment", "Regular live music and special events to enhance your dining experience.", activeGold),
                  const SizedBox(height: 32),

                  Center(
                    child: Column(
                      children: [
                        Text("Vision & Mission", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                        Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 50, height: 3, decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildVisionMissionCard("Vision", Icons.visibility, "\"Menjadi destinasi kuliner dan rekreasi terbaik di Indonesia yang dikenal dengan pelayanan prima dan pengalaman tak terlupakan bagi setiap pelanggan.\"", activeGold, isItalic: true),
                  const SizedBox(height: 16),
                  _buildVisionMissionCard("Mission", Icons.gps_fixed, "• Menyediakan makanan berkualitas dengan harga terjangkau\n\n• Memberikan pelayanan terbaik dan ramah kepada pelanggan\n\n• Menciptakan suasana yang nyaman dan menyenangkan\n\n• Mengembangkan inovasi menu secara berkelanjutan", activeGold),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // JUDUL PLAN YOUR VISIT
            Center(
              child: Column(
                children: [
                  Text("Plan Your Visit", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                  Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 50, height: 3, decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 👇 PEMANGGILAN FOOTER GLOBAL 👇
            const GlobalAppFooter(), 
            
            const SizedBox(height: 40),
          ],
        ),
      ),

      // =====================================
      // BOTTOM NAV BAR SEMPURNA
      // =====================================
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

  // --- Kumpulan Helper Widget Tetap Sama ---
  Widget _buildFeatureCard(IconData icon, String title, String desc, Color goldColor) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Icon(icon, color: goldColor, size: 40), const SizedBox(height: 12), Text(title, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF14334C))), const SizedBox(height: 8), Text(desc, textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600, height: 1.5))]));
  }
  
  Widget _buildVisionMissionCard(String title, IconData icon, String content, Color goldColor, {bool isItalic = false}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: goldColor, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: goldColor, size: 20), const SizedBox(width: 10), Text(title, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF14334C)))]), const SizedBox(height: 12), Text(content, style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade700, height: 1.6, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal))]));
  }
}