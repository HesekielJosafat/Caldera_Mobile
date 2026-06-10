import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';

// Import halaman tujuan "Order Now"
import '../../menu/screens/user_menu_screen.dart';
import '../../reservation/screens/user_reservation_screen.dart';
import '../../pool/screens/user_facility_screen.dart';

class UserPromoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promo;

  const UserPromoDetailScreen({Key? key, required this.promo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);

    String imgUrl = promo['banner_image'] ?? '';
    if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
      imgUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imgUrl';
    }

    String discountText = promo['discount_value'] != null ? "Diskon ${promo['discount_value']}" : "Special Price";
    String promoType = (promo['promo_type'] ?? 'Promo').toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(promo['title'] ?? 'Promo Detail', style: GoogleFonts.sora(color: Colors.white, fontSize: 16)),
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GAMBAR UTAMA
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imgUrl.isNotEmpty
                    ? Image.network(imgUrl, height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildPlaceholder())
                    : _buildPlaceholder(),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. BADGE TIPE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                      child: Text(promoType.toUpperCase(), style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    
                    // 3. JUDUL & DISKON (Warna Biru seperti di web)
                    Text(promo['title'] ?? '', style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(discountText, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
                    const SizedBox(height: 16),
                    
                    // 4. DESKRIPSI
                    Text(promo['description'] ?? '', style: GoogleFonts.sora(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
                    const SizedBox(height: 24),

                    // 5. KODE PROMO (Kotak Biru Muda)
                    if (promo['promo_code'] != null)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(8)),
                        child: RichText(text: TextSpan(style: GoogleFonts.sora(color: Colors.black87, fontSize: 14), children: [
                          const TextSpan(text: "Promo Code: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: promo['promo_code']),
                        ])),
                      ),
                    
                    const SizedBox(height: 12),

                    // 6. TANGGAL VALID (Kotak Kuning Muda)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: RichText(text: TextSpan(style: GoogleFonts.sora(color: Colors.black87, fontSize: 14), children: [
                        const TextSpan(text: "Valid until: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        // Coba parse tanggal jika formatnya standar
                        TextSpan(text: promo['end_date']?.toString().split('T')[0] ?? '-'),
                      ])),
                    ),
                    
                    const SizedBox(height: 30),

                    // 7. TOMBOL ORDER NOW
                    SizedBox(
                      width: 150, // Tombol tidak full width (seperti di web)
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () {
                          // Arahkan berdasarkan tipe promo
                          if (promoType.contains('menu') || promoType.contains('food')) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserMenuScreen()));
                          } else if (promoType.contains('reservation')) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserReservationScreen()));
                          } else {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserPoolScreen())); // Default tiket kolam
                          }
                        },
                        child: Text("Order Now", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(height: 250, width: double.infinity, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.local_offer, size: 60, color: Colors.grey)));
  }
}