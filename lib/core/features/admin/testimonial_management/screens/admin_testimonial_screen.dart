import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';

class AdminTestimonialScreen extends StatefulWidget {
  const AdminTestimonialScreen({Key? key}) : super(key: key);

  @override
  State<AdminTestimonialScreen> createState() => _AdminTestimonialScreenState();
}

class _AdminTestimonialScreenState extends State<AdminTestimonialScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> allTestimonials = [];
  List<dynamic> filteredTestimonials = [];
  bool isLoading = true;

  // Filter Variables
  String _statusFilter = 'Semua Status';
  String _ratingFilter = 'Semua Rating';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTestimonials();
  }

  Future<void> _fetchTestimonials() async {
    setState(() => isLoading = true);
    final data = await _apiService.getTestimonials(); 
    if (mounted) {
      setState(() {
        allTestimonials = data;
        _applyFilters();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTestimonials = allTestimonials.where((item) {
        // Filter Status (0 = Pending, 1 = Disetujui)
        bool isApproved = item['is_approved'] == 1 || item['is_approved'] == true;
        bool matchesStatus = true;
        if (_statusFilter == 'Disetujui') matchesStatus = isApproved;
        if (_statusFilter == 'Pending') matchesStatus = !isApproved;

        // Filter Rating
        int rating = int.tryParse(item['rating']?.toString() ?? '0') ?? 0;
        bool matchesRating = true;
        if (_ratingFilter != 'Semua Rating') {
          int targetRating = int.parse(_ratingFilter.split(' ')[0]);
          matchesRating = rating == targetRating;
        }

        // Filter Pencarian Text
        String name = (item['customer_name'] ?? '').toString().toLowerCase();
        String comment = (item['comment'] ?? '').toString().toLowerCase();
        bool matchesSearch = _searchQuery.isEmpty || 
                             name.contains(_searchQuery.toLowerCase()) || 
                             comment.contains(_searchQuery.toLowerCase());

        return matchesStatus && matchesRating && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteTestimonial(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Testimoni", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus testimoni ini secara permanen?", style: GoogleFonts.sora(fontSize: 13)),
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
      
      // Memanggil fungsi API asli yang sudah ditambahkan di ApiService
      bool success = await _apiService.deleteTestimonial(id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Testimoni berhasil dihapus")));
          _fetchTestimonials();
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus testimoni")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==========================================
        // 1. FILTER & SEARCH BAR (Mirip Web)
        // ==========================================
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter, isExpanded: true,
                          items: ['Semua Status', 'Disetujui', 'Pending'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.sora(fontSize: 11)))).toList(),
                          onChanged: (v) { setState(() => _statusFilter = v!); _applyFilters(); },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _ratingFilter, isExpanded: true,
                          items: ['Semua Rating', '5 Bintang', '4 Bintang', '3 Bintang', '2 Bintang', '1 Bintang'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.sora(fontSize: 11)))).toList(),
                          onChanged: (v) { setState(() => _ratingFilter = v!); _applyFilters(); },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (v) { _searchQuery = v; _applyFilters(); },
                  style: GoogleFonts.sora(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "Cari nama atau komentar...",
                    hintStyle: GoogleFonts.sora(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // 2. DAFTAR TESTIMONI
        // ==========================================
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
              : filteredTestimonials.isEmpty
                  ? Center(child: Text("Tidak ada testimoni yang sesuai", style: GoogleFonts.sora(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTestimonials.length,
                      itemBuilder: (context, index) {
                        final item = filteredTestimonials[index];
                        final bool isApproved = item['is_approved'] == 1 || item['is_approved'] == true;
                        final bool isFeatured = item['is_featured'] == 1 || item['is_featured'] == true;
                        final int rating = int.tryParse(item['rating']?.toString() ?? '0') ?? 0;
                        final String name = item['customer_name'] ?? 'Guest';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF14334C),
                                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
                                      ],
                                    ),
                                  ),
                                  if (item['visit_date'] != null || item['created_at'] != null)
                                    Text(
                                      (item['visit_date'] ?? item['created_at']).toString().split('T')[0], 
                                      style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('"${item['comment'] ?? ''}"', style: GoogleFonts.sora(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                              const SizedBox(height: 16),
                              
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  if (item['service_type'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text(item['service_type'].toString().toUpperCase(), style: GoogleFonts.sora(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: isApproved ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Text(isApproved ? "DISETUJUI" : "PENDING", style: GoogleFonts.sora(fontSize: 9, color: isApproved ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isFeatured)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Row(children: [
                                        const Icon(Icons.star, size: 10, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text("FEATURED", style: GoogleFonts.sora(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                                      ]),
                                    ),
                                  
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteTestimonial(item['id']),
                                  ),
                                ],
                              ),
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