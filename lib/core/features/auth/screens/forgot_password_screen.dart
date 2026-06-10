import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../services/api_service.dart'; // Sesuaikan path

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);

  bool _isLoading = false;
  
  // State untuk melacak user sedang di tahap mana
  // 0: Input Email, 1: Input OTP & Password Baru
  int _currentStep = 0; 

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService().forgotPassword(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
      setState(() => _currentStep = 1); // Pindah ke tahap buat password baru
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.length < 6 || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService().resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      _passwordController.text.trim(),
      _confirmPasswordController.text.trim()
    );
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
      // Kembali ke halaman Login
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal reset password'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _currentStep == 1 ? setState(() => _currentStep = 0) : Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.lock_reset, size: 80, color: activeGold),
              const SizedBox(height: 20),
              Text(
                'Lupa Password?',
                style: GoogleFonts.sora(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _currentStep == 0 
                  ? 'Masukkan email Anda untuk menerima kode OTP pemulihan.' 
                  : 'Masukkan kode OTP dan buat password baru Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 40),

              // TAHAP 0: INPUT EMAIL
              if (_currentStep == 0) ...[
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.sora(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Masukkan Email',
                      prefixIcon: Icon(Icons.email, color: primaryNavy),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('Kirim Kode OTP', style: GoogleFonts.sora(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              // TAHAP 1: INPUT OTP & PASSWORD BARU
              if (_currentStep == 1) ...[
                Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: PinTheme(
                    width: 50, height: 56,
                    textStyle: const TextStyle(fontSize: 22, color: Colors.black),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildPasswordField('Password Baru', _passwordController),
                const SizedBox(height: 16),
                _buildPasswordField('Konfirmasi Password', _confirmPasswordController),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: activeGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('Simpan Password', style: GoogleFonts.sora(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: GoogleFonts.sora(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.lock, color: primaryNavy),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}