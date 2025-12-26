import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      appBar: _buildHeader(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildHowItWorksSection(),
            _buildFeatureShowcase(),
            _buildCTASection(),
            _buildFooter(),
          ],
        ),
      ),
      floatingActionButton: _isScrolled
          ? FloatingActionButton(
              onPressed: () => _scrollController.animateTo(0, duration: 600.ms, curve: Curves.easeOutQuart),
              backgroundColor: const Color(0xFF39A4E6),
              elevation: 4,
              child: const Icon(LucideIcons.arrowUp, color: Colors.white),
            ).animate().scale().fadeIn()
          : null,
    );
  }

  PreferredSizeWidget _buildHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: AnimatedContainer(
        duration: 400.ms,
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: _isScrolled ? 10 : 0,
              sigmaY: _isScrolled ? 10 : 0,
            ),
            child: AnimatedContainer(
              duration: 400.ms,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              decoration: BoxDecoration(
                color: _isScrolled ? Colors.black.withOpacity(0.7) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: _isScrolled ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Premium Logo
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF39A4E6), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF39A4E6).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'MediScan',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Navigation
                  _headerNavLink('Services'),
                  _headerNavLink('Solutions'),
                  _headerNavLink('Integrations'),
                  const SizedBox(width: 40),
                  TextButton(
                    onPressed: () => _showAuthModal(context, true),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 25),
                  ElevatedButton(
                    onPressed: () => _showAuthModal(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39A4E6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                    ),
                    child: Text('Join MediScan', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerNavLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          // Dynamic Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.8, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A3B58),
                    Color(0xFF0F0F0F),
                  ],
                ),
              ),
            ),
          ),
          
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pillBadge('Next Gen Health Analysis'),
                        const SizedBox(height: 40),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 84,
                              fontWeight: FontWeight.bold,
                              height: 1.05,
                            ),
                            children: const [
                              TextSpan(text: 'Revolutionizing\n'),
                              TextSpan(
                                text: 'Health Data ',
                                style: TextStyle(color: Color(0xFF39A4E6)),
                              ),
                              TextSpan(text: 'Access.'),
                            ],
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
                        const SizedBox(height: 30),
                        Text(
                          'Transform your medical reports into intelligent insights. Secured by bank-grade encryption and powered by precision AI.',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 22,
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 800.ms),
                        const SizedBox(height: 50),
                        Row(
                          children: [
                            _actionButton('Start Your Journey', true, () => _showAuthModal(context, false)),
                            const SizedBox(width: 25),
                            _actionButton('View Demo', false, () {}),
                          ],
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Image.asset(
                        'assets/images/web_intro_1.png',
                        fit: BoxFit.contain,
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .moveY(begin: -20, end: 20, duration: 4.seconds, curve: Curves.easeInOutSine)
                       .animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.9, 0.9)),
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

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 160, horizontal: 80),
      color: Colors.black,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/web_intro_2.png',
                  fit: BoxFit.contain,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),
              ),
              const SizedBox(width: 100),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pillBadge('Intelligent Extraction'),
                    const SizedBox(height: 30),
                    Text(
                      'AI-Powered Report Scanning',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Our advanced OCR and NLP algorithms extract critical medical data from your reports with 99.9% accuracy. No more manual entry—just clear, actionable results.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _featureItem(LucideIcons.checkCircle, 'Instant Analysis'),
                    _featureItem(LucideIcons.checkCircle, 'Smart Categorization'),
                    _featureItem(LucideIcons.checkCircle, 'Multi-format Support (PDF, PNG, JPG)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureShowcase() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 160, horizontal: 80),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pillBadge('Family Focused'),
                    const SizedBox(height: 30),
                    Text(
                      'Universal Records for Your Whole Family',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Manage health profiles for your children, parents, and yourself in one unified dashboard. Securely share reports with doctors when it matters most.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _featureItem(LucideIcons.users, 'Profile Switching'),
                    _featureItem(LucideIcons.share2, 'One-tap Sharing'),
                    _featureItem(LucideIcons.heart, 'Comprehensive History'),
                  ],
                ),
              ),
              const SizedBox(width: 100),
              Expanded(
                child: Image.asset(
                  'assets/images/web_intro_3.png',
                  fit: BoxFit.contain,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 120),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF39A4E6).withOpacity(0.1), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Take Control of Your Health?',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Join thousands of users who trust MediScan daily.',
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 18),
          ),
          const SizedBox(height: 50),
          _actionButton('Get Started for Free', true, () => _showAuthModal(context, false)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      color: Colors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MediScan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _footerLink('Privacy Policy'),
                  const SizedBox(width: 30),
                  _footerLink('Terms of Service'),
                  const SizedBox(width: 30),
                  _footerLink('Help Center'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 40),
          Text(
            '© 2025 MediScan Intelligence Ltd. Built with clinical precision.',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          color: const Color(0xFF39A4E6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _actionButton(String text, bool isPrimary, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF39A4E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ] : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF39A4E6), size: 24),
          const SizedBox(width: 15),
          Text(
            text,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15),
    );
  }
}
