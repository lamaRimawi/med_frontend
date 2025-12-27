import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../widgets/auth_modal.dart';
import '../widgets/animated_bubble_background.dart';
import '../services/auth_service.dart';
import '../services/auth_api.dart';
import '../widgets/theme_toggle.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isScrolled = false;

  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _scrollController.addListener(_onScroll);
    
    // Ensure focus for keyboard scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && token.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    final lastMethod = prefs.getString('last_login_method');
    if (lastMethod == 'google') {
      final userData = await AuthService.trySilentGoogleLogin();
      if (userData != null && mounted) {
        final (success, _) = await AuthApi.loginWithGoogle(userData['idToken']);
        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: 800.ms,
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showAuthModal(BuildContext context, bool isLogin) {
    AuthModal.show(context, isLogin: isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = themeProvider?.themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildHeader(context, isDark),
      body: Stack(
        children: [
          Positioned.fill(
             child: AnimatedBubbleBackground(isDark: isDark),
          ),
          
          Positioned.fill(
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (node, event) => KeyEventResult.ignored,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildHeroSection(context, isDark),
                    _buildStatsSection(context, isDark),
                    _buildFeaturesSection(context, isDark),
                    _buildShowcaseSection(context, isDark),
                    _buildCTASection(context, isDark),
                    _buildFooter(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isScrolled
          ? FloatingActionButton(
              onPressed: () => _scrollController.animateTo(0,
                  duration: 600.ms, curve: Curves.easeOutQuart),
              backgroundColor: const Color(0xFF39A4E6),
              elevation: 4,
              child: const Icon(LucideIcons.arrowUp, color: Colors.white),
            ).animate().scale().fadeIn()
          : null,
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context, bool isDark) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
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
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 60,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: _isScrolled
                    ? (isDark ? const Color(0xFF0F172A).withOpacity(0.7) : Colors.white.withOpacity(0.8))
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: _isScrolled
                        ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                   Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                      ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MediScan',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (!isMobile) ...[
                    _navButton('Features', isDark, () => _scrollToSection(_featuresKey)),
                    _navButton('How it Works', isDark, () => _scrollToSection(_howItWorksKey)),
                    const SizedBox(width: 20),
                  ],

                  if (!isMobile) ...[
                    TextButton(
                      onPressed: () => _showAuthModal(context, true),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  _HoverButton(
                    text: isMobile ? 'Get Started' : 'Join MediScan',
                    onTap: () => _showAuthModal(context, false),
                    isPrimary: true,
                    isDark: isDark,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Container(
      constraints: BoxConstraints(minHeight: math.max(500, size.height - 80)),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 100 : 24, 
        vertical: isDesktop ? 60 : 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                flex: isDesktop ? 6 : 1,
                child: Column(
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pillBadge('Next Gen Health AI', isDark),
                    const SizedBox(height: 32),
                    Text(
                      'Your Medical Data,\nFinally Understood.',
                      textAlign: isDesktop ? TextAlign.start : TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: isDesktop ? 72 : 42,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Upload reports, get instant AI analysis, and track your family\'s health trends securely. No more confusing medical jargon.',
                      textAlign: isDesktop ? TextAlign.start : TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: isDesktop ? 20 : 16,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 48),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        _HoverButton(
                          text: 'Analyze Report Now', 
                          onTap: () => _showAuthModal(context, false),
                          isPrimary: true,
                          isDark: isDark,
                        ),
                        _HoverButton(
                          text: 'Watch Demo', 
                          onTap: () {},
                          isPrimary: false,
                          isDark: isDark,
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 40),
                    
                    // Trust Indicators
                    Row(
                      mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        _trustItem(LucideIcons.shieldCheck, 'HIPAA Compliant', isDark),
                        const SizedBox(width: 24),
                        _trustItem(LucideIcons.users, '10k+ Users', isDark),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
              
              if (isDesktop) ...[
                const SizedBox(width: 60),
                Expanded(
                  flex: 5,
                  child: Image.asset(
                    'assets/images/web_intro_1.png',
                    fit: BoxFit.contain,
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .moveY(begin: -20, end: 20, duration: 4.seconds, curve: Curves.easeInOutSine)
                   .animate().fadeIn(duration: 1.seconds),
                )
              ]
            ],
          ),
          
          if (!isDesktop) ...[
             const SizedBox(height: 60),
             Image.asset(
                'assets/images/web_intro_1.png',
                height: 300,
                fit: BoxFit.contain,
              ).animate().fadeIn(),
          ]
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 60,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _statItem('99.9%', 'Accuracy Rate', isDark),
              _statItem('1M+', 'Reports Analyzed', isDark),
              _statItem('24/7', 'AI Availability', isDark),
              _statItem('Instant', 'Processing Speed', isDark),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Container(
      key: _featuresKey,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isDesktop ? 100 : 60),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Why MediScan?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF39A4E6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Medical Intelligence at Your Fingertips',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 48 : 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 80),

              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _featureCard(LucideIcons.scan, 'Smart OCR', 'Instantly digitize paper reports with 99% accuracy using advanced vision models.', isDark),
                  _featureCard(LucideIcons.brainCircuit, 'AI Analysis', 'Understand complex medical terms in plain English with our medical LLM.', isDark),
                  _featureCard(LucideIcons.shieldCheck, 'Bank-Grade Security', 'Your health data is encrypted end-to-end. We never sell your data.', isDark),
                  _featureCard(LucideIcons.history, 'Timeline View', 'Track health trends over time with dynamic charting and automatic aliasing.', isDark),
                  _featureCard(LucideIcons.share2, 'Easy Sharing', 'Securely share specific reports with your doctor or family members instantly.', isDark),
                  _featureCard(LucideIcons.users, 'Family Profiles', 'Manage health records for your entire multi-generational family in one place.', isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowcaseSection(BuildContext context, bool isDark) {
     final size = MediaQuery.of(context).size;
     final isDesktop = size.width > 900;

     return Container(
       key: _howItWorksKey,
       padding: EdgeInsets.symmetric(horizontal: 24, vertical: isDesktop ? 80 : 40),
       color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
       child: Center(
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: 1200),
           child: isDesktop 
             ? Row(
                children: [
                  Expanded(
                    child: Image.asset('assets/images/web_intro_2.png', fit: BoxFit.contain)
                      .animate().fadeIn().slideX(begin: -0.1),
                  ),
                  const SizedBox(width: 80),
                  Expanded(child: _showcaseContent(isDark)),
                ],
               )
             : Column(
                children: [
                  Image.asset('assets/images/web_intro_2.png', height: 300, fit: BoxFit.contain),
                  const SizedBox(height: 48),
                  _showcaseContent(isDark),
                ],
               ),
         ),
       ),
     );
  }

  Widget _showcaseContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pillBadge('Family First', isDark),
        const SizedBox(height: 24),
        Text(
          'Universal Records for\nYour Whole Family',
          style: GoogleFonts.outfit(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Manage health profiles for your children, parents, and yourself in one unified dashboard. Securely share reports with doctors when it matters most.',
          style: GoogleFonts.outfit(
            fontSize: 18,
            color: isDark ? Colors.white60 : Colors.black54,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _checkListItem('Multiple Profiles', isDark),
        _checkListItem('Timeline View of Health Trends', isDark),
        _checkListItem('PDF & Image Support', isDark),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1100),
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39A4E6).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ready to take control?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands trusting MediScan with their data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 18),
          ),
          const SizedBox(height: 40),
          
          _HoverButton(
            text: 'Get Started Free', 
            onTap: () => _showAuthModal(context, false),
            isPrimary: false,
            isDark: isDark,
            customBgColor: Colors.white,
            customTextColor: const Color(0xFF39A4E6),
            effect: HoverEffect.elevationGlow,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final themeProvider = ThemeProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Text(
                              'MediScan',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Empowering families with accessible, understandable, and secure medical intelligence.',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Theme Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _themeOption(Icons.sunny, 'Light', !isDark, themeProvider, isDark),
                              _themeOption(Icons.nightlight_round, 'Dark', isDark, themeProvider, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const Spacer(),
                    _footerColumn('Product', ['Features', 'How it Works', 'FAQ'], isDark),
                    const SizedBox(width: 60),
                    _footerColumn('Company', ['About Us', 'Careers', 'Contact'], isDark),
                    const SizedBox(width: 60),
                    _footerColumn('Legal', ['Privacy Policy', 'Terms of Service', 'Security'], isDark),
                  ],
                ],
              ),
              const SizedBox(height: 60),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2025 MediScan Intelligence Ltd.',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.twitter, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 20),
                      Icon(LucideIcons.linkedin, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 20),
                      Icon(LucideIcons.instagram, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(IconData icon, String text, bool isSelected, ThemeProvider? provider, bool isDarkBg) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          provider?.toggleTheme();
        }
      },
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDarkBg ? Colors.white : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected 
                  ? (isDarkBg ? Colors.black : Colors.black) 
                  : (isDarkBg ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected 
                  ? (isDarkBg ? Colors.black : Colors.black) 
                  : (isDarkBg ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerColumn(String title, List<String> links, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onHover: (val) {}, // Placeholder for future simple hover
            onTap: () {},
            child: Text(
              link,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  // Helper Widgets
  Widget _pillBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF39A4E6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          color: const Color(0xFF39A4E6),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navButton(String text, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc, bool isDark) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? [] : [
           BoxShadow(
             color: Colors.black.withOpacity(0.03),
             blurRadius: 20,
             offset: const Offset(0, 10),
           ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF39A4E6), size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }
  
  Widget _checkListItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle, color: Color(0xFF39A4E6), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF39A4E6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}


enum HoverEffect { shimmer, borderReveal, elevationGlow }

class _HoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDark;
  final Color? customBgColor;
  final Color? customTextColor;
  final EdgeInsetsGeometry padding;
  final HoverEffect effect;

  const _HoverButton({
    required this.text,
    required this.onTap,
    this.isPrimary = true,
    required this.isDark,
    this.customBgColor,
    this.customTextColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    HoverEffect? effect,
  }) : effect = effect ?? (isPrimary ? HoverEffect.shimmer : HoverEffect.borderReveal);

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Base Colors
    final Color brandColor = const Color(0xFF39A4E6);
    final Color baseBgColor = widget.customBgColor ?? (widget.isPrimary ? brandColor : Colors.transparent);
    
    // Border color logic - secondary button needs a clear border in light/dark
    final Color baseBorderColor = widget.isPrimary 
        ? Colors.transparent 
        : (widget.isDark ? Colors.white24 : Colors.black12);
    
    final Color activeBorderColor = widget.isPrimary 
        ? Colors.transparent 
        : brandColor;

    final Color baseTextColor = widget.customTextColor ?? (
        widget.isPrimary 
          ? Colors.white 
          : (widget.isDark ? Colors.white : Colors.black87)
    );
    
    // Fix: activeTextColor should respect customTextColor if provided
    final Color activeTextColor = widget.customTextColor ?? (
        widget.isPrimary 
          ? Colors.white 
          : brandColor
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (widget.effect == HoverEffect.shimmer) {
          _controller.repeat();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (widget.effect == HoverEffect.shimmer) {
          _controller.reset();
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.effect == HoverEffect.borderReveal && _isHovered 
                    ? brandColor.withOpacity(0.05) 
                    : baseBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isHovered ? activeBorderColor : baseBorderColor,
                  width: _isHovered && widget.effect == HoverEffect.borderReveal ? 2.0 : 1.5,
                ),
                boxShadow: [
                  if (_isHovered && widget.isPrimary)
                    BoxShadow(
                      color: brandColor.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  if (_isHovered && widget.effect == HoverEffect.borderReveal)
                    BoxShadow(
                      color: brandColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  if (_isHovered && widget.effect == HoverEffect.elevationGlow)
                    BoxShadow(
                      color: brandColor.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // EFFECT: Elevation Glow (Expanding Shadow)
                    // (This is primarily handled by the decoration's boxShadow, 
                    // but we can add a subtle internal tint here)
                    if (widget.effect == HoverEffect.elevationGlow)
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: _isHovered 
                              ? brandColor.withOpacity(0.04) 
                              : Colors.transparent,
                        ),
                      ),

                    // Text Layer
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.outfit(
                        color: _isHovered && widget.effect == HoverEffect.borderReveal 
                            ? activeTextColor 
                            : baseTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Text(widget.text),
                    ),

                    // EFFECT: Neon Shimmer (Primary)
                    if (widget.effect == HoverEffect.shimmer && _isHovered)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Transform.translate(
                              offset: Offset(
                                -constraints.maxWidth + (constraints.maxWidth * 3 * _controller.value),
                                0,
                              ),
                              child: Transform.rotate(
                                angle: 0.5,
                                child: Container(
                                  width: constraints.maxWidth / 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.35),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.2, 0.5, 0.8],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
