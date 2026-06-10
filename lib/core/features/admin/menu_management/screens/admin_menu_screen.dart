import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'admin_menu_form_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({Key? key}) : super(key: key);

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> menus = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    setState(() => isLoading = true);
    final data = await _apiService.getMenus();
    if (mounted) {
      setState(() {
        menus = data;
        isLoading = false;
      });
    }
  }

  Future<void> _deleteMenu(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Menu", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus menu ini?", style: GoogleFonts.sora()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => isLoading = true);
      bool success = await _apiService.deleteMenu(id);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menu berhasil dihapus")));
        _fetchMenus();
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus menu")));
        }
      }
    }
  }

  void _navigateAndRefresh(Map<String, dynamic>? menuData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminMenuFormScreen(menu: menuData)),
    );
    if (result == true) {
      _fetchMenus();
    }
  }

  // Helper untuk menampilkan gambar dengan benar
  Widget _buildMenuImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return _fallbackImage();

    // Jika path sudah berupa URL utuh
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => _fallbackImage());
    } 
    
    // Jika path dari Laravel storage (misal: 'menus/ayam.jpg')
    String fullUrl = 'http://10.0.2.2:8000/storage/$imagePath';
    return Image.network(fullUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => _fallbackImage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF9E596), 
        onPressed: () => _navigateAndRefresh(null),
        icon: const Icon(Icons.add, color: Colors.black87, size: 18),
        label: Text("Add New Menu", style: GoogleFonts.sora(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
          : menus.isEmpty
              ? Center(child: Text("Belum ada menu", style: GoogleFonts.sora(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final menu = menus[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF5),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, spreadRadius: 1)],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            // Mengambil image dari key 'image' sesuai migration
                            child: _buildMenuImage(menu['image']),
                          ),
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(menu['name'] ?? 'Nama Menu', style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (menu['category'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text(menu['category'], style: GoogleFonts.sora(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                      ),
                                    const SizedBox(width: 8),
                                    if (menu['is_recommended'] == 1 || menu['is_recommended'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text("Recommended", style: GoogleFonts.sora(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Rp ${menu['price'] ?? 0}", style: GoogleFonts.sora(fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                          ),
                          
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _navigateAndRefresh(menu),
                                    child: Icon(Icons.edit, color: Colors.orange[400], size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _deleteMenu(menu['id']),
                                    child: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}