import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportIncomeScreen extends StatefulWidget {
  const AdminReportIncomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportIncomeScreen> createState() => _AdminReportIncomeScreenState();
}

class _AdminReportIncomeScreenState extends State<AdminReportIncomeScreen> {
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  
  double totalTicketIncome = 0;
  double totalReservationDP = 0;

  DateTime? _startDate;
  DateTime? _endDate;
  String _typeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchIncomeData();
  }

  Future<void> _fetchIncomeData() async {
    setState(() => isLoading = true);
    
    // Ambil data tiket dan reservasi untuk menghitung total pendapatan
    final tickets = await _apiService.getTickets();
    final reservations = await _apiService.getReservations();
    
    if (mounted) {
      setState(() {
        totalTicketIncome = tickets.fold(0.0, (sum, t) => sum + (double.tryParse(t['total_amount']?.toString() ?? '0') ?? 0));
        totalReservationDP = reservations.fold(0.0, (sum, r) => sum + (double.tryParse(r['down_payment']?.toString() ?? '0') ?? 0));
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() { isStart ? _startDate = picked : _endDate = picked; });
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = totalTicketIncome + totalReservationDP;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text("Laporan Pemasukan", style: GoogleFonts.sora(color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF14334C), iconTheme: const IconThemeData(color: Colors.white)),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF14334C)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF14334C), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFFD4AF37)), const SizedBox(width: 12),
                      Expanded(child: Text("Laporan Pemasukan", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        onPressed: () {}, icon: const Icon(Icons.file_download, color: Colors.white, size: 16), label: Text("Export", style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // FILTER BAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDatePicker("TANGGAL MULAI", _startDate, true)), const SizedBox(width: 12),
                          Expanded(child: _buildDatePicker("TANGGAL SELESAI", _endDate, false)),
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
                                Text("TIPE TRANSAKSI", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)), const SizedBox(height: 4),
                                Container(
                                  height: 35, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true, value: _typeFilter,
                                      items: ['Semua', 'Down Payment (Reservasi)', 'Full Payment (Tiket)'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.sora(fontSize: 12)))).toList(),
                                      onChanged: (v) => setState(() => _typeFilter = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C), minimumSize: const Size(0, 35)), onPressed: () {}, icon: const Icon(Icons.filter_alt, size: 14, color: Colors.white), label: Text("Filter", style: GoogleFonts.sora(color: Colors.white, fontSize: 12))))
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // METRIK CARDS
                Row(
                  children: [
                    Expanded(child: _buildMetricCard("TOTAL PEMASUKAN", "Rp ${totalIncome.toStringAsFixed(0)}", const Color(0xFF2C3E50))), const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard("DARI TIKET KOLAM", "Rp ${totalTicketIncome.toStringAsFixed(0)}", const Color(0xFF27AE60))), const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard("DARI RESERVASI", "Rp ${totalReservationDP.toStringAsFixed(0)}", const Color(0xFF2980B9))),
                  ],
                ),
                const SizedBox(height: 20),

                // GRAFIK DUMMY (Perbandingan & Tren)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 200, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(children: [
                          Text("PERBANDINGAN PEMASUKAN", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                          Expanded(child: PieChart(PieChartData(sections: [PieChartSectionData(value: totalTicketIncome, color: Colors.green, title: '', radius: 30), PieChartSectionData(value: totalReservationDP, color: Colors.blue, title: '', radius: 30)]))),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 200, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(children: [
                          Text("TREN PEMASUKAN HARIAN", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                          Expanded(child: LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: true), lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 100), FlSpot(1, 300)], color: Colors.orange)]))),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // TABEL DATA
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF14334C), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text("NO", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(child: Text("TANGGAL", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(child: Text("TIPE", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(child: Text("JUMLAH", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      const Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada data pemasukan")), // Placeholder
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }

  // (Helper function _buildDatePicker & _buildMetricCard sama dengan file sebelumnya)
  Widget _buildDatePicker(String label, DateTime? date, bool isStart) { /*... sama ...*/ return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)), const SizedBox(height: 4), InkWell(onTap: () => _selectDate(context, isStart), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(date == null ? "mm/dd/yyyy" : "${date.day}/${date.month}/${date.year}", style: GoogleFonts.sora(fontSize: 12)), const Icon(Icons.calendar_today, size: 16, color: Colors.grey)])))]); }
  Widget _buildMetricCard(String title, String value, Color bgColor) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: GoogleFonts.sora(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))])); }
}