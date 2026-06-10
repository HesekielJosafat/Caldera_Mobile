import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:caldera_app/core/services/api_service.dart';

class AdminMenuFormScreen extends StatefulWidget {
  final Map<String, dynamic>? menu; 

  const AdminMenuFormScreen({Key? key, this.menu}) : super(key: key);

  @override
  State<AdminMenuFormScreen> createState() => _AdminMenuFormScreenState();
}

class _AdminMenuFormScreenState extends State<AdminMenuFormScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _sortOrderCtrl;

  String? _selectedCategory;
  bool _isAvailable = true;
  bool _isRecommended = false;

  final List<String> _categories = ['Makanan', 'Minuman', 'Dessert'];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.menu != null;

    _nameCtrl = TextEditingController(text: isEdit ? widget.menu!['name'] : '');
    // Hapus desimal nol berlebih jika ada
    _priceCtrl = TextEditingController(text: isEdit ? double.parse(widget.menu!['price'].toString()).toInt().toString() : '');
    _descCtrl = TextEditingController(text: isEdit ? (widget.menu!['description'] ?? '') : '');
    _sortOrderCtrl = TextEditingController(text: isEdit ? (widget.menu!['sort_order'] ?? '0').toString() : '0');

    if (isEdit && _categories.contains(widget.menu!['category'])) {
      _selectedCategory = widget.menu!['category'];
    }
    
    _isAvailable = isEdit ? (widget.menu!['is_available'] == 1 || widget.menu!['is_available'] == true) : true;
    _isRecommended = isEdit ? (widget.menu!['is_recommended'] == 1 || widget.menu!['is_recommended'] == true) : false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() { _selectedImage = File(pickedFile.path); });
    }
  }

  Future<void> _saveMenu() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi field yang wajib (*)")));
      return;
    }

    setState(() => _isLoading = true);

    // Kunci Payload JSON disesuaikan persis dengan Migrasi Anda
    Map<String, dynamic> payload = {
      'name': _nameCtrl.text,
      'category': _selectedCategory,
      'price': _priceCtrl.text,
      'description': _descCtrl.text,
      'is_available': _isAvailable ? 1 : 0,
      'is_recommended': _isRecommended ? 1 : 0,
      'sort_order': _sortOrderCtrl.text,
    };

    bool success = widget.menu != null
        ? await _apiService.updateMenu(widget.menu!['id'], payload, imageFile: _selectedImage)
        : await _apiService.createMenu(payload, imageFile: _selectedImage);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.menu != null ? "Menu diupdate" : "Menu ditambahkan")));
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan data")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14334C),
        title: Text(widget.menu != null ? "Edit Menu" : "Add New Menu", style: GoogleFonts.sora(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.menu != null ? "Edit Menu Data" : "+ Add New Menu", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF14334C))),
                    const Divider(height: 30),

                    _buildLabel("Menu Name *"),
                    _buildTextField(_nameCtrl, "Enter menu name"),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Category *"),
                              Container(
                                height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text("Select", style: GoogleFonts.sora(fontSize: 13, color: Colors.grey)),
                                    value: _selectedCategory,
                                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.sora(fontSize: 13)))).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Price *"),
                              _buildTextField(_priceCtrl, "Rp", isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Description *"),
                    TextField(
                      controller: _descCtrl, maxLines: 4, style: GoogleFonts.sora(fontSize: 13),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.all(12)),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Menu Image"),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300))),
                          onPressed: _pickImage,
                          child: Text("Choose File", style: GoogleFonts.sora(fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedImage != null ? _selectedImage!.path.split('/').last : "No file chosen", 
                            style: GoogleFonts.sora(fontSize: 12, color: _selectedImage != null ? Colors.blue : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null)
                       Container(
                         margin: const EdgeInsets.only(top: 8), height: 80, width: 80,
                         decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)),
                       ),
                    
                    const SizedBox(height: 4),
                    Text("Ukuran rekomendasi: 500x500px", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: CheckboxListTile(title: Text("Available", style: GoogleFonts.sora(fontSize: 13)), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v!), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: const Color(0xFF14334C))),
                        Expanded(child: CheckboxListTile(title: Text("Recommended", style: GoogleFonts.sora(fontSize: 13)), value: _isRecommended, onChanged: (v) => setState(() => _isRecommended = v!), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: const Color(0xFF14334C))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Sort Order"),
                    _buildTextField(_sortOrderCtrl, "0", isNumber: true),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.sora(color: Colors.grey.shade700))),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: _saveMenu,
                          icon: const Icon(Icons.save, size: 16, color: Colors.white),
                          label: Text("Save Menu", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 13)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, style: GoogleFonts.sora(fontSize: 13),
        decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
      ),
    );
  }
}