import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// IMPORT KOMPONEN & FITUR
import '../auth/screens/login_screen.dart'; 
import 'dashboard/admin_dashboard_screen.dart';
import 'menu_management/screens/admin_menu_screen.dart';
import 'gallery_management/screens/admin_gallery_screen.dart';
import 'reservation_management/screens/admin_reservation_screen.dart';
import 'testimonial_management/screens/admin_testimonial_screen.dart';
import 'facilities/admin_facilities_screen.dart';
import 'report_overview/report_overview_screen.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _selectedIndex = 0;

  // Daftar Halaman
  final List<Widget> _adminPages = [
    const AdminDashboardScreen(),
    const AdminMenuScreen(),
    const AdminGalleryScreen(),
    const AdminReservationScreen(),
    const AdminTestimonialScreen(),
    const Scaffold(body: Center(child: Text("Promo Page"))),
    const AdminFacilitiesScreen(), 
    const AdminReportScreen(), 
  ];

  // Daftar Judul (Notification tidak ada di Sidebar lagi)
  final List<String> _pageTitles = [
    'Dashboard',
    'Menu Management',
    'Gallery Management',
    'Confirm Reservations',
    'Customer Testimonials',
    'Promo Management',
    'Facilities',
    'Report Overview',
  ];

  // Daftar Ikon (Opsional untuk mempercantik)
  final List<IconData> _navIcons = [
    Icons.dashboard,
    Icons.restaurant_menu,
    Icons.photo_library,
    Icons.table_restaurant,
    Icons.comment,
    Icons.local_offer,
    Icons.pool,
    Icons.assessment,
  ];

  // ==========================================
  // FUNGSI POPUP NOTIFIKASI
  // ==========================================
  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Transparan agar terlihat seperti Dropdown
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Area luar untuk menutup popup jika diklik
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Kotak Popup Notifikasi
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 5,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300, // Lebar popup
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Menyesuaikan tinggi dengan isi
                    children: [
                      // HEADER POPUP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active, size: 16, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Text("Notifikasi", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Logika API "Tandai Semua Dibaca"
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua notifikasi ditandai dibaca")));
                            },
                            child: Text("Tandai semua dibaca", style: GoogleFonts.sora(fontSize: 10, color: const Color(0xFFD4AF37))),
                          )
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.black12),
                      ),
                      
                      // BODY POPUP (KONDISI KOSONG)
                      // TODO: Nanti kita integrasikan API List Notifikasi di sini
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 32, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text("Belum ada notifikasi", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // APP BAR 
      appBar: AppBar(
        backgroundColor: const Color(0xFF14334C),
        elevation: 0,
        title: Text(_pageTitles[_selectedIndex], style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // IKON NOTIFIKASI
          IconButton(
            onPressed: () => _showNotificationPopup(context), // Panggil Popup Notifikasi
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    // Angka notif (sementara di-hardcode 0, nanti dari API)
                    child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // DRAWER (SIDEBAR)
      drawer: Drawer(
        child: Column(
          children:[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF14334C)),
              accountName: Text("Super Admin Caldera", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
              accountEmail: Text("admin@caldera.com", style: GoogleFonts.sora()),
              currentAccountPicture: const CircleAvatar(backgroundColor: Color(0xFFD4AF37), child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _pageTitles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    selected: _selectedIndex == index,
                    selectedTileColor: const Color(0xFF14334C).withOpacity(0.1),
                    leading: Icon(_navIcons[index], color: _selectedIndex == index ? const Color(0xFF14334C) : Colors.grey),
                    title: Text(_pageTitles[index], style: GoogleFonts.sora(fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context); // Tutup drawer
                    },
                  );
                },
              ),
            ),
            
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text("Log Out", style: GoogleFonts.sora(color: Colors.red)),
              onTap: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      
      body: _adminPages[_selectedIndex],
    );
  }
}