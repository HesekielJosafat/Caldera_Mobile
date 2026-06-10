import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalAppHeader extends StatelessWidget {
  const GlobalAppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 24, right: 16, bottom: 16),
      decoration: const BoxDecoration(color: primaryNavy),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LOGO TEXT
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                const TextSpan(text: 'Caldera ', style: TextStyle(color: activeGold)),
                const TextSpan(text: 'Resto & Pool', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          
          // NOTIFICATION ICON
          IconButton(
            onPressed: () { 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buka Notifikasi User")));
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}