import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caldera_app/core/services/api_service.dart'; // Sesuaikan path api_service Anda
import 'package:pinput/pinput.dart';

// PASTIKAN IMPORT HALAMAN BERANDA INI SESUAI DENGAN FOLDER ANDA
import '../../user/main_user_screen.dart'; 

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _start = 60; // Timer 60 detik untuk kirim ulang
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() => _start = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan 6 digit OTP')));
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await ApiService().verifyOtp(_otpController.text);

    if (!mounted) return;
    
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi Berhasil!'), backgroundColor: Colors.green)
      );
      
      // 👇 MEMBERI WAKTU JEDA AGAR ANIMASI BERJALAN MULUS SEBELUM PINDAH 👇
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => const MainUserScreen()), 
            (route) => false,
          );
        }
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'OTP Salah atau Kadaluarsa'), backgroundColor: Colors.red)
      );
    }
  }

  void _resendOtp() async {
    setState(() => _isLoading = true);
    final result = await ApiService().resendOtp();
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP baru telah dikirim'), backgroundColor: Colors.green)
      );
      startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengirim ulang OTP'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF14334C);

    // TEMA UNTUK KOTAK PINPUT
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read, size: 60, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'Verifikasi Email',
                  style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan kode 6 digit yang dikirim ke',
                  style: GoogleFonts.sora(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    widget.email,
                    style: GoogleFonts.sora(fontSize: 14, color: Colors.amber[800], fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),

                Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: primaryNavy, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onCompleted: (pin) {
                    // Otomatis memicu verifikasi jika 6 digit sudah terisi penuh
                    if (!_isLoading) _verifyOtp();
                  },
                ),
                
                const SizedBox(height: 16),
                Text('Kode berlaku selama 10 menit', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),

                // Tombol Verifikasi
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text('Verifikasi Sekarang', style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),

                // Timer Kirim Ulang
                _start == 0
                    ? GestureDetector(
                        onTap: _isLoading ? null : _resendOtp,
                        child: Text('Kirim Ulang OTP', style: GoogleFonts.sora(color: primaryNavy, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                      )
                    : RichText(
                        text: TextSpan(
                          text: 'Tidak dapat kode? dalam ',
                          style: GoogleFonts.sora(color: Colors.grey[600], fontSize: 13),
                          children: [
                            TextSpan(text: '$_start detik', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}