import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalAppFooter extends StatelessWidget {
  const GlobalAppFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KARTU LOKASI & KONTAK
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                // Tombol Buka Maps
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse("https://maps.app.goo.gl/dahhwPLVRKnpftdB8");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryNavy.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                          child: const Icon(Icons.map, color: activeGold, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text("Open in Google Maps", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: primaryNavy)),
                      ],
                    ),
                  ),
                ),
                
                // Detail Kontak
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildModernContactRow(primaryNavy, Icons.location_on, "Jl. Patuan Nagari, Sangkar Nihuta, Kec. Balige, Toba, Sumatera Utara 22312"),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildModernContactRow(primaryNavy, Icons.phone, "(022) 1234567 / 0812-3456-7890"),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildModernContactRow(primaryNavy, Icons.email, "info@caldera.com"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. JAM OPERASIONAL
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.restaurant, color: activeGold, size: 24),
                      const SizedBox(height: 12),
                      Text("Resto Hours", style: GoogleFonts.sora(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Mon - Fri:\n10:00 - 22:00", style: GoogleFonts.sora(color: Colors.white, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 4),
                      Text("Sat - Sun:\n09:00 - 23:00", style: GoogleFonts.sora(color: Colors.white, fontSize: 12, height: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pool, color: Colors.blue.shade700, size: 24),
                      const SizedBox(height: 12),
                      Text("Pool Hours", style: GoogleFonts.sora(color: Colors.blue.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Daily:\n08:00 - 18:00", style: GoogleFonts.sora(color: Colors.black87, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 4), 
                      Text("\n", style: GoogleFonts.sora(fontSize: 12, height: 1.5)), 
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 3. SOCIAL MEDIA & COPYRIGHT
          Center(
            child: Column(
              children: [
                Text("Connect With Us", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModernSocialBtn(primaryNavy, Icons.camera_alt_outlined, "https://www.instagram.com/calderarestoandpool/"), 
                    const SizedBox(width: 16),
                    _buildModernSocialBtn(primaryNavy, Icons.music_note, "https://www.tiktok.com/@caldera.resto.cof7"), 
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "© ${DateTime.now().year} Caldera Resto & Pool.\nAll rights reserved.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernContactRow(Color primaryColor, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.sora(fontSize: 12, color: Colors.black87, height: 1.5))),
      ],
    );
  }

  Widget _buildModernSocialBtn(Color primaryColor, IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
    );
  }
}