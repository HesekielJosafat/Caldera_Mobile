import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/onboarding1.jpg", // Ganti dengan path foto Anda
      "title": "Pengalaman Terbaik Menikmati Resto & Pool",
      "desc": "Nikmati hidangan lezat dan suasana tenang dari Caldera hanya dalam satu aplikasi."
    },
    {
      "image": "assets/images/onboarding2.jpg",
      "title": "Berbagai Keuntungan Via Caldera App",
      "desc": "Pesan meja tanpa antri, dapat promo menarik setiap hari, dan fasilitas eksklusif lainnya."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Slider Gambar
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, i) => Image.asset(_pages[i]["image"]!, fit: BoxFit.cover, height: double.infinity),
          ),
          
          // Konten di bawah
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.white, Colors.white.withOpacity(0.8), Colors.transparent]
              )
            ),
          ),
          
          Positioned(
            bottom: 50, left: 24, right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) => 
                    Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4), 
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == i ? const Color(0xFF14334C) : Colors.grey))),
                ),
                const SizedBox(height: 20),
                Text(_pages[_currentPage]["title"]!, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF14334C)), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(_pages[_currentPage]["desc"]!, style: GoogleFonts.sora(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                
                // Tombol Masuk
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14334C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text("Masuk", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), // Atau arahkan ke home
                  child: Text("Lewati tahap ini", style: GoogleFonts.sora(color: Colors.grey)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}