import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'admin_gallery_form_screen.dart';

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({Key? key}) : super(key: key);

  @override
  State<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> galleries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
  }

  Future<void> _fetchGalleries() async {
    setState(() => isLoading = true);
    final data = await _apiService.getGallery();
    if (mounted) {
      setState(() {
        galleries = data;
        isLoading = false;
      });
    }
  }

  void _openGalleryForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminGalleryFormScreen()),
    );
    if (result == true) {
      _fetchGalleries();
    }
  }

  Future<void> _deleteGallery(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Media", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus item ini?", style: GoogleFonts.sora()),
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
      bool success = await _apiService.deleteGallery(id);
      if (success) {
        _fetchGalleries();
      } else {
        setState(() => isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TOMBOL + NEW GALLERY
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: _openGalleryForm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9E596), 
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              ),
              child: Center(
                // PERUBAHAN TEKS DISINI
                child: Text("+ New Gallery", style: GoogleFonts.sora(fontWeight: FontWeight.bold))
              ),
            ),
          ),
        ),

        // DAFTAR GALLERY
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
              : galleries.isEmpty
                  ? Center(child: Text("Belum ada data gallery", style: GoogleFonts.sora(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 16, 
                        mainAxisSpacing: 16, 
                        childAspectRatio: 0.85,
                      ),
                      itemCount: galleries.length,
                      itemBuilder: (context, index) {
                        final item = galleries[index];
                        String fileUrl = item['file_path'] ?? '';
                        if (!fileUrl.startsWith('http')) {
                          fileUrl = 'http://10.0.2.2:8000/storage/$fileUrl';
                        }
                        
                        // Cek apakah item ini video atau gambar
                        bool isVideo = item['type'] == 'video';
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(12), 
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: isVideo 
                                    // Jika Video, tampilkan ikon Video besar sebagai placeholder 
                                    // (karena load thumbnail video butuh plugin berat spt video_thumbnail)
                                    ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50)))
                                    // Jika Gambar, load gambarnya
                                    : Image.network(
                                        fileUrl, 
                                        fit: BoxFit.cover, 
                                        width: double.infinity, 
                                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? 'Tanpa Judul', 
                                        style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _deleteGallery(item['id']),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}