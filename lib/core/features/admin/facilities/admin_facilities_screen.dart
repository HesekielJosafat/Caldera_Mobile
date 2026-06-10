import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';


class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> allTickets = [];
  List<dynamic> filteredTickets = [];
  bool isLoading = true;

  // Filter Variables (Menyesuaikan Web)
  String _statusFilter = 'Semua Status';
  String _paymentFilter = 'Semua Pembayaran';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => isLoading = true);
    final data = await _apiService.getTickets();
    if (mounted) {
      setState(() {
        allTickets = data.reversed.toList(); // Yang terbaru di atas
        _applyFilters();
        isLoading = false;
      });
    }
  }

  // LOGIKA FILTER MENGUBAH BAHASA INDONESIA KE VALUE DATABASE INGGRIS
  void _applyFilters() {
    setState(() {
      filteredTickets = allTickets.where((ticket) {
        // 1. Cek Status (DB: active, used, expired, cancelled)
        String dbStatus = (ticket['status'] ?? '').toString().toLowerCase();
        bool matchStatus = _statusFilter == 'Semua Status' ||
            (_statusFilter == 'Aktif' && dbStatus == 'active') ||
            (_statusFilter == 'Digunakan' && dbStatus == 'used') ||
            (_statusFilter == 'Kadaluarsa' && dbStatus == 'expired') ||
            (_statusFilter == 'Dibatalkan' && dbStatus == 'cancelled');

        // 2. Cek Pembayaran (DB: paid, unpaid)
        String dbPayment = (ticket['payment_status'] ?? '').toString().toLowerCase();
        bool matchPayment = _paymentFilter == 'Semua Pembayaran' ||
            (_paymentFilter == 'Lunas' && dbPayment == 'paid') ||
            (_paymentFilter == 'Belum Bayar' && dbPayment == 'unpaid');

        // 3. Cek Pencarian (Nama atau Kode Tiket)
        String name = (ticket['customer_name'] ?? '').toString().toLowerCase();
        String code = (ticket['ticket_code'] ?? '').toString().toLowerCase();
        bool matchSearch = _searchQuery.isEmpty || 
                           name.contains(_searchQuery.toLowerCase()) || 
                           code.contains(_searchQuery.toLowerCase());

        return matchStatus && matchPayment && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
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
                    // Dropdown Status
                    Expanded(
                      child: Container(
                        height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter, isExpanded: true,
                            items: ['Semua Status', 'Aktif', 'Digunakan', 'Kadaluarsa', 'Dibatalkan'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.sora(fontSize: 11)))).toList(),
                            onChanged: (v) { setState(() => _statusFilter = v!); _applyFilters(); },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown Pembayaran
                    Expanded(
                      child: Container(
                        height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _paymentFilter, isExpanded: true,
                            items: ['Semua Pembayaran', 'Lunas', 'Belum Bayar'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.sora(fontSize: 11)))).toList(),
                            onChanged: (v) { setState(() => _paymentFilter = v!); _applyFilters(); },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search Bar
                SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (v) { _searchQuery = v; _applyFilters(); },
                    style: GoogleFonts.sora(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau kode tiket...",
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
          // 2. DAFTAR TIKET KOLAM
          // ==========================================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
                : filteredTickets.isEmpty
                    ? Center(child: Text("Belum ada data tiket kolam", style: GoogleFonts.sora(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Bottom padding for FAB
                        itemCount: filteredTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = filteredTickets[index];
                          
                          // Mapping Data dari DB
                          String code = ticket['ticket_code'] ?? '-';
                          String name = ticket['customer_name'] ?? 'Guest';
                          String date = ticket['visit_date'] ?? '-';
                          String type = (ticket['ticket_type'] ?? 'adult').toString().toUpperCase();
                          int qty = int.tryParse(ticket['number_of_tickets']?.toString() ?? '0') ?? 0;
                          String total = ticket['total_amount']?.toString() ?? '0';
                          
                          String dbStatus = ticket['status'] ?? 'active';
                          String dbPayment = ticket['payment_status'] ?? 'unpaid';

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
                                // ROW 1: KODE & PAYMENT STATUS
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("#$code", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF14334C))),
                                    _buildPaymentBadge(dbPayment),
                                  ],
                                ),
                                const Divider(height: 24),
                                
                                // ROW 2: INFO CUSTOMER
                                Row(
                                  children: [
                                    CircleAvatar(backgroundColor: Colors.grey.shade200, radius: 18, child: const Icon(Icons.person, color: Colors.grey, size: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text("Kunjungan: $date", style: GoogleFonts.sora(fontSize: 11, color: Colors.grey.shade700)),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ROW 3: DETAIL TIKET
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFFFFFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Jenis Tiket", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)),
                                          Text("$type (x$qty)", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text("Total Harga", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)),
                                          Text("Rp $total", style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ROW 4: STATUS & AKSI
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatusBadge(dbStatus),
                                    // Tombol Aksi (Opsional, misal Hapus)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fungsi Hapus Tiket")));
                                      },
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER: Badge Pembayaran
  Widget _buildPaymentBadge(String payment) {
    bool isPaid = payment == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isPaid ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(
        isPaid ? "LUNAS" : "BELUM BAYAR", 
        style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.red.shade700)
      ),
    );
  }

  // WIDGET HELPER: Badge Status Tiket
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (status) {
      case 'used':
        bgColor = Colors.blue.shade50; textColor = Colors.blue.shade700; label = "DIGUNAKAN"; break;
      case 'expired':
        bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; label = "KADALUARSA"; break;
      case 'cancelled':
        bgColor = Colors.red.shade50; textColor = Colors.red.shade700; label = "DIBATALKAN"; break;
      case 'active':
      default:
        bgColor = Colors.green.shade50; textColor = Colors.green.shade700; label = "AKTIF"; break;
    }

    return Row(
      children: [
        Text("Status: ", style: GoogleFonts.sora(fontSize: 11, color: Colors.grey.shade700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
        ),
      ],
    );
  }
}