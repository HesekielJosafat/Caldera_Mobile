import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);
    const Color inactiveWhite = Colors.white54;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // 5 IKON UTAMA DI BOTTOM NAV (MENGGUNAKAN MATERIAL ICON)
    final List<IconData> navIcons = [
      Icons.home_outlined,            // 0. Home
      Icons.pool,                    // 1. Pool
      Icons.calendar_today_outlined, // 2. Reservasi Meja
      Icons.restaurant_menu,         // 3. Menu
      Icons.person_outline,          // 4. Profile
    ];

    final List<String> navLabels = [
      "Home",
      "Pool",
      "Reservasi",
      "Menu",
      "Profile",
    ];

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navIcons.length, (index) {
            bool isActive = selectedIndex == index;
            return GestureDetector(
              onTap: () => onItemTapped(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 65,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      navIcons[index],
                      size: 24,
                      color: isActive ? activeGold : inactiveWhite,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      navLabels[index],
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        color: isActive ? activeGold : inactiveWhite,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}