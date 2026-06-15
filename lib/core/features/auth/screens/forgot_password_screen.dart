import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../services/api_service.dart'; // Sesuaikan path

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);

  bool _isLoading = false;
  
  // State mata password
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // State untuk melacak user sedang di tahap mana
  // 0: Input Email, 1: Input OTP & Password Baru
  int _currentStep = 0; 

  // STATE UNTUK KEKUATAN PASSWORD
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // FUNGSI UNTUK MENGECEK KEKUATAN PASSWORD REAL-TIME
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

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.forgotPassword(_emailController.text.trim());
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'OTP Terkirim'), backgroundColor: Colors.green));
      setState(() => _currentStep = 1); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal mengirim OTP'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.length < 6 || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP dan Password wajib diisi')));
      return;
    }

    // Validasi syarat password baru
    if (_passwordController.text.length < 8 || 
        !_passwordController.text.contains(RegExp(r'[A-Z]')) || 
        !_passwordController.text.contains(RegExp(r'[0-9]')) || 
        !_passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru belum memenuhi syarat keamanan'), backgroundColor: Colors.orange));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService().resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      _passwordController.text.trim(),
      _confirmPasswordController.text.trim()
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Password berhasil direset!'), backgroundColor: Colors.green));
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal reset password'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // TEMA KOTAK PINPUT
    final defaultPinTheme = PinTheme(
      width: 50, height: 56,
      textStyle: GoogleFonts.sora(fontSize: 22, color: primaryNavy, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // --- HEADER ICON ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: activeGold.withOpacity(0.3), width: 2)),
                          child: Icon(Icons.lock_reset, size: 60, color: activeGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- KARTU FORM (PUTIH) ---
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
                          Text(
                            _currentStep == 0 ? 'Lupa Password?' : 'Buat Password Baru',
                            style: GoogleFonts.playfairDisplay(color: primaryNavy, fontSize: 28, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStep == 0 
                              ? 'Masukkan email Anda untuk menerima kode OTP pemulihan.' 
                              : 'Masukkan kode OTP yang dikirim ke ${_emailController.text}',
                            style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // ===================================
                          // TAHAP 0: INPUT EMAIL
                          // ===================================
                          if (_currentStep == 0) ...[
                            _buildTextField('Alamat Email', _emailController, Icons.email_outlined, type: TextInputType.emailAddress),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryNavy, elevation: 5, shadowColor: primaryNavy.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _sendOtp,
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('Kirim Kode OTP', style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],

                          // ===================================
                          // TAHAP 1: INPUT OTP & PASSWORD BARU
                          // ===================================
                          if (_currentStep == 1) ...[
                            Center(
                              child: Pinput(
                                length: 6,
                                controller: _otpController,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                                  border: Border.all(color: primaryNavy, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // PASSWORD BARU
                            _buildPasswordField(
                              'Password Baru', 
                              _passwordController, 
                              _obscureNew, 
                              () => setState(() => _obscureNew = !_obscureNew),
                              onChanged: _checkPasswordStrength,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                              child: Text('* Syarat: Min. 8 karakter, ada huruf kapital, angka & simbol.', style: GoogleFonts.sora(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                            ),

                            // BAR KEKUATAN PASSWORD
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(value: _passwordStrength, backgroundColor: Colors.grey.shade200, color: _passwordStrengthColor, minHeight: 6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(_passwordStrengthText, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: _passwordStrengthColor)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // KONFIRMASI PASSWORD
                            _buildPasswordField(
                              'Konfirmasi Password', 
                              _confirmPasswordController, 
                              _obscureConfirm, 
                              () => setState(() => _obscureConfirm = !_obscureConfirm)
                            ),
                            const SizedBox(height: 32),

                            // TOMBOL SIMPAN
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeGold, elevation: 5, shadowColor: activeGold.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _resetPassword,
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : Text('Simpan Password Baru', style: GoogleFonts.sora(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
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

  // WIDGET HELPER PASSWORD FIELD
  Widget _buildPasswordField(String hint, TextEditingController controller, bool isObscured, VoidCallback toggleVis, {Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller, obscureText: isObscured, style: GoogleFonts.sora(fontSize: 14), onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sora(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF14334C)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600, size: 20), onPressed: toggleVis),
        ),
      ),
    );
  }
}