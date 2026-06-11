import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';

class UserMenuScreen extends StatefulWidget {
  final String searchQuery;
  const UserMenuScreen({Key? key, this.searchQuery = ""}) : super(key: key);

  @override
  State<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> menuItems = [];
  bool isLoading = true;

  // Filter Kategori (Web Style)
  String selectedCategory = "All";
  final List<String> categories = ["All", "Makanan", "Minuman", "Dessert"];

  // Controller untuk search bar lokal
  final TextEditingController _localSearchController = TextEditingController();
  String localSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchMenuFromApi();
  }

  // FUNGSI MENGAMBIL DATA DARI WEB
  Future<void> _fetchMenuFromApi() async {
    try {
      final List<dynamic> data = await _apiService.getMenus();
      if (mounted) {
        setState(() {
          menuItems = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Error fetching menus: $e");
    }
  }

  // Helper untuk format harga
  String formatCurrency(String priceString) {
    try {
      double price = double.parse(priceString);
      final formatter = NumberFormat('#,###', 'id_ID');
      return formatter.format(price);
    } catch (e) {
      return priceString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF1B3B5A);

    // Menggabungkan search dari parent dan lokal
    String activeSearch = localSearchQuery.isNotEmpty ? localSearchQuery : widget.searchQuery;

    // Filter berdasarkan Pencarian DAN Kategori
    List<dynamic> filteredMenu = menuItems.where((item) {
      final namaMenu = item['name']?.toString().toLowerCase() ?? '';
      final itemCategory = item['category']?.toString().toLowerCase() ?? '';
      
      final matchesSearch = namaMenu.contains(activeSearch.toLowerCase());
      final matchesCategory = selectedCategory == "All" || 
                              itemCategory == selectedCategory.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Expanded(
          // BUNGKUS DENGAN REFRESH INDICATOR UNTUK PULL-TO-REFRESH DI HALAMAN MENU
          child: RefreshIndicator(
            color: primaryNavy,
            onRefresh: _fetchMenuFromApi, // Pemicu ambil data baru
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Memaksa agar tetap bisa ditarik ke bawah
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // 1. JUDUL & SUBJUDUL ALA WEB
                  Text(
                    "Our Menu",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 3,
                    color: const Color(0xFFC49A45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Discover our delicious selection of food and beverages",
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // 2. SEARCH BAR ALA WEB
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: TextField(
                        controller: _localSearchController,
                        onChanged: (value) => setState(() => localSearchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search menu...",
                          hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. TABS KATEGORI KAPSUL (WEB STYLE)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => selectedCategory = category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryNavy : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected ? primaryNavy : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.sora(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. LIST KARTU MENU
                  isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: primaryNavy),
                        )
                      : filteredMenu.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text("Menu tidak ditemukan", style: GoogleFonts.sora(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredMenu.length,
                              itemBuilder: (context, index) {
                                final item = filteredMenu[index];
                                
                                final String namaMenu = item['name'] ?? 'Nama Menu';
                                final String hargaMenu = item['price']?.toString() ?? '0';
                                
                                // 👇 1. PERBAIKAN: MERAKIT PATH GAMBAR MENJADI URL UTUH DARI HOSTING 👇
                                String imageUrl = item['image_url'] ?? item['image'] ?? '';
                                if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                                  imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imageUrl';
                                }

                                final String descMenu = item['description'] ?? '';
                                final bool isRecommended = item['is_recommended'] == 1 || item['is_recommended'] == true;

                                return _buildWebStyleCard(
                                  namaMenu: namaMenu,
                                  hargaMenu: hargaMenu,
                                  imageUrl: imageUrl, // Kirim URL utuh
                                  descMenu: descMenu,
                                  isRecommended: isRecommended,
                                );
                              },
                            ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DESAIN KARTU MENU (Sama Persis Seperti Web)
  Widget _buildWebStyleCard({
    required String namaMenu,
    required String hargaMenu,
    required String imageUrl,
    required String descMenu,
    required bool isRecommended,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Menu
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
          
          // Konten Teks
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        namaMenu,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: const Color(0xFF1B3B5A)
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Rp ${formatCurrency(hargaMenu)}",
                      style: GoogleFonts.sora(
                        color: const Color(0xFFC49A45),
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (descMenu.isNotEmpty)
                  Text(
                    descMenu,
                    style: GoogleFonts.sora(
                      color: Colors.grey.shade600, 
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                
                if (isRecommended) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade100)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFC49A45), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "Recommended",
                          style: GoogleFonts.sora(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, color: Colors.grey.shade300, size: 50),
          const SizedBox(height: 8),
          Text("No Image Available", style: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 12))
        ],
      ),
    );
  }
}