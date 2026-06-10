import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart'; // Sesuaikan path api_service Anda
import 'otp_verification_screen.dart'; // File OTP yang akan kita buat

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak sama')));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
    };

    final result = await ApiService().register(data);

    setState(() => _isLoading = false);

    // Cek sesuai struktur response API Laravel Anda (misal success: true)
    if (result['success'] == true || result['message'] == 'User created successfully' /* Sesuaikan */) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil, periksa email untuk OTP')));
      
      // Pindah ke halaman OTP
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: _emailController.text)),
      );
    } else {
      // Tampilkan pesan error dari backend
      String errorMsg = result['message'] ?? 'Gagal melakukan registrasi';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);
    const Color activeGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: primaryNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => Column(
                    children: [
                      Text('CALDERA', style: GoogleFonts.sora(color: activeGold, fontSize: 28, letterSpacing: 2.0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('REGISTER', style: GoogleFonts.sora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField('Nama', controller: _nameController),
              const SizedBox(height: 16),
              _buildTextField('Email', controller: _emailController, inputType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Masukkan password', isPassword: true, controller: _passwordController),
              const SizedBox(height: 16),
              _buildTextField('Konfirmasi password', isPassword: true, controller: _confirmPasswordController),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Sudah punya akun? ', style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Login.',
                      style: GoogleFonts.sora(color: Colors.lightBlueAccent, fontSize: 12, decoration: TextDecoration.underline, decorationColor: Colors.lightBlueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text('Register', style: GoogleFonts.sora(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool isPassword = false, required TextEditingController controller, TextInputType inputType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.0)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        style: GoogleFonts.sora(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}