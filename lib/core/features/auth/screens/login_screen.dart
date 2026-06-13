import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../../services/api_service.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart'; 
import '../../user/main_user_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true; 
  String? _errorMessage;

  final Color primaryNavy = const Color(0xFF14334C);
  final Color activeGold = const Color(0xFFD4AF37);
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail(); 
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI INGATKAN SAYA (REMEMBER ME)
  // ==========================================
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveOrClearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  // ==========================================
  // FUNGSI LOGIN UTAMA
  // ==========================================
  Future<void> _login() async {
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
      
      final user = response['user'];
      if (user != null && (user['role'] == 'admin' || user['role'] == 'staff')) {
        await _apiService.logout(); 
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
        return; 
      }

      if (response['success'] == true) {
        await _saveOrClearEmail(); 

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainUserScreen()),
          );
        }
      } else if (response['needs_verification'] == true) {
        await _saveOrClearEmail(); 

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Silakan verifikasi email Anda terlebih dahulu.'),
              backgroundColor: Colors.orange,
            )
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: _emailController.text.trim()),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Email atau password salah');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan jaringan');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // RENDER UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Mengambil tinggi layar HP untuk membuat responsif
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryNavy,
      body: SafeArea(
        bottom: false, 
        // 👇 PERBAIKAN: SingleChildScrollView bungkus seluruh layar agar tidak error saat keyboard muncul
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
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 👇 PERBAIKAN: Logo Gambar Bulat Caldera 👇
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: activeGold, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/caldera_icon.jpeg', // Gambar asli Caldera
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.pool, size: 50, color: activeGold), // Cadangan jika gambar belum ditaruh di assets
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CALDERA',
                          style: GoogleFonts.playfairDisplay(color: activeGold, fontSize: 32, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RESTO & POOL',
                          style: GoogleFonts.sora(color: Colors.white70, fontSize: 12, letterSpacing: 4.0),
                        ),
                      ],
                    ),
                  ),

                  // --- KARTU FORM LOGIN ---
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.playfairDisplay(color: primaryNavy, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan login untuk melanjutkan',
                            style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 13),
                          ),
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

                          // INPUT EMAIL
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.sora(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Alamat Email',
                                hintStyle: GoogleFonts.sora(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.email_outlined, color: primaryNavy),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // INPUT PASSWORD DGN IKON MATA
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword, 
                              style: GoogleFonts.sora(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: GoogleFonts.sora(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.lock_outline, color: primaryNavy),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // LOGIN BUTTON
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy,
                                elevation: 5,
                                shadowColor: primaryNavy.withOpacity(0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Login Sekarang', style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // REMEMBER ME & FORGOT PASSWORD
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: primaryNavy,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (value) {
                                        setState(() => _rememberMe = value ?? false);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Ingatkan saya', style: GoogleFonts.sora(color: Colors.grey.shade700, fontSize: 12)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                child: Text('Lupa Password?', style: GoogleFonts.sora(color: primaryNavy, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),

                          // REGISTER LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Belum mempunyai akun? ', style: GoogleFonts.sora(color: Colors.grey.shade600, fontSize: 12)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                                },
                                child: Text(
                                  'Daftar di sini.',
                                  style: GoogleFonts.sora(color: activeGold, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20), // Spasi agar aman kalau ada keyboard
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
}