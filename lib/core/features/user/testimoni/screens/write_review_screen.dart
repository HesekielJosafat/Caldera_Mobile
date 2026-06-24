import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io'; // Untuk File
import 'package:image_picker/image_picker.dart'; // Untuk ambil gambar

// PACKAGE TIMEAGO UNTUK FORMAT WAKTU NOTIFIKASI
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/src/messages/id_messages.dart';

// IMPORT API, NAVBAR, DAN HALAMAN TERKAIT
import 'package:caldera_app/core/services/api_service.dart';
import 'package:caldera_app/core/widgets/custom_bottom_nav.dart';
import 'package:caldera_app/core/features/user/main_user_screen.dart';
import 'package:caldera_app/core/features/user/notification/screens/user_notification_screen.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({Key? key}) : super(key: key);

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedService;
  DateTime? _visitDate;
  int _selectedRating = 0;
  File? _selectedImage;

  // ==========================================
  // STATE NOTIFIKASI
  // ==========================================
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    // SETUP BAHASA INDONESIA UNTUK TIMEAGO
    timeago.setLocaleMessages('id', IdMessages());
    _fetchNotifications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI NOTIFIKASI
  // ==========================================
  Future<void> _fetchNotifications() async {
    try {
      final data = await _apiService.getUserNotifications();
      final notifications = List<dynamic>.from(data['notifications'] ?? []);
      final unreadCount = notifications.where((n) => n['read_at'] == null).length;

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
          _notifications = notifications;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil notifikasi: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    Navigator.of(context).pop();

    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read_at'] = 'read';
      }
    });

    bool success = await _apiService.markAllNotificationsAsRead();
    if (success) {
      await _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua notifikasi ditandai dibaca"), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }
    } else {
      await _fetchNotifications();
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '-';
    try {
      String formattedString = createdAt.replaceAll(' ', 'T');
      if (!formattedString.endsWith('Z')) {
        formattedString = formattedString + 'Z';
      }
      final dateTime = DateTime.parse(formattedString).toLocal();
      return timeago.format(dateTime, locale: 'id');
    } catch (e) {
      return createdAt;
    }
  }

  void _showNotificationPopup() {
    _fetchNotifications();

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 5,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications_active, size: 16, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 8),
                                Text("Notifikasi", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                            if (_unreadCount > 0)
                              GestureDetector(
                                onTap: _markAllAsRead,
                                child: Text("Tandai semua dibaca", style: GoogleFonts.sora(fontSize: 10, color: const Color(0xFF14334C), fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                      Flexible(
                        child: _notifications.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications_off_outlined, size: 32, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text("Belum ada notifikasi", style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 11)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _notifications.length > 4 ? 4 : _notifications.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final notif = _notifications[index];
                                  bool isUnread = notif['read_at'] == null;

                                  return Container(
                                    color: isUnread ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF14334C).withOpacity(0.1),
                                        child: const Icon(Icons.notifications, color: Color(0xFF14334C), size: 18),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(notif['title'] ?? '', style: GoogleFonts.sora(fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                                          ),
                                          if (isUnread) const Icon(Icons.circle, size: 8, color: Colors.red),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(notif['body'] ?? '', style: GoogleFonts.sora(fontSize: 10, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Text(_formatTime(notif['created_at']), style: GoogleFonts.sora(fontSize: 9, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserNotificationScreen()));
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.all(12),
                          child: Text("Lihat semua notifikasi →", textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 11, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // FUNGSI SUBMIT REVIEW KE API
  // ==========================================
  Future<void> _submitReview() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama wajib diisi!")));
      return;
    }
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon berikan rating (bintang)!")));
      return;
    }
    if (_reviewController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ulasan minimal 10 karakter!")));
      return;
    }

    setState(() => _isSubmitting = true);

    // Siapkan data sesuai kebutuhan TestimonialController Laravel
    Map<String, dynamic> payload = {
      'customer_name': _nameController.text.trim(),
      'customer_email': _emailController.text.trim(),
      'rating': _selectedRating,
      'comment': _reviewController.text.trim(),
      'service_type': _selectedService?.toLowerCase(),
    };

    final result = await _apiService.submitTestimonial(payload);
    
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Testimoni berhasil dikirim dan menunggu persetujuan admin."), backgroundColor: Colors.green)
      );
      // Kembali ke halaman testimoni
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Gagal mengirim testimoni. Silakan coba lagi."), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF14334C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _visitDate) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80, // Mengurangi ukuran agar tidak lebih dari 2MB
  );

  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }
}

  // ==========================================
  // RENDER BODY (FORM REVIEW)
  // ==========================================
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text("Share your experience at Caldera Resto & Pool", style: GoogleFonts.sora(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),

            // NAME & EMAIL
            _buildLabel("Your Name *"),
            _buildTextField(_nameController, "Enter your name"),
            const SizedBox(height: 16),
            
            // _buildLabel("Email (Optional)"),
            // _buildTextField(_emailController, "Enter your email"),
            // const SizedBox(height: 16),

            // SERVICE TYPE & VISIT DATE
            _buildLabel("Service Type"),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedService,
                  hint: Text("Select Service", style: GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade600)),
                  items: ["Restaurant", "Pool", "Event"].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.sora(fontSize: 13)));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedService = newValue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel("Visit Date"),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Text(
                      _visitDate == null ? "mm/dd/yyyy" : "${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}",
                      style: GoogleFonts.sora(fontSize: 13, color: _visitDate == null ? Colors.grey.shade600 : Colors.black87),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PHOTO UPLOAD
//             _buildLabel("Your Photo (Optional)"),
// Row(
//   children: [
//     ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.grey.shade200,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(4),
//             side: BorderSide(color: Colors.grey.shade300)),
//       ),
//       // 1. Panggil fungsi _pickImage saat tombol ditekan
//                   onPressed: _pickImage, 
//                   child: Text("Choose File", style: GoogleFonts.sora(fontSize: 12)),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   // 2. Gunakan _selectedImage untuk menampilkan nama file
//                   child: Text(
//                     _selectedImage == null 
//                         ? "No file chosen" 
//                         : _selectedImage!.path.split('/').last, // Ambil nama file-nya saja
//                     style: GoogleFonts.sora(fontSize: 12, color: Colors.grey),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text("Max 2MB. JPG, JPEG, or PNG", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey)),
//             const SizedBox(height: 24),

//             // RATING STARS
//             _buildLabel("Rating *"),
//             Row(
//               children: List.generate(5, (index) {
//                 return IconButton(
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                   icon: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
//                   onPressed: () => setState(() => _selectedRating = index + 1),
//                 );
//               }),
//             ),
//             const SizedBox(height: 20),

            // REVIEW TEXT
            _buildLabel("Your Review *"),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              style: GoogleFonts.sora(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Tell us about your experience...",
                hintStyle: GoogleFonts.sora(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 4),
            Text("Min 10 characters", style: GoogleFonts.sora(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 30),

            // SUBMIT BUTTON (WITH LOADING STATE)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14334C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          const Icon(Icons.send, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Submit Review", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // ==========================================
      // APP HEADER CALDERA DGN NOTIFIKASI
      // ==========================================
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: primaryNavy,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Caldera ', style: TextStyle(color: activeGold)),
              const TextSpan(text: 'Resto & Pool', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showNotificationPopup,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: _buildBody(), // Form Submit Review

      // ==========================================
      // BOTTOM NAVBAR
      // ==========================================
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0, 
        onItemTapped: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainUserScreen(initialIndex: index,)),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        style: GoogleFonts.sora(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}