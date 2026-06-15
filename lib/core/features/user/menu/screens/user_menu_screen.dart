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

class _UserMenuScreenState extends State<UserMenuScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  List<dynamic> menuItems = [];
  bool isLoading = true;

  // Filter Kategori (Mobile Style)
  String selectedCategory = "All";
  final List<String> categories = ["All", "Makanan", "Minuman", "Dessert"];

  // Controller untuk search bar lokal
  final TextEditingController _localSearchController = TextEditingController();
  String localSearchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Daftarkan Observer
    _fetchMenuFromApi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Cabut Observer
    _localSearchController.dispose();
    super.dispose();
  }

  // AUTO-REFRESH SAAT APP DIBUKA KEMBALI DARI BACKGROUND
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMenuFromApi();
    }
  }

  // FUNGSI MENGAMBIL DATA DARI API
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
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

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
        // ==========================================
        // 1. MOBILE NATIVE SEARCH BAR
        // ==========================================
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 10),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _localSearchController,
              onChanged: (value) => setState(() => localSearchQuery = value),
              style: GoogleFonts.sora(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Cari menu favoritmu...",
                hintStyle: GoogleFonts.sora(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                // Tombol silang (clear) muncul jika ada teks
                suffixIcon: localSearchQuery.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 18),
                      onPressed: () {
                        _localSearchController.clear();
                        setState(() => localSearchQuery = "");
                      },
                    )
                  : null,
              ),
            ),
          ),
        ),

        // ==========================================
        // 2. MOBILE NATIVE CATEGORY CHIPS
        // ==========================================
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: GoogleFonts.sora(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() => selectedCategory = category);
                    },
                    selectedColor: primaryNavy,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? primaryNavy : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false, // Sembunyikan centang default
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Sedikit bayangan di bawah header pencarian
        Container(height: 1, color: Colors.grey.shade200),

        // ==========================================
        // 3. LIST MENU (CARD HORIZONTAL)
        // ==========================================
        Expanded(
          child: RefreshIndicator(
            color: activeGold,
            onRefresh: _fetchMenuFromApi, 
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryNavy))
                : filteredMenu.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("Menu tidak ditemukan", style: GoogleFonts.sora(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: filteredMenu.length,
                        itemBuilder: (context, index) {
                          final item = filteredMenu[index];
                          
                          final String namaMenu = item['name'] ?? 'Nama Menu';
                          final String hargaMenu = item['price']?.toString() ?? '0';
                          final String descMenu = item['description'] ?? '';
                          final bool isRecommended = item['is_recommended'] == 1 || item['is_recommended'] == true;

                          // MERAKIT URL GAMBAR
                          String imageUrl = item['image_url'] ?? item['image'] ?? '';
                          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                            imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imageUrl';
                          }

                          return _buildMobileCard(
                            namaMenu: namaMenu,
                            hargaMenu: hargaMenu,
                            imageUrl: imageUrl,
                            descMenu: descMenu,
                            isRecommended: isRecommended,
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DESAIN KARTU MENU ALA G0FOOD/GRABFOOD
  // ==========================================
  Widget _buildMobileCard({
    required String namaMenu,
    required String hargaMenu,
    required String imageUrl,
    required String descMenu,
    required bool isRecommended,
  }) {
    const Color activeGold = Color(0xFFD4AF37);
    const Color primaryNavy = Color(0xFF14334C);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THUMBNAIL GAMBAR KIRI
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _fallbackImage(),
                    )
                  : _fallbackImage(),
            ),
            
            const SizedBox(width: 16),
            
            // 2. KONTEN TEKS KANAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Menu
                  Text(
                    namaMenu,
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: Colors.black87
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Deskripsi
                  if (descMenu.isNotEmpty)
                    Text(
                      descMenu,
                      style: GoogleFonts.sora(
                        color: Colors.grey.shade600, 
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Harga dan Badge Recommended
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rp ${formatCurrency(hargaMenu)}",
                        style: GoogleFonts.sora(
                          color: primaryNavy,
                          fontWeight: FontWeight.bold, 
                          fontSize: 13
                        ),
                      ),
                      
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: activeGold.withOpacity(0.5))
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: activeGold, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                "Recommended",
                                style: GoogleFonts.sora(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 30),
      ),
    );
  }
}