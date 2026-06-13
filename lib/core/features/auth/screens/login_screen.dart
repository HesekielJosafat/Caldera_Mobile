import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_service.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart'; // Pastikan path import OTP screen ini sudah benar
import '../../user/main_user_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);
  
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validasi input tidak boleh kosong
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email tidak boleh kosong');
      return;
    }
    
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Password tidak boleh kosong');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // 👇 Blokir admin
      final user = response['user'];
      if (user != null && (user['role'] == 'admin' || user['role'] == 'staff')) {
        await _apiService.logout(); // Hapus memori yang terlanjur tersimpan
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akses Ditolak: Admin hanya dapat login melalui Website.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return; // Hentikan proses secara total!
      }

      // SKENARIO 1: Login sukses & Sudah OTP
      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainUserScreen()),
          );
        }
      }
        
      // SKENARIO 2: Password benar, tapi BELUM verifikasi OTP
      else if (response['needs_verification'] == true) {
        // Tampilkan pesan/notifikasi kecil ke user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Silakan verifikasi email Anda terlebih dahulu.'),
            backgroundColor: Colors.orange,
          )
        );

        // Lempar user ke halaman verifikasi OTP
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: _emailController.text.trim()),
          ),
        );
      } 
      // SKENARIO 3: Login gagal (password salah, email tidak terdaftar, dll)
      else {
        setState(() => _errorMessage = response['message'] ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/caldera_icon.jpeg',
                  height: 140,
                  errorBuilder: (context, error, stackTrace) => Column(
                    children: [
                      Icon(Icons.pool, size: 80, color: activeGold),
                      Text(
                        'CALDERA',
                        style: GoogleFonts.sora(color: activeGold, fontSize: 28, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              // Icon & Title
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, color: Colors.white, size: 45),
                    const SizedBox(height: 8),
                    Text(
                      'LOGIN',
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.sora(color: Colors.red.shade900, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Email Field
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.0)),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.sora(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: GoogleFonts.sora(color: Colors.grey, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.0)),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.sora(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: GoogleFonts.sora(color: Colors.grey, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.sora(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          fillColor: MaterialStateProperty.resolveWith((states) => Colors.transparent),
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Ingatkan saya', style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    child: Text('Lupa Password?', style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tidak mempunyai akun? ', style: GoogleFonts.sora(color: Colors.white, fontSize: 12)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Daftar.',
                      style: GoogleFonts.sora(
                        color: Colors.lightBlueAccent, 
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}