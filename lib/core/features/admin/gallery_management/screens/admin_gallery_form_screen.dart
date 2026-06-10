import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:caldera_app/core/services/api_service.dart';

class AdminGalleryFormScreen extends StatefulWidget {
  const AdminGalleryFormScreen({Key? key}) : super(key: key);

  @override
  State<AdminGalleryFormScreen> createState() => _AdminGalleryFormScreenState();
}

class _AdminGalleryFormScreenState extends State<AdminGalleryFormScreen> {
  final ApiService _apiService = ApiService();
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();

  String _mediaType = 'image'; // Default Tipe Media
  String? _parentType;
  bool _isFeatured = false;
  File? _selectedFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia() async {
    XFile? picked;
    
    // Pilih fungsi berdasarkan Tipe Media yang dipilih di dropdown
    if (_mediaType == 'video') {
      picked = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }

    if (picked != null) {
      setState(() => _selectedFile = File(picked!.path));
    }
  }

  Future<void> _saveGallery() async {
    if (_titleCtrl.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan File Media wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> payload = {
      'title': _titleCtrl.text,
      'type': _mediaType, // 'image' atau 'video'
      'category': _categoryCtrl.text,
      'sort_order': _sortCtrl.text,
      'description': _descCtrl.text,
      'is_featured': _isFeatured ? 1 : 0,
      // Tambahkan logic Parent ID di sini nanti jika diperlukan backend
    };

    bool success = await _apiService.createGallery(payload, _selectedFile!);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Media berhasil disimpan")));
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengupload media")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Tambah Gallery", style: GoogleFonts.sora(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF14334C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INFORMASI MEDIA", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                  const Divider(height: 30),
                  
                  _buildLabel("JUDUL GALLERY *"),
                  _buildTextField(_titleCtrl, "Masukkan judul"),
                  const SizedBox(height: 16),
                  
                  _buildLabel("TIPE MEDIA *"),
                  Container(
                    height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _mediaType,
                        items: const [
                          DropdownMenuItem(value: 'image', child: Text("Gambar")),
                          DropdownMenuItem(value: 'video', child: Text("Video")),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _mediaType = v!;
                            _selectedFile = null; // Reset file jika tipe diganti
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(_mediaType == 'image' ? "UPLOAD GAMBAR *" : "UPLOAD VIDEO *"),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300))),
                        onPressed: _pickMedia,
                        icon: Icon(_mediaType == 'video' ? Icons.videocam : Icons.image, size: 16),
                        label: Text("Choose File", style: GoogleFonts.sora(fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile == null ? "No file chosen" : _selectedFile!.path.split('/').last,
                          style: GoogleFonts.sora(fontSize: 12, color: _selectedFile == null ? Colors.grey : Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Preview (Hanya tampilkan jika Gambar, karena Video butuh player khusus)
                  if (_selectedFile != null && _mediaType == 'image')
                     Container(
                       margin: const EdgeInsets.only(top: 8), height: 80, width: 80,
                       decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)),
                     ),
                  
                  const SizedBox(height: 4),
                  Text(_mediaType == 'image' ? "Format: JPG, JPEG, PNG. Max: 2MB" : "Format: MP4. Max: 10MB", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 30),

                  Text("RELASI & KATEGORI", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                  const Divider(height: 30),
                  
                  // MENCEGAH OVERFLOW: Disusun ke bawah (Column) bukan Row
                  _buildLabel("TIPE PARENT *"),
                  Container(
                    height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text("Pilih Tipe", style: GoogleFonts.sora(fontSize: 13, color: Colors.grey)),
                        value: _parentType,
                        items: ['Menu', 'Event', 'Promo', 'Testimonial'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.sora(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _parentType = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel("PARENT ID (Opsional)"),
                  _buildTextField(TextEditingController(), "Pilih Parent ID / Kode"),
                  const SizedBox(height: 16),
                  
                  _buildLabel("KATEGORI"),
                  _buildTextField(_categoryCtrl, "Contoh: restaurant, pool, event"),
                  const SizedBox(height: 16),
                  
                  _buildLabel("SORT ORDER"),
                  _buildTextField(_sortCtrl, "0"),
                  const SizedBox(height: 16),
                  
                  _buildLabel("DESKRIPSI"),
                  TextField(
                    controller: _descCtrl, maxLines: 4, style: GoogleFonts.sora(fontSize: 13),
                    decoration: InputDecoration(hintText: "Tulis deskripsi...", hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.all(12)),
                  ),
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: Text("Jadikan Featured", style: GoogleFonts.sora(fontSize: 13)),
                    value: _isFeatured,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF14334C),
                    onChanged: (v) => setState(() => _isFeatured = v!),
                  ),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: GoogleFonts.sora(color: Colors.grey.shade700))),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _saveGallery,
                        icon: const Icon(Icons.save, size: 16, color: Colors.white),
                        label: Text("Simpan", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700)));
  
  Widget _buildTextField(TextEditingController ctrl, String hint) => SizedBox(
    height: 45,
    child: TextField(
      controller: ctrl, style: GoogleFonts.sora(fontSize: 13),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
    ),
  );
}