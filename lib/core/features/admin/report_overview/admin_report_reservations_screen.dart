import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportReservationsScreen extends StatefulWidget {
  const AdminReportReservationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportReservationsScreen> createState() => _AdminReportReservationsScreenState();
}

class _AdminReportReservationsScreenState extends State<AdminReportReservationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> reservations = [];
  bool isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;
  String _statusFilter = 'Semua Status';

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
        reservations = data;
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { isStart ? _startDate = picked : _endDate = picked; });
    }
  }

  Future<void> _exportExcel() async {
    final Uri url = Uri.parse('${ApiService.baseUrl}/admin/reports/reservations/export');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka link export")));
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalRes = reservations.length;
    int confirmedRes = reservations.where((r) => r['status'] == 'confirmed').length;
    int pendingRes = reservations.where((r) => r['status'] == 'pending').length;
    int totalGuests = reservations.fold(0, (sum, item) => sum + (int.tryParse(item['number_of_guests']?.toString() ?? '0') ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text("Laporan Reservasi", style: GoogleFonts.sora(color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF14334C), iconTheme: const IconThemeData(color: Colors.white)),
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
                      const Icon(Icons.calendar_today, color: Color(0xFFD4AF37)), const SizedBox(width: 12),
                      Expanded(child: Text("Laporan Reservasi Meja", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        onPressed: _exportExcel, icon: const Icon(Icons.file_download, color: Colors.white, size: 16),
                        label: Text("Export Excel", style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
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
                          Expanded(child: _buildDatePicker("TANGGAL MULAI", _startDate, true)),
                          const SizedBox(width: 12),
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
                                Text("STATUS", style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)), const SizedBox(height: 4),
                                Container(
                                  height: 35, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true, value: _statusFilter,
                                      items: ['Semua Status', 'Pending', 'Confirmed', 'Completed', 'Cancelled'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.sora(fontSize: 12)))).toList(),
                                      onChanged: (v) => setState(() => _statusFilter = v!),
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
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.0, mainAxisSpacing: 12, crossAxisSpacing: 12,
                  children: [
                    _buildMetricCard("TOTAL RESERVASI", totalRes.toString(), const Color(0xFF2C3E50)),
                    _buildMetricCard("CONFIRMED", confirmedRes.toString(), const Color(0xFF27AE60)),
                    _buildMetricCard("PENDING", pendingRes.toString(), const Color(0xFFD35400)),
                    _buildMetricCard("TOTAL TAMU", totalGuests.toString(), const Color(0xFF2980B9)),
                  ],
                ),
                const SizedBox(height: 20),

                // GRAFIK DUMMY
                Container(
                  height: 250, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(children: [
                    Text("Jumlah Reservasi (Dummy)", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
                    Expanded(child: LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: true), lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 2)], color: const Color(0xFF14334C))]))),
                  ]),
                ),
                const SizedBox(height: 20),

                // TABEL DATA
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF14334C), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("KODE", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(child: Text("CUSTOMER", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(child: Text("TANGGAL", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            Text("STATUS", style: GoogleFonts.sora(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      reservations.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada data reservasi"))) : ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final res = reservations[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(res['booking_code'] ?? '-', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(child: Text(res['customer_name'] ?? '-', style: GoogleFonts.sora(fontSize: 11))),
                                Expanded(child: Text(res['reservation_date'] ?? '-', style: GoogleFonts.sora(fontSize: 11))),
                                Text(res['status']?.toUpperCase() ?? 'PENDING', style: GoogleFonts.sora(fontSize: 9, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
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

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)), const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(date == null ? "mm/dd/yyyy" : "${date.day}/${date.month}/${date.year}", style: GoogleFonts.sora(fontSize: 12)), const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.sora(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
          Text(value, style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}