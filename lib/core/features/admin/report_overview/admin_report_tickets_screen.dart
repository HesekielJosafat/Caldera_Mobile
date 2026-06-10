import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportTicketsScreen extends StatefulWidget {
  const AdminReportTicketsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportTicketsScreen> createState() => _AdminReportTicketsScreenState();
}

class _AdminReportTicketsScreenState extends State<AdminReportTicketsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> tickets = [];
  bool isLoading = true;

  // Filter
  DateTime? _startDate;
  DateTime? _endDate;
  String _statusFilter = 'Semua Status';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => isLoading = true);
    // Sementara kita gunakan API getTickets yang sudah ada. 
    // Idealnya ada endpoint khusus report yang menerima filter tanggal.
    final data = await _apiService.getTickets();
    if (mounted) {
      setState(() {
        tickets = data;
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportExcel() async {
     // Ganti URL dengan endpoint export yang benar di Laravel Anda
    final Uri url = Uri.parse('${ApiService.baseUrl}/admin/reports/tickets/export');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka link export")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Metrik secara manual dari data (Sementara)
    int totalTickets = tickets.length;
    double totalIncome = tickets.fold(0.0, (sum, item) {
      double price = double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
    double avgPerTicket = totalTickets > 0 ? totalIncome / totalTickets : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Laporan Tiket Kolam", style: GoogleFonts.sora(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF14334C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // HEADER EXPORT
                // ==========================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF14334C), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 12),
                      Expanded(child: Text("Laporan Penjualan Tiket Kolam", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        onPressed: _exportExcel,
                        icon: const Icon(Icons.file_download, color: Colors.white, size: 16),
                        label: Text("Export", style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ==========================================
                // FILTER BAR
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("TANGGAL MULAI", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(_startDate == null ? "mm/dd/yyyy" : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}", style: GoogleFonts.sora(fontSize: 12)),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("TANGGAL SELESAI", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(_endDate == null ? "mm/dd/yyyy" : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}", style: GoogleFonts.sora(fontSize: 12)),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("STATUS TIKET", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                const SizedBox(height: 4),
                                Container(
                                  height: 35, padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true, value: _statusFilter,
                                      items: ['Semua Status', 'Aktif', 'Digunakan', 'Kadaluarsa'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.sora(fontSize: 12)))).toList(),
                                      onChanged: (v) => setState(() => _statusFilter = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C), minimumSize: const Size(0, 35)),
                              onPressed: () { /* TODO: Terapkan Filter ke API */ },
                              icon: const Icon(Icons.filter_alt, size: 14, color: Colors.white),
                              label: Text("Filter", style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ==========================================
                // METRIK CARDS
                // ==========================================
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, childAspectRatio: 2.0, mainAxisSpacing: 12, crossAxisSpacing: 12,
                  children: [
                    _buildMetricCard("TOTAL TIKET TERJUAL", totalTickets.toString(), const Color(0xFF2C3E50)),
                    _buildMetricCard("TOTAL TRANSAKSI", tickets.length.toString(), const Color(0xFF27AE60)), // Ganti logika jika beda
                    _buildMetricCard("TOTAL PENDAPATAN", "Rp $totalIncome", const Color(0xFFD35400)),
                    _buildMetricCard("RATA-RATA PER TIKET", "Rp ${avgPerTicket.toStringAsFixed(0)}", const Color(0xFF2980B9)),
                  ],
                ),
                const SizedBox(height: 16),

                // ==========================================
                // GRAFIK DUMMY (Mirip Web)
                // ==========================================
                Row(
                  children: [
                    Expanded(child: _buildPieChartCard()), // Grafik Penjualan per Jenis (Pie)
                    const SizedBox(width: 12),
                    Expanded(child: _buildLineChartCard()), // Grafik Tren Penjualan (Line)
                  ],
                ),
                const SizedBox(height: 20),

                // ==========================================
                // TABEL DATA TIKET
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF14334C), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("KODE TIKET", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("CUSTOMER", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("TOTAL HARGA", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("STATUS", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      tickets.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada data tiket")))
                        : ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            itemCount: tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = tickets[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(ticket['ticket_code'] ?? '-', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold))),
                                    Expanded(child: Text(ticket['customer_name'] ?? '-', style: GoogleFonts.sora(fontSize: 11), textAlign: TextAlign.center)),
                                    Expanded(child: Text("Rp ${ticket['total_amount'] ?? 0}", style: GoogleFonts.sora(fontSize: 11), textAlign: TextAlign.center)),
                                    Expanded(child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text(ticket['status']?.toUpperCase() ?? 'ACTIVE', style: GoogleFonts.sora(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                      ),
                                    )),
                                  ],
                                ),
                              );
                            },
                          )
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.sora(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Placeholder untuk Pie Chart
  Widget _buildPieChartCard() {
    return Container(
      height: 200, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Text("PENJUALAN PER JENIS", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: PieChart(PieChartData(
              sections: [
                PieChartSectionData(value: 60, color: const Color(0xFF14334C), title: 'D', radius: 40),
                PieChartSectionData(value: 30, color: Colors.green, title: 'A', radius: 40),
                PieChartSectionData(value: 10, color: const Color(0xFFD4AF37), title: 'K', radius: 40),
              ],
            )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF14334C), "Dewasa"), const SizedBox(width: 4),
              _buildLegendItem(Colors.green, "Anak"), const SizedBox(width: 4),
              _buildLegendItem(const Color(0xFFD4AF37), "Keluarga"),
            ],
          )
        ],
      ),
    );
  }

  // Placeholder untuk Line Chart
  Widget _buildLineChartCard() {
    return Container(
      height: 200, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Text("TREN PENJUALAN", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300), left: BorderSide(color: Colors.grey.shade300))),
              lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(2, 1.4), FlSpot(3, 3)], color: const Color(0xFF14334C), barWidth: 2, isCurved: true)],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [Container(width: 6, height: 6, color: color), const SizedBox(width: 2), Text(text, style: GoogleFonts.sora(fontSize: 8))]);
  }
}