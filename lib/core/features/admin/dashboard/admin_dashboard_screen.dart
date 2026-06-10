import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:caldera_app/core/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final data = await _apiService.getAdminDashboard();
    if (mounted) {
      setState(() {
        stats = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF14334C))));

    final quickStats = (stats['quick_stats'] as Map<String, dynamic>? ?? {});
    final recentRes = (stats['recent_reservations'] as List? ??[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // MENGGUNAKAN SCROLL CONFIGURATION UNTUK MEMATIKAN EFEK MEREGANG/MELAR (ANDROID 12+)
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              // 1. CARDS METRIK
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, childAspectRatio: 1.6, mainAxisSpacing: 10, crossAxisSpacing: 10,
                children:[
                  _buildStatCard("Today's Res.", (stats['today_reservations'] ?? 0).toString(), Colors.blue, Icons.calendar_today),
                  _buildStatCard("Today's Tickets", (stats['today_tickets'] ?? 0).toString(), Colors.green, Icons.confirmation_number),
                  _buildStatCard("Income", "Rp ${(stats['today_income'] ?? 0)}", Colors.amber, Icons.attach_money),
                  _buildStatCard("Pending", (stats['pending_reservations'] ?? 0).toString(), Colors.red, Icons.access_time),
                ],
              ),
              const SizedBox(height: 20),

              // 2. GRAFIK PROFESIONAL
              if (stats['chart'] != null) _buildProfessionalChart(stats['chart']),

              const SizedBox(height: 20),
              
              // 3. SYSTEM OVERVIEW
              Text("System Overview", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _buildListTile("Total Menus", (quickStats['total_menus'] ?? 0).toString(), Icons.restaurant),
              _buildListTile("Active Promos", (quickStats['active_promos'] ?? 0).toString(), Icons.local_offer),
              _buildListTile("Pending Testimonials", (quickStats['pending_testimonials'] ?? 0).toString(), Icons.comment),
              _buildListTile("Gallery Items", (quickStats['gallery_items'] ?? 0).toString(), Icons.photo_library),
              
              const SizedBox(height: 20),
              
              // 4. RECENT RESERVATIONS
              Text("Recent Reservations", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              recentRes.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No recent reservations")))
                : Column(
                    children: recentRes.map((res) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF14334C)),
                        title: Text(res['customer_name'] ?? 'Guest', style: GoogleFonts.sora(fontSize: 14)),
                        subtitle: Text(res['reservation_date'] ?? '', style: GoogleFonts.sora(fontSize: 12)),
                        trailing: Text(res['status'] ?? '-', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    )).toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalChart(Map<String, dynamic> chart) {
    List<String> labels = List<String>.from(chart['labels'] ?? []);
    List<dynamic> resData = chart['reservations'] ?? [];
    List<dynamic> tickData = chart['tickets'] ??[];
    List<dynamic> incData = chart['income'] ??[];

    return Container(
      height: 350, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Column(
        children:[
          Text("Weekly Overview", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children:[
            _buildLegendItem(Colors.pink, "Res."),
            const SizedBox(width: 10),
            _buildLegendItem(const Color(0xFF14334C), "Tickets"),
            const SizedBox(width: 10),
            _buildLegendItem(const Color(0xFFD4AF37), "Income"),
          ]),
          const SizedBox(height: 15),
          Expanded(child: LineChart(LineChartData(
            minY: 0, maxY: 1.0,
            gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: 0.1,
              getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 30, interval: 0.1,
                getTitlesWidget: (val, meta) => Text(val.toStringAsFixed(1), style: GoogleFonts.sora(fontSize: 8))
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 30,
                getTitlesWidget: (val, meta) => Padding(padding: const EdgeInsets.only(top: 5), child: Text(labels[val.toInt()], style: GoogleFonts.sora(fontSize: 8)))
              )),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
            lineBarsData:[
              _createLine(resData, Colors.pink),
              _createLine(tickData, const Color(0xFF14334C)),
              _createLine(incData, const Color(0xFFD4AF37)),
            ],
          ))),
        ],
      ),
    );
  }

  LineChartBarData _createLine(List<dynamic> data, Color color) {
    return LineChartBarData(
      spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), (data[i] as num).toDouble())),
      color: color, isCurved: true, barWidth: 3, dotData: FlDotData(show: true),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children:[Container(width: 10, height: 10, color: color), const SizedBox(width: 4), Text(text, style: GoogleFonts.sora(fontSize: 10))]);
  }

  Widget _buildStatCard(String title, String val, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
        Icon(icon, size: 20, color: color),
        Text(val, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: GoogleFonts.sora(fontSize: 9, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildListTile(String title, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Row(children:[Icon(icon, size: 18, color: const Color(0xFF14334C)), const SizedBox(width: 12), Text(title, style: GoogleFonts.sora(fontSize: 14)), const Spacer(), Text(val, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14))]),
    );
  }
}