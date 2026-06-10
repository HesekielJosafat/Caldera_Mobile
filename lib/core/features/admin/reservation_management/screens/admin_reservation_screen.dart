import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'dart:io'; // Untuk class File dan Directory
import 'package:path_provider/path_provider.dart'; // Untuk getApplicationDocumentsDirectory
import 'package:open_filex/open_filex.dart'; // Untuk OpenFilex


class AdminReservationScreen extends StatefulWidget {
  const AdminReservationScreen({Key? key}) : super(key: key);

  @override
  State<AdminReservationScreen> createState() => _AdminReservationScreenState();
}

class _AdminReservationScreenState extends State<AdminReservationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> allReservations = [];
  List<dynamic> filteredReservations = [];
  bool isLoading = true;

  String _statusFilter = 'Semua Status';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() => isLoading = true);
    final data = await _apiService.getReservations();
    if (mounted) {
      setState(() {
        allReservations = data.reversed.toList();
        _applyFilter();
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      filteredReservations = allReservations.where((res) {
        bool matchesStatus = _statusFilter == 'Semua Status' || 
                             (res['status'] ?? '').toString().toLowerCase() == _statusFilter.toLowerCase();
        bool matchesSearch = _searchQuery.isEmpty || 
                             (res['customer_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             (res['booking_code'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  // Fungsi Export
    Future<void> _exportData() async {
  setState(() => isLoading = true);
  
    try {
      final bytes = await _apiService.downloadExportedFile(_apiService.getExportReservationsUrl());
      
      if (bytes != null) {
        // Dapatkan path dokumen aplikasi (ini paling aman di Android)
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/Reservasi_Caldera_${DateTime.now().millisecondsSinceEpoch}.xlsx');
        
        await file.writeAsBytes(bytes);
        
        setState(() => isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil diunduh: ${file.path}")));
          // Buka filenya
          await OpenFilex.open(file.path);
        }
      } else {
        throw Exception("Data kosong");
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengunduh file")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FILTER & EXPORT BAR (Mirroring Web)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          items: ['Semua Status', 'Pending', 'Confirmed', 'Cancelled', 'Completed']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.sora(fontSize: 12)))).toList(),
                          onChanged: (v) { setState(() => _statusFilter = v!); _applyFilter(); },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: _exportData,
                    icon: const Icon(Icons.file_download, size: 16),
                    label: Text("Export", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) { _searchQuery = v; _applyFilter(); },
                decoration: InputDecoration(
                  hintText: "Cari nama atau kode booking...",
                  hintStyle: GoogleFonts.sora(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10)
                ),
              ),
            ],
          ),
        ),
        
        // LIST RESERVASI
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
            : filteredReservations.isEmpty
              ? Center(child: Text("Belum ada data reservasi", style: GoogleFonts.sora(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReservations.length,
                  itemBuilder: (context, index) {
                    final res = filteredReservations[index];
                    String status = (res['status'] ?? 'pending').toString().toLowerCase();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("#${res['booking_code'] ?? 'N/A'}", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF14334C))),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const Divider(),
                          Text(res['customer_name'] ?? '-', style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Date: ${res['reservation_date']} | Guests: ${res['number_of_guests']}", style: GoogleFonts.sora(fontSize: 12)),
                          
                          if (status == 'pending') ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(onPressed: () {}, child: Text("Decline", style: GoogleFonts.sora(fontSize: 11))),
                                const SizedBox(width: 8),
                                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C)), child: Text("Accept", style: GoogleFonts.sora(fontSize: 11, color: Colors.white))),
                              ],
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'cancelled' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}