import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'package:intl/intl.dart'; 
import '../../../auth/screens/login_screen.dart';

import '../../reservation/screens/user_my_reservations_screen.dart';
import '../../pool/screens/user_my_tickets_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  // Data User
  String _userName = "User Name";
  String _userEmail = "user@caldera.com";
  String _userPhone = "";
  String _memberSince = "-"; 

  // Controllers Edit Profile
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  // Controllers Change Password
  final TextEditingController _oldPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfileData(showSpinner: false); 
    }
  }

  Future<void> _loadProfileData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    
    // 1. Ambil dari lokal dulu
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      _updateLocalState(userData);
    }

    // 2. Refresh dari API
    final apiData = await _apiService.getProfile();
    if (mounted && apiData['success'] == true && apiData['data'] != null) {
      _updateLocalState(apiData['data']);
      await prefs.setString('user', jsonEncode(apiData['data']));
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _updateLocalState(Map<String, dynamic> data) {
    setState(() {
      _userName = data['name'] ?? _userName;
      _userEmail = data['email'] ?? _userEmail;
      _userPhone = data['phone'] ?? _userPhone;
      
      if (data['created_at'] != null) {
        try {
          DateTime dt = DateTime.parse(data['created_at']).toLocal();
          _memberSince = DateFormat('dd MMMM yyyy').format(dt); 
        } catch (e) {
          _memberSince = data['created_at'].toString().split('T')[0];
        }
      }
      
      _nameCtrl.text = _userName;
      _phoneCtrl.text = _userPhone == '-' ? '' : _userPhone;
    });
  }

  Future<void> _updateProfile() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama lengkap wajib diisi")));
      return;
    }

    setState(() => _isSavingProfile = true);
    
    final payload = {
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'update_type': 'profile' 
    };

    final result = await _apiService.updateProfile(payload);
    
    setState(() => _isSavingProfile = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      _loadProfileData(showSpinner: false); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Gagal memperbarui profil", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua field password wajib diisi")));
      return;
    }
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak cocok", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }
    if (_newPasswordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password baru minimal 8 karakter", style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSavingPassword = true);

    final payload = {
      'current_password': _oldPasswordCtrl.text,
      'password': _newPasswordCtrl.text,
      'password_confirmation': _confirmPasswordCtrl.text,
      'update_type': 'password'
    };

    final result = await _apiService.updateProfile(payload);
    
    setState(() => _isSavingPassword = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Password lama salah atau terjadi kesalahan", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Log Out", style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin keluar?", style: GoogleFonts.sora(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: GoogleFonts.sora(color: Colors.grey.shade700))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await _apiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
            child: Text("Keluar", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return "U"; 
    List<String> nameParts = fullName.trim().split(RegExp(r'\s+')); 
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryNavy))
          : RefreshIndicator(
              color: primaryNavy,
              onRefresh: () => _loadProfileData(showSpinner: false), 
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    // --- BACKGROUND BIRU NAVY DI ATAS ---
                    Container(
                      height: 220, // Tinggi background biru
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: primaryNavy,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    
                    // --- KONTEN UTAMA ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 60), // Jarak aman dari atas

                          // ==========================================
                          // 1. KARTU PROFIL UTAMA (Menggantung di atas biru)
                          // ==========================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 32, bottom: 24, left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(20), 
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))]
                            ),
                            child: Column(
                              children: [
                                // Avatar Bulat
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: activeGold, width: 2.5)),
                                  child: CircleAvatar(
                                    radius: 40, 
                                    backgroundColor: primaryNavy, 
                                    child: Text(_getInitials(_userName), style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.bold, color: activeGold))
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Info Nama & Email
                                Text(_userName, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy)),
                                const SizedBox(height: 6),
                                Text(_userEmail, style: GoogleFonts.sora(fontSize: 13, color: Colors.grey.shade600)),
                                const SizedBox(height: 16),
                                
                                // Lencana Member
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: activeGold.withAlpha(20), 
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars, color: activeGold, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Member Since: $_memberSince",
                                        style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: activeGold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Tombol Riwayat
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300), 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                          padding: const EdgeInsets.symmetric(vertical: 14)
                                        ),
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserMyReservationsScreen())),
                                        icon: const Icon(Icons.calendar_month, size: 16, color: primaryNavy),
                                        label: Text("Reservasi", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: primaryNavy)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300), 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                          padding: const EdgeInsets.symmetric(vertical: 14)
                                        ),
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserMyTicketsScreen())),
                                        icon: const Icon(Icons.confirmation_number_outlined, size: 16, color: primaryNavy),
                                        label: Text("Tiket", style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: primaryNavy)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ==========================================
                          // 2. FORM EDIT PROFIL
                          // ==========================================
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: primaryNavy.withOpacity(0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.person_outline, color: primaryNavy, size: 20)
                                    ),
                                    const SizedBox(width: 12),
                                    Text("Informasi Profil", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                _buildLabel("Nama Lengkap"),
                                _buildTextField(_nameCtrl, "Nama lengkap Anda"),
                                const SizedBox(height: 16),
                                
                                _buildLabel("Alamat Email"),
                                TextField(
                                  controller: TextEditingController(text: _userEmail), enabled: false, style: GoogleFonts.sora(fontSize: 13, color: Colors.grey),
                                  decoration: InputDecoration(fillColor: Colors.grey.shade100, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 4),
                                  child: Text("Email tidak dapat diubah. Hubungi admin untuk perubahan.", style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade500)),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Nomor WhatsApp"),
                                _buildTextField(_phoneCtrl, "Contoh: 081234567890", isPhone: true),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity, height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    onPressed: _isSavingProfile ? null : _updateProfile,
                                    child: _isSavingProfile 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text("Simpan Perubahan", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ==========================================
                          // 3. FORM GANTI PASSWORD
                          // ==========================================
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: activeGold.withOpacity(0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.vpn_key_outlined, color: activeGold, size: 20)
                                    ),
                                    const SizedBox(width: 12),
                                    Text("Ganti Password", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                _buildLabel("Password Lama"),
                                _buildPasswordField(_oldPasswordCtrl, "Masukkan password saat ini", _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                                const SizedBox(height: 16),
                                
                                _buildLabel("Password Baru"),
                                _buildPasswordField(_newPasswordCtrl, "Minimal 8 karakter", _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                                const SizedBox(height: 16),

                                _buildLabel("Konfirmasi Password Baru"),
                                _buildPasswordField(_confirmPasswordCtrl, "Ulangi password baru", _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity, height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: activeGold,
                                      side: BorderSide(color: activeGold, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                    ),
                                    onPressed: _isSavingPassword ? null : _changePassword,
                                    child: _isSavingPassword 
                                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: activeGold, strokeWidth: 2))
                                        : Text("Ganti Password", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ==========================================
                          // 4. TOMBOL LOGOUT UTAMA
                          // ==========================================
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red, 
                                side: const BorderSide(color: Colors.red, width: 1.5), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              onPressed: _showLogoutDialog,
                              icon: const Icon(Icons.power_settings_new, size: 20),
                              label: Text("Log Out Keluar", style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // WIDGET HELPERS
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isPhone = false}) {
    return SizedBox(
      child: TextField(
        controller: ctrl, keyboardType: isPhone ? TextInputType.phone : TextInputType.text, style: GoogleFonts.sora(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), 
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF14334C))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, String hint, bool isObscured, VoidCallback toggleVis) {
    return SizedBox(
      child: TextField(
        controller: ctrl, obscureText: isObscured, style: GoogleFonts.sora(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade400, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), 
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF14334C))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: toggleVis),
        ),
      ),
    );
  }
}