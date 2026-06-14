import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart';
import 'otp_verification_screen.dart'; 
import 'login_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  
  // State untuk ikon mata password
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 👇 STATE UNTUK KEKUATAN PASSWORD 👇
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 👇 FUNGSI UNTUK MENGECEK KEKUATAN PASSWORD REAL-TIME 👇
  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }

    int score = 0;
    // Pengecekan 4 Syarat Wajib
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++; // Huruf Kapital
    if (password.contains(RegExp(r'[0-9]'))) score++; // Angka
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // Karakter Khusus

    setState(() {
      _passwordStrength = score / 4;
      if (score <= 1) {
        _passwordStrengthText = 'Sangat Lemah (Bahaya)';
        _passwordStrengthColor = Colors.red;
      } else if (score == 2) {
        _passwordStrengthText = 'Lemah';
        _passwordStrengthColor = Colors.orange;
      } else if (score == 3) {
        _passwordStrengthText = 'Sedang';
        _passwordStrengthColor = Colors.amber.shade600;
      } else {
        _passwordStrengthText = 'Kuat (Aman)';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _handleRegister() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // 1. Cek kekosongan field wajib
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Nama, Email, dan Password wajib diisi');
      return;
    }

    // 2. Validasi Password Berdasarkan Syarat
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter');
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => _errorMessage = 'Password harus memiliki minimal 1 huruf kapital');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _errorMessage = 'Password harus memiliki minimal 1 angka');
      return;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() => _errorMessage = 'Password harus memiliki minimal 1 karakter khusus (cth: ! @ #)');
      return;
    }

    // 3. Konfirmasi Password
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 4. Siapkan payload data (phone dikirim hanya jika tidak kosong)
    Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
    };

    if (phone.isNotEmpty) {
      data['phone'] = phone; // Nomor telepon sekarang resmi opsional!
    }

    final result = await _apiService.register(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true || result['message'] == 'User created successfully') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Mengalihkan ke verifikasi OTP...'), backgroundColor: Colors.green)
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: email)),
      );
    } else {
      String errorMsg = result['message'] ?? 'Gagal melakukan registrasi';

      // Logika cerdas jika email nyangkut di OTP
      if (errorMsg.contains('belum verifikasi')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange, duration: const Duration(seconds: 4)));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        });
      } else if (errorMsg.contains('sudah diverifikasi')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.blue, duration: const Duration(seconds: 4)));
      } else {
        setState(() => _errorMessage = errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryNavy,
      body: SafeArea(
        bottom: false, 
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // --- HEADER LOGO ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: activeGold, width: 2)),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/caldera_icon.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(Icons.pool, size: 40, color: activeGold), 
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('CALDERA', style: GoogleFonts.playfairDisplay(color: activeGold, fontSize: 24, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                        Text('RESTO & POOL', style: GoogleFonts.sora(color: Colors.white70, fontSize: 10, letterSpacing: 4.0)),
                      ],
                    ),
                  ),

                  // --- KARTU FORM REGISTER ---
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Create Account', style: GoogleFonts.playfairDisplay(color: primaryNavy, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Daftar untuk menikmati layanan Caldera', style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 32),

                          // PESAN ERROR
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_errorMessage!, style: GoogleFonts.sora(color: Colors.red.shade700, fontSize: 12))),
                                ],
                              ),
                            ),

                          // NAMA FIELD
                          _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
                          const SizedBox(height: 16),
                          
                          // EMAIL FIELD
                          _buildTextField('Alamat Email', _emailController, Icons.email_outlined, type: TextInputType.emailAddress),
                          const SizedBox(height: 16),

                          // PHONE FIELD (Opsional)
                          _buildTextField('Nomor WhatsApp (Opsional)', _phoneController, Icons.phone_outlined, type: TextInputType.phone),
                          const SizedBox(height: 16),

                          // PASSWORD FIELD DGN DETEKSI REAL-TIME
                          _buildPasswordField(
                            'Password (Kapital, Angka, Simbol)', 
                            _passwordController, 
                            _obscurePassword, 
                            () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            onChanged: _checkPasswordStrength, // 👈 Panggil fungsi deteksi kekuatan
                          ),
                          
                          // 👇 WIDGET INDIKATOR KEKUATAN PASSWORD 👇
                          if (_passwordController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor: Colors.grey.shade200,
                                        color: _passwordStrengthColor,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _passwordStrengthText,
                                    style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: _passwordStrengthColor),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // CONFIRM PASSWORD FIELD
                          _buildPasswordField('Konfirmasi Password', _confirmPasswordController, _obscureConfirmPassword, () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          }),
                          const SizedBox(height: 32),

                          // REGISTER BUTTON
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy, elevation: 5, shadowColor: primaryNavy.withOpacity(0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Daftar Sekarang', style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // LOGIN LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sudah mempunyai akun? ', style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context), 
                                child: Text('Login di sini.', style: GoogleFonts.sora(color: activeGold, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER TEXT FIELD
  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller, keyboardType: type, style: GoogleFonts.sora(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: const Color(0xFF14334C)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // WIDGET HELPER PASSWORD FIELD (DIPERBARUI DGN onChanged)
  Widget _buildPasswordField(String hint, TextEditingController controller, bool isObscured, VoidCallback toggleVis, {Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller, 
        obscureText: isObscured, 
        style: GoogleFonts.sora(fontSize: 14),
        onChanged: onChanged, // 👈 Fungsi dijalankan saat mengetik
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF14334C)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600, size: 20),
            onPressed: toggleVis,
          ),
        ),
      ),
    );
  }
}