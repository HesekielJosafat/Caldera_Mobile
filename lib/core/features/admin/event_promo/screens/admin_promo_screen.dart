import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPromoScreen extends StatelessWidget {
  const AdminPromoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Mengikuti warna background dashboard
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () {},
        label: Text("Add New Promo", style: GoogleFonts.sora(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5), // Warna krem tipis sesuai Figma
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Promo 10% OFF Dining", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Active Period : Aug 1 - Aug 31", style: GoogleFonts.sora(fontSize: 12)),
                const SizedBox(height: 8),
                Text("Description : Lorem ipsum dolor sit amet...", style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.edit, color: Colors.red[400], size: 20),
                    const SizedBox(width: 16),
                    Icon(Icons.delete, color: Colors.red[400], size: 20),
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