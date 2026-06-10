import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Pastikan package intl sudah terinstall
import 'package:caldera_app/core/services/api_service.dart';
import 'user_reservation_success_screen.dart'; // Import layar sukses
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart'; // Import MainUserScreen untuk navigasi aman ke home setelah cancel

class UserReservationScreen extends StatefulWidget {
  const UserReservationScreen({Key? key}) : super(key: key);

  @override
  State<UserReservationScreen> createState() => _UserReservationScreenState();
}

class _UserReservationScreenState extends State<UserReservationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _guestsCtrl = TextEditingController(text: '2');
  final TextEditingController _specialReqCtrl = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;

  // Sesuai dengan konfigurasi di web
  final List<String> weekdaySlots = [
    '10:00:00', '11:00:00', '12:00:00', '13:00:00', '14:00:00',
    '15:00:00', '16:00:00', '17:00:00', '18:00:00', '19:00:00',
    '20:00:00', '21:00:00'
  ];
  
  final List<String> weekendSlots = [
    '09:00:00', '10:00:00', '11:00:00', '12:00:00', '13:00:00',
    '14:00:00', '15:00:00', '16:00:00', '17:00:00', '18:00:00',
    '19:00:00', '20:00:00', '21:00:00', '22:00:00'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _guestsCtrl.dispose();
    _specialReqCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Di web: min 1 hari ke depan, max 30 hari ke depan
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF14334C), 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset waktu jika tanggal berubah
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih tanggal reservasi")));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih jam reservasi")));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> payload = {
      'customer_name': _nameCtrl.text,
      'customer_phone': _phoneCtrl.text,
      'number_of_guests': int.parse(_guestsCtrl.text),
      'reservation_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'reservation_time': _selectedTime,
      'special_requests': _specialReqCtrl.text,
    };

    final result = await _apiService.createReservation(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      
      // Jika sukses (Ada parameter success true atau ada object data)
      if (result['success'] == true || result['data'] != null || result['booking_code'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reservasi Berhasil!")));
        
        // Ambil data reservasi dari response Laravel (Biasanya di dalam array 'data')
        Map<String, dynamic> resData = result['data'] ?? result;

        // Arahkan ke Layar Sukses
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => UserReservationSuccessScreen(reservationData: resData))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Gagal menyimpan reservasi")));
      }
    }
  }

  // Format dari "13:00:00" menjadi "1:00 PM"
  String _formatTimeDisplay(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return "$hour12:00 $ampm";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    // Cek apakah tanggal yg dipilih adalah weekend
    bool isWeekend = false;
    if (_selectedDate != null) {
      isWeekend = _selectedDate!.weekday == DateTime.saturday || _selectedDate!.weekday == DateTime.sunday;
    }
    List<String> currentSlots = isWeekend ? weekendSlots : weekdaySlots;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // APPBAR DIHAPUS DI SINI
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryNavy))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ==========================================
                // 1. KARTU FORM RESERVASI
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.clipboardList, color: activeGold, size: 28
                              ), const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              Text("Reservation Form", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy)),
                              Text("Fill out the form below & we'll confirm via WhatsApp", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildLabel("Full Name *", Icons.person, activeGold),
                        _buildTextField(_nameCtrl, "Enter your full name", TextInputType.name),
                        const SizedBox(height: 16),

                        _buildLabel(
                            "WhatsApp Number *",
                            FontAwesomeIcons.whatsapp,
                            const Color(0xFF25D366),
                          ),
                        _buildTextField(_phoneCtrl, "0812-3456-7890", TextInputType.phone),
                        Text("We'll send confirmation to this number", style: GoogleFonts.sora(color: Colors.grey.shade500, fontSize: 9)),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Guests *", Icons.people, activeGold),
                                  _buildTextField(_guestsCtrl, "2", TextInputType.number),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Date *", Icons.calendar_today, activeGold),
                                  InkWell(
                                    onTap: _pickDate,
                                    child: Container(
                                      height: 48, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_selectedDate == null ? "mm/dd/yyyy" : DateFormat('MM/dd/yyyy').format(_selectedDate!), style: GoogleFonts.sora(fontSize: 13, color: _selectedDate == null ? Colors.grey : Colors.black87)),
                                          Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // TIME SLOTS (Dinamis berubah sesuai hari yg dipilih)
                        _buildLabel("Reservation Time *", Icons.access_time, activeGold),
                        _selectedDate == null 
                          ? Container(
                              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 30),
                                  const SizedBox(height: 8),
                                  Text("Please select a date first", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: Colors.blue.shade400, width: 4))),
                                  child: Text("Operating Hours for ${isWeekend ? 'Weekend: 09:00 - 23:00' : 'Weekday: 10:00 - 22:00'}", style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                ),
                                GridView.builder(
                                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                  itemCount: currentSlots.length,
                                  itemBuilder: (context, index) {
                                    String time = currentSlots[index];
                                    bool isSelected = _selectedTime == time;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedTime = time),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryNavy : (isWeekend ? Colors.green.shade50 : const Color(0xFFF8F6F2)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isSelected ? primaryNavy : (isWeekend ? Colors.green.shade200 : Colors.grey.shade300)),
                                        ),
                                        child: Text("🕐 ${_formatTimeDisplay(time)}", style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade900),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text("Note: Your table will be held for 30 minutes after the reservation time.", style: GoogleFonts.sora(fontSize: 10, color: Colors.orange.shade900))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                        const SizedBox(height: 24),

                        _buildLabel("Special Requests", Icons.comment, activeGold),
                        TextField(
                          controller: _specialReqCtrl, maxLines: 3, style: GoogleFonts.sora(fontSize: 13),
                          decoration: InputDecoration(hintText: "Example: baby chair, non-smoking area...", hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.all(12)),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFDFCFA), borderRadius: BorderRadius.circular(12), border: const Border(left: BorderSide(color: Color(0xFF25D366), width: 4))),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.whatsapp, color: const Color(0xFF25D366), size: 18
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Confirmation via WhatsApp:", style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: primaryNavy)),
                                    Text("Reservation confirmation will be sent to your WhatsApp number within 24 hours.", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Ganti bagian Row tombol (baris 270-an) menjadi:
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primaryNavy), 
                                  padding: const EdgeInsets.symmetric(vertical: 14), 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ), 
                                onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MainUserScreen()),
                                  (route) => false,
                                );
                              }, 
                                child: Text("Cancel", style: GoogleFonts.sora(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 13))
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366), 
                                  padding: const EdgeInsets.symmetric(vertical: 14), 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ), 
                                onPressed: _submitForm, 
                                icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 16), 
                                label: Text("Reserve", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                              )
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 2. KARTU JAM OPERASIONAL & KONTAK
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.restaurant, color: activeGold, size: 28), const SizedBox(height: 8),
                            Text("Restaurant Hours", style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 12)), const SizedBox(height: 4),
                            Text("Mon-Fri: 10:00 - 22:00\nSat-Sun: 09:00 - 23:00", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      Container(height: 60, width: 1, color: Colors.grey.shade200),
                      Expanded(
                        child: Column(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.phone, color: activeGold, size: 28
                            ), const SizedBox(height: 8),
                            Text("Contact Us", style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 12)), const SizedBox(height: 4),
                            Text("WA: 0812-3456-7890\nCall: (022) 1234567", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }

  // Helper membuat Label
  Widget _buildLabel(String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF14334C))),
        ],
      ),
    );
  }

  // Helper membuat TextField
  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextFormField(
      controller: controller, keyboardType: type, style: GoogleFonts.sora(fontSize: 13),
      validator: (value) => value!.isEmpty ? "This field is required" : null,
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
    );
  }
}