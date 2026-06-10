import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'user_ticket_form_screen.dart';

class UserPoolScreen extends StatefulWidget {
  const UserPoolScreen({Key? key}) : super(key: key);

  @override
  State<UserPoolScreen> createState() => _UserPoolScreenState();
}

class _UserPoolScreenState extends State<UserPoolScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? poolInfo;
  bool isLoading = true;

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _fetchPoolInfo();
  }

  Future<void> _fetchPoolInfo() async {
    try {
      final response = await _apiService.getPoolInfo();
      if (mounted) {
        setState(() {
          poolInfo = response['data'] ?? response; 
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback data jika API kosong/error agar UI tetap terisi data asli dari web
    final String poolName = poolInfo?['name'] ?? "Caldera Pool";
    final Map<String, dynamic> hours = poolInfo?['operational_hours'] ?? {
      'weekdays': '08:00 - 18:00',
      'weekend': '08:00 - 20:00'
    };
    final Map<String, dynamic> prices = poolInfo?['ticket_prices'] ?? {
      'adult': 35000,
      'child': 25000,
      'family': 100000
    };
    final List<dynamic> facilities = poolInfo?['facilities'] ?? [
      'Kolam Dewasa', 'Kolam Anak', 'Water Slide', 'Gazebo', 'Locker', 'Shower'
    ];
    final List<dynamic> rules = poolInfo?['rules'] ?? [
      'Menggunakan pakaian renang', 'Dilarang merokok', 'Anak harus didampingi orang tua'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // bg-light
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryNavy))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. HEADER SECTION (Caldera Pool)
                  // ==========================================
                  Center(
                    child: Column(
                      children: [
                        Text(
                          poolName,
                          style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: primaryNavy),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 50, height: 3,
                          decoration: BoxDecoration(color: activeGold, borderRadius: BorderRadius.circular(2)),
                        ),
                        Text(
                          "Enjoy our refreshing and family-friendly swimming pool",
                          style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 2. HERO IMAGE
                  // ==========================================
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/2.png', // Fallback gambar lokal Anda
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 3. TICKET PRICE TABLE (Meniru Web)
                  // ==========================================
                  Text(
                    "Tiket Masuk Kolam Renang",
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceTable(prices),
                  const SizedBox(height: 20),

                  // BUTTON CTA (Beli Tiket)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserTicketFormScreen()));
                      },
                      icon: Icon(Icons.confirmation_number_outlined, color: activeGold, size: 18),
                      label: Text(
                        "Beli Tiket Sekarang",
                        style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ==========================================
                  // 4. FEATURE CARDS (Jam, Fasilitas, Aturan)
                  // ==========================================
                  _buildFeatureCard(
                    Icons.access_time,
                    "Jam Operasional",
                    "Setiap Hari\n${hours['weekdays']} WIB",
                    activeGold,
                  ),
                  _buildFeatureCard(
                    Icons.check_circle_outline,
                    "Fasilitas",
                    facilities.join(', '),
                    activeGold,
                  ),
                  _buildFeatureCard(
                    Icons.shield_outlined,
                    "Peraturan",
                    rules.join(', '),
                    activeGold,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // WIDGET HELPERS
  // ==========================================

  // Widget membuat Tabel Harga Tiket persis seperti Web Bootstrap
  Widget _buildPriceTable(Map<String, dynamic> prices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0D0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Header (Navy Blue)
            Container(
              color: primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Jenis Tiket", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text("Harga", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            // Table Rows
            _buildTableRow("Dewasa", "Rp ${prices['adult'] ?? 35000}"),
            const Divider(height: 1, color: Color(0xFFE8E0D0)),
            _buildTableRow("Anak-Anak (3-12 tahun)", "Rp ${prices['child'] ?? 25000}"),
            const Divider(height: 1, color: Color(0xFFE8E0D0)),
            _buildTableRow("Keluarga (4 orang)", "Rp ${prices['family'] ?? 100000}"),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.sora(fontSize: 13, color: Colors.black87)),
          Text(value, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: primaryNavy)),
        ],
      ),
    );
  }

  // Card dengan Border Emas di atasnya (border-top: 3px solid #c1a067)
  Widget _buildFeatureCard(IconData icon, String title, String content, Color goldColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(top: BorderSide(color: goldColor, width: 3)), // Border emas atas seperti web
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: goldColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy)),
                const SizedBox(height: 6),
                Text(
                  content, 
                  style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}