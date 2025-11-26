import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isSkipPressed = false;
  bool _isButtonPressed = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding1.png',
      title: 'Scan & Upload Reports',
      description:
          'Quickly capture your medical documents, lab results, and prescriptions with your camera. Upload PDFs or images in seconds to your secure digital vault.',
      gradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
    OnboardingData(
      image: 'assets/images/onboarding2.png',
      title: 'Extract Key Information',
      description:
          'Our smart AI automatically extracts important details like dates, diagnoses, medications, and test results. No more manual data entry required.',
      gradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
    OnboardingData(
      image: 'assets/images/onboarding3.png',
      title: 'Track Your Health Journey',
      description:
          'View your complete medical timeline in one place. Share reports securely with doctors, family, or healthcare providers whenever needed.',
      gradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onSkipPressed() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pages[_currentPage].gradient,
          ),
        ),
        child: Stack(
          children: [
            // Background animated elements
            _buildAnimatedBackground(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Skip Button with press effect
                  if (_currentPage < _pages.length - 1)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, right: 20),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isSkipPressed = true),
                          onTapUp: (_) => setState(() => _isSkipPressed = false),
                          onTapCancel: () => setState(() => _isSkipPressed = false),
                          onTap: _onSkipPressed,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSkipPressed
                                  ? const Color(0xFF39A4E6).withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 150),
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF39A4E6),
                                    fontSize: _isSkipPressed ? 17 : 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  child: const Text('Skip'),
                                ),
                                const SizedBox(width: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  transform: Matrix4.translationValues(
                                    _isSkipPressed ? 4 : 0,
                                    0,
                                    0,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: const Color(0xFF39A4E6),
                                    size: _isSkipPressed ? 20 : 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 400))
                            .slideX(begin: 0.2, end: 0),
                      ),
                    )
                  else
                    const SizedBox(height: 60),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPage(
                          data: _pages[index],
                          isActive: index == _currentPage,
                        );
                      },
                    ),
                  ),

                  // Page Indicator - Modern Design
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = index == _currentPage;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isActive ? 32 : 8,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF39A4E6) : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF39A4E6).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Next/Get Started Button - with press effects
                  Padding(
                    padding: const EdgeInsets.only(left: 32, right: 32, bottom: 48, top: 16),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) {
                        setState(() => _isButtonPressed = false);
                        _onNextPressed();
                      },
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        height: 56,
                        transform: Matrix4.diagonal3Values(
                          _isButtonPressed ? 0.98 : 1.0,
                          _isButtonPressed ? 0.98 : 1.0,
                          1.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isButtonPressed
                                ? [const Color(0xFF2B8FD9), const Color(0xFF1B7AC9)]
                                : [const Color(0xFF39A4E6), const Color(0xFF2B8FD9)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF39A4E6).withValues(
                                alpha: _isButtonPressed ? 0.7 : 0.4,
                              ),
                              blurRadius: _isButtonPressed ? 35 : 20,
                              spreadRadius: _isButtonPressed ? 5 : 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                            style: GoogleFonts.openSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 600))
                        .slideY(begin: 0.3, end: 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Animated gradient orbs
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF39A4E6).withValues(alpha: 0.4),
                  const Color(0xFF2B8FD9).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveX(begin: 0, end: 50, duration: const Duration(seconds: 8))
              .moveY(begin: 0, end: 30, duration: const Duration(seconds: 8))
              .scaleXY(begin: 1, end: 1.2, duration: const Duration(seconds: 8)),
        ),

        Positioned(
          bottom: -128,
          right: -128,
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF39A4E6).withValues(alpha: 0.4),
                  const Color(0xFF2B8FD9).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveX(begin: 0, end: -30, duration: const Duration(seconds: 10))
              .moveY(begin: 0, end: -50, duration: const Duration(seconds: 10))
              .scaleXY(begin: 1, end: 1.3, duration: const Duration(seconds: 10)),
        ),

        // Floating geometric shapes
        ..._buildFloatingShapes(),

        // Animated dots pattern
        ..._buildAnimatedDots(),

        // Medical cross particles
        ..._buildMedicalCrossParticles(),

        // Glassmorphism floating cards
        ..._buildGlassmorphismCards(),

        // Morphing blob shapes
        ..._buildMorphingBlobs(),
      ],
    );
  }

  List<Widget> _buildFloatingShapes() {
    return [
      Positioned(
        top: 80,
        left: MediaQuery.of(context).size.width * 0.15,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF39A4E6).withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: 0, end: -30, duration: const Duration(seconds: 6))
            .rotate(begin: 0, end: 0.25, duration: const Duration(seconds: 6))
            .scaleXY(begin: 1, end: 1.1, duration: const Duration(seconds: 6)),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.33,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF39A4E6).withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: 0, end: 25, duration: const Duration(seconds: 7))
            .rotate(begin: 0, end: -0.33, duration: const Duration(seconds: 7))
            .scaleXY(begin: 1, end: 0.9, duration: const Duration(seconds: 7)),
      ),
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.25,
        left: MediaQuery.of(context).size.width * 0.12,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: 0, end: -20, duration: const Duration(seconds: 8))
            .moveX(begin: 0, end: 15, duration: const Duration(seconds: 8))
            .scaleXY(begin: 1, end: 1.15, duration: const Duration(seconds: 8)),
      ),
    ];
  }

  List<Widget> _buildAnimatedDots() {
    return List.generate(12, (i) {

      return Positioned(
        top: (i * 27) % 100 / 100 * MediaQuery.of(context).size.height,
        left: (i * 43) % 100 / 100 * MediaQuery.of(context).size.width,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF39A4E6).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(
              begin: 1,
              end: 1.5,
              duration: Duration(milliseconds: 4000 + (i % 3) * 1000),
              delay: Duration(milliseconds: i * 200),
            )
            .custom(
              duration: Duration(milliseconds: 4000 + (i % 3) * 1000),
              delay: Duration(milliseconds: i * 200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 0.2 + (value * 0.2),
                  child: child,
                );
              },
            )
            .moveY(
              begin: 0,
              end: -20,
              duration: Duration(milliseconds: 4000 + (i % 3) * 1000),
              delay: Duration(milliseconds: i * 200),
            ),
      );
    });
  }

  List<Widget> _buildMedicalCrossParticles() {
    return List.generate(5, (i) {
      return Positioned(
        top: ((i * 23 + 10) % 90) / 100 * MediaQuery.of(context).size.height,
        left: ((i * 37 + 5) % 90) / 100 * MediaQuery.of(context).size.width,
        child: Icon(
          Icons.add,
          size: 32,
          color: const Color(0xFF39A4E6).withValues(alpha: 0.15),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -40,
              duration: Duration(seconds: 8 + i),
              delay: Duration(milliseconds: i * 500),
            )
            .rotate(
              begin: 0,
              end: 1,
              duration: Duration(seconds: 8 + i),
              delay: Duration(milliseconds: i * 500),
            )
            .scaleXY(
              begin: 1,
              end: 1.2,
              duration: Duration(seconds: 8 + i),
              delay: Duration(milliseconds: i * 500),
            )
            .custom(
              duration: Duration(seconds: 8 + i),
              delay: Duration(milliseconds: i * 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 0.1 + (value * 0.2),
                  child: child,
                );
              },
            ),
      );
    });
  }

  List<Widget> _buildGlassmorphismCards() {
    return [
      Positioned(
        top: MediaQuery.of(context).size.height * 0.15,
        left: MediaQuery.of(context).size.width * 0.08,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF39A4E6).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF39A4E6).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF39A4E6).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: 0, end: -15, duration: const Duration(seconds: 6))
            .moveX(begin: 0, end: 10, duration: const Duration(seconds: 6))
            .rotate(begin: 0, end: 0.014, duration: const Duration(seconds: 6)),
      ),
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.35,
        right: MediaQuery.of(context).size.width * 0.08,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF39A4E6).withValues(alpha: 0.4),
                    const Color(0xFF2B8FD9).withValues(alpha: 0.4),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.2, duration: const Duration(seconds: 2)),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: 0, end: 20, duration: const Duration(seconds: 7))
            .moveX(begin: 0, end: -8, duration: const Duration(seconds: 7))
            .rotate(begin: 0, end: -0.014, duration: const Duration(seconds: 7)),
      ),
    ];
  }

  List<Widget> _buildMorphingBlobs() {
    return [
      Positioned(
        top: MediaQuery.of(context).size.height * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .custom(
              duration: const Duration(seconds: 10),
              builder: (context, value, child) {
                return Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                    ),
                    borderRadius: BorderRadius.circular(40 + value * 20),
                  ),
                );
              },
            )
            .rotate(begin: 0, end: 1, duration: const Duration(seconds: 10))
            .custom(
              duration: const Duration(seconds: 10),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value * 0.1,
                  child: child,
                );
              },
            ),
      ),
    ];
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Illustration with glow and floating animation
          Stack(
            alignment: Alignment.center,
            children: [
              // Decorative glow behind image
              Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF39A4E6).withValues(alpha: 0.2),
                      const Color(0xFF2B8FD9).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .scaleXY(begin: 0.8, end: 1, duration: const Duration(milliseconds: 600)),

              // Main illustration - no background
              SizedBox(
                width: 350,
                height: 350,
                child: Center(
                  child: Image.asset(
                    data.image,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                  )
                  .then()
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -10,
                    duration: const Duration(milliseconds: 3000),
                    curve: Curves.easeInOut,
                  ),

              // Sparkle effects
              ...List.generate(6, (i) {
                final random = math.Random(i);
                return Positioned(
                  top: random.nextDouble() * 280 + 35,
                  left: random.nextDouble() * 280 + 35,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF39A4E6),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scaleXY(
                        begin: 0,
                        end: 1,
                        duration: const Duration(milliseconds: 1000),
                        delay: Duration(milliseconds: 500 + i * 200),
                      )
                      .then()
                      .scaleXY(
                        begin: 1,
                        end: 0,
                        duration: const Duration(milliseconds: 1000),
                      )
                      .fadeIn(
                        duration: const Duration(milliseconds: 1000),
                        delay: Duration(milliseconds: 500 + i * 200),
                      )
                      .then()
                      .fadeOut(duration: const Duration(milliseconds: 1000)),
                );
              }),
            ],
          ),

          const SizedBox(height: 48),

          // Title with shimmer effect
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF39A4E6),
              letterSpacing: 0.3,
              height: 1.3,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 600),
              )
              .slideY(
                begin: 0.3,
                end: 0,
                duration: const Duration(milliseconds: 600),
              )
              .shimmer(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 1500),
                color: const Color(0xFF39A4E6).withValues(alpha: 0.3),
              ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoCondensed(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.7,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w400,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 600),
              )
              .slideY(
                begin: 0.3,
                end: 0,
                duration: const Duration(milliseconds: 600),
              ),

          const SizedBox(height: 32),
        ],
      ),
    ),
  );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;
  final List<Color> gradient;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
