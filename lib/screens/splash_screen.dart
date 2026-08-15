import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  // Staggered Animations
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;
  late Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    // Set transparent status bar with dark icons for crisp white theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // 1. Icon scales & fades in (0.0 -> 0.55)
    _iconScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    // 2. "CHOICE ELECTRICALS" slides & fades in (0.35 -> 0.75)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 3. "POS APP" badge slides & fades in (0.55 -> 0.92)
    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _badgeSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Loading dots fade in (0.65 -> 1.0)
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Total startup display time (~1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    final apiService = context.read<ApiService>();

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

      if (!mounted) return;

      if (apiService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (!onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Brand Color Palette
    const Color primaryBlue = Color(0xFF087FEF);
    const Color darkNavy = Color(0xFF0B3B82);
    const Color lightBlueBg = Color(0xFFEFF6FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  const Spacer(flex: 3),

                  // 1. Minimal Electrical Icon Emblem
                  FadeTransition(
                    opacity: _iconFade,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryBlue,
                              darkNavy,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle electrical spark ring
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Sharp Electrical Bolt
                              const Icon(
                                Icons.bolt_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. CHOICE ELECTRICALS Title
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        'CHOICE ELECTRICALS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: darkNavy,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. POS APP Subtitle Badge
                  FadeTransition(
                    opacity: _badgeFade,
                    child: SlideTransition(
                      position: _badgeSlide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'POS APP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 4. Subtle 3-Dot Loading Indicator near bottom
                  FadeTransition(
                    opacity: _dotsFade,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: _PulsingDotsIndicator(color: primaryBlue),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Subtle Animated 3-Dot Indicator (`• • •`)
class _PulsingDotsIndicator extends StatefulWidget {
  final Color color;

  const _PulsingDotsIndicator({required this.color});

  @override
  State<_PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
}

class _PulsingDotsIndicatorState extends State<_PulsingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double progress = ((_controller.value + (index * 0.3)) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.25 + (progress * 0.75)),
              ),
            );
          }),
        );
      },
    );
  }
}
