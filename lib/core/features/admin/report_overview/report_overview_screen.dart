import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_report_tickets_screen.dart';
import 'admin_report_reservations_screen.dart';
import 'admin_report_income_screen.dart';

class AdminReportScreen extends StatelessWidget {
  const AdminReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KARTU 1: LAPORAN TIKET KOLAM
          _buildReportCard(
            context: context,
            title: "Laporan Tiket Kolam",
            subtitle: "Lihat laporan penjualan tiket kolam",
            icon: Icons.confirmation_number,
            iconColor: const Color(0xFF14334C), // Navy
            onTap: () {
              // PERUBAHAN: Panggil Navigator.push
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportTicketsScreen()));
            },
          ),
          const SizedBox(height: 16),

          // KARTU 2: LAPORAN RESERVASI
          _buildReportCard(
            context: context,
            title: "Laporan Reservasi",
            subtitle: "Lihat laporan reservasi meja",
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportReservationsScreen()));
            },
          ),
          const SizedBox(height: 16),

          // KARTU 3: LAPORAN PEMASUKAN
          _buildReportCard(
            context: context,
            title: "Laporan Pemasukan",
            subtitle: "Lihat laporan pendapatan keseluruhan",
            icon: Icons.attach_money,
            iconColor: const Color(0xFFD4AF37),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportIncomeScreen()));
            },
          ),
        ],
      ),
    );
  }

  // WIDGET BANTUAN UNTUK KARTU LAPORAN
  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Ikon Bundar di atas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(height: 16),
                
                // Judul dan Subjudul
                Text(
                  title,
                  style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF14334C)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.sora(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Tombol "Lihat Laporan" di bagian bawah kartu
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF14334C), // Navy blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Lihat Laporan",
                    style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}