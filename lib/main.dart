import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import halaman Login
import 'core/features/auth/screens/login_screen.dart'; 

// Fungsi ini menangkap notifikasi saat aplikasi ditutup/di-minimize
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notifikasi masuk saat background: ${message.messageId}");
}

void main() async {
  // Wajib ditambahkan sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Menyalakan Firebase
  await Firebase.initializeApp(); 
  
  // Mendaftarkan fungsi background tadi
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); 

  runApp(const MyApp()); // (Sesuaikan dengan nama class App Anda)
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caldera Resto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14334C)),
        textTheme: GoogleFonts.soraTextTheme(Theme.of(context).textTheme),
      ),
      // UBAH INI: Aplikasi sekarang mulai dari LoginScreen
      home: const LoginScreen(), 
    );
  }
}