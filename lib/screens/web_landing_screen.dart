import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/auth_modal.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAuthModal(BuildContext context, bool isLogin) {
    AuthModal.show(context, isLogin: isLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: _buildHeader(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildFeaturesSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
        decoration: BoxDecoration(
          color: _isScrolled ? Colors.black.withOpacity(0.8) : Colors.transparent,
          boxShadow: _isScrolled
              ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]
              : [],
        ),
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39A4E6).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.health_and_safety, color: Color(0xFF39A4E6), size: 30),
                ),
                const SizedBox(width: 12),
                Text(
                  'MediScan',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Nav Links
            _navLink('Features'),
            _navLink('About'),
            _navLink('Contact'),
            const SizedBox(width: 30),
            // Auth Buttons
            TextButton(
              onPressed: () => _showAuthModal(context, true),
              child: Text(
                'Login',
                style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => _showAuthModal(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A4E6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Get Started', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF121212),
            const Color(0xFF1A1A1A),
            const Color(0xFF39A4E6).withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Elements
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF39A4E6).withOpacity(0.05),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 5.seconds)
             .moveY(begin: 0, end: 50, duration: 4.seconds),
          ),
          
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF39A4E6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.3)),
                          ),
                          child: Text(
                            'Revolutionizing Health Records',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF39A4E6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2),
                        const SizedBox(height: 30),
                        Text(
                          'Your Medical History,\nUnified and Secure.',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideX(begin: -0.1),
                        const SizedBox(height: 25),
                        Text(
                          'Scan, store, and analyze your medical reports with AI-powered insights. Access your healthcare data anywhere, anytime.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 20,
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showAuthModal(context, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF39A4E6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: Text('Get Started Now', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 20),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: Text('Watch Demo', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 4,
                    child: Center(
                      // Placeholder for a premium 3D illustration or high-res UI mockup
                      child: Icon(Icons.dashboard_customize, size: 400, color: Colors.white12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      color: const Color(0xFF161616),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Powerful Features',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _featureCard(Icons.scanner, 'AI Scanning', 'Instant data extraction from any medical report.'),
                  _featureCard(Icons.security, 'Total Security', 'Bank-grade encryption for all your health records.'),
                  _featureCard(Icons.insights, 'Smart Trends', 'Track your health metrics over time with interactive charts.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF39A4E6), size: 50),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale();
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      width: double.infinity,
      color: Colors.black,
      child: Center(
        child: Text(
          '© 2025 MediScan. All rights reserved.',
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      ),
    );
  }
}
