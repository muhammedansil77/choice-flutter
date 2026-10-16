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

  // Staggered Animation Tracks (Total ~2.2s cinematic intro)
  late Animation<double> _glowIntensity;
  late Animation<double> _baseFade;
  late Animation<double> _baseScale;

  late Animation<double> _emblemFade;
  late Animation<double> _emblemScale;
  late Animation<double> _electricPulseProgress;
  late Animation<double> _electricPulseOpacity;

  late Animation<double> _choiceFade;
  late Animation<double> _choiceSlide;

  late Animation<double> _elecFade;
  late Animation<double> _elecScaleX;

  late Animation<double> _fullLogoFade;
  late Animation<double> _sweepProgress;
  late Animation<double> _sweepOpacity;

  bool _isImagesPrecached = false;

  @override
  void initState() {
    super.initState();

    // Dark luxury status and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF030406),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 1. Radial ambient gold glow & Base squircle (0.00 -> 0.32)
    _glowIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
      ),
    );
    _baseFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOut),
      ),
    );
    _baseScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Electrical C + Plug Emblem: Fade in & scale 90% -> 100% (0.12 -> 0.46)
    _emblemFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.12, 0.42, curve: Curves.easeOut),
      ),
    );
    _emblemScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.12, 0.46, curve: Curves.easeOutCubic),
      ),
    );

    // 2b. Electric Pulse traveling through plug & cable (0.30 -> 0.54)
    _electricPulseProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.30, 0.54, curve: Curves.easeInOut),
      ),
    );
    _electricPulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.95), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 0.0), weight: 60),
    ]).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.30, 0.54, curve: Curves.easeInOut),
      ),
    );

    // 3. "choice" text: Smooth fade + upward movement (0.44 -> 0.68)
    _choiceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.44, 0.66, curve: Curves.easeOut),
      ),
    );
    _choiceSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.44, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 4. "ELECTRICALS": Fade + subtle tracking expansion (0.58 -> 0.78)
    _elecFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.58, 0.76, curve: Curves.easeOut),
      ),
    );
    _elecScaleX = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.58, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    // 5. Full unaltered original logo crossfade (0.70 -> 0.78)
    _fullLogoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.70, 0.78, curve: Curves.easeInOut),
      ),
    );

    // 6. Subtle Gold Light Sweep across complete logo (0.72 -> 0.90)
    _sweepProgress = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.72, 0.90, curve: Curves.easeInOutCubic),
      ),
    );
    _sweepOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.55), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.55, end: 0.55), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.55, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.72, 0.90, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
    _initializeAndNavigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImagesPrecached) {
      _isImagesPrecached = true;
      precacheImage(const AssetImage('assets/images/logo.png'), context);
      precacheImage(const AssetImage('assets/images/splash_base.png'), context);
      precacheImage(const AssetImage('assets/images/splash_emblem.png'), context);
      precacheImage(const AssetImage('assets/images/splash_choice.png'), context);
      precacheImage(const AssetImage('assets/images/splash_electricals.png'), context);
    }
  }

  Future<void> _initializeAndNavigate() async {
    final apiService = context.read<ApiService>();

    try {
      // Concurrently initialize auth and ensure minimum 2.3s splash experience
      final results = await Future.wait([
        apiService.loadPersistedToken(),
        SharedPreferences.getInstance(),
        Future.delayed(const Duration(milliseconds: 2350)),
      ]);

      if (!mounted) return;

      final bool hasTokenInService = results[0] as bool;
      final prefs = results[1] as SharedPreferences;
      final bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
      final String? savedToken = prefs.getString('token');

      final bool isUserLoggedIn = hasTokenInService || (savedToken != null && savedToken.trim().isNotEmpty);

      Widget destination;
      if (isUserLoggedIn) {
        destination = const HomeScreen();
      } else if (!onboardingCompleted) {
        destination = const OnboardingScreen();
      } else {
        destination = const LoginScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, __) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
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
    const Color goldAccent = Color(0xFFE5A93C);

    return Scaffold(
      backgroundColor: const Color(0xFF030406),
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF030406),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.90,
                colors: [
                  goldAccent.withValues(alpha: 0.08 * _glowIntensity.value),
                  const Color(0xFF13100A).withValues(alpha: 0.28 * _glowIntensity.value),
                  const Color(0xFF06070A),
                  const Color(0xFF030406),
                ],
                stops: const [0.0, 0.40, 0.72, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive sizing preserving exact 1:1 aspect ratio across all devices
                    final double size = (constraints.maxWidth * 0.50).clamp(185.0, 225.0);

                    return SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. BASE SQUIRCLE WITH SUBTLE GLOW SHADOW
                          Opacity(
                            opacity: _baseFade.value,
                            child: Transform.scale(
                              scale: _baseScale.value,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(size * 0.20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldAccent.withValues(alpha: 0.16 * _glowIntensity.value),
                                      blurRadius: 36,
                                      offset: const Offset(0, 12),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(size * 0.20),
                                  child: Image.asset(
                                    'assets/images/splash_base.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. EMBLEM: ELECTRICAL C + PLUG (FADE IN + SCALE 90% -> 100%)
                          if (_emblemFade.value > 0.0)
                            Opacity(
                              opacity: _emblemFade.value,
                              child: Transform.scale(
                                scale: _emblemScale.value,
                                child: SizedBox(
                                  width: size,
                                  height: size,
                                  child: Image.asset(
                                    'assets/images/splash_emblem.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            ),

                          // 2b. SUBTLE GOLDEN LIGHT / ELECTRIC PULSE TRAVELING THROUGH PLUG & CABLE
                          if (_electricPulseOpacity.value > 0.0)
                            Opacity(
                              opacity: _electricPulseOpacity.value,
                              child: Transform.scale(
                                scale: _emblemScale.value,
                                child: ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) {
                                    final double p = _electricPulseProgress.value;
                                    return LinearGradient(
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                      stops: [
                                        (p - 0.25).clamp(0.0, 1.0),
                                        p.clamp(0.0, 1.0),
                                        (p + 0.25).clamp(0.0, 1.0),
                                      ],
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFFFFF2B8).withValues(alpha: 0.90),
                                        Colors.transparent,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Image.asset(
                                    'assets/images/splash_emblem.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                          // 3. "choice" TEXT (SMOOTH FADE + SLIGHT UPWARD MOTION)
                          if (_choiceFade.value > 0.0)
                            Transform.translate(
                              offset: Offset(0, _choiceSlide.value),
                              child: Opacity(
                                opacity: _choiceFade.value,
                                child: SizedBox(
                                  width: size,
                                  height: size,
                                  child: Image.asset(
                                    'assets/images/splash_choice.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            ),

                          // 4. "ELECTRICALS" (FADE + SUBTLE TRACKING/LETTER-SPACING EFFECT)
                          if (_elecFade.value > 0.0)
                            Transform.scale(
                              scaleX: _elecScaleX.value,
                              scaleY: 1.0,
                              child: Opacity(
                                opacity: _elecFade.value,
                                child: SizedBox(
                                  width: size,
                                  height: size,
                                  child: Image.asset(
                                    'assets/images/splash_electricals.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            ),

                          // 5. COMPLETE ORIGINAL LOGO OVERLAY (Ensures 100% exact original artwork)
                          if (_fullLogoFade.value > 0.0)
                            Opacity(
                              opacity: _fullLogoFade.value,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(size * 0.20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(size * 0.20),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            ),

                          // 6. VERY SUBTLE GOLD METALLIC LIGHT SWEEP ACROSS COMPLETE LOGO
                          if (_sweepOpacity.value > 0.0)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(size * 0.20),
                              child: Opacity(
                                opacity: _sweepOpacity.value,
                                child: ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) {
                                    final double sp = _sweepProgress.value;
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [
                                        (sp - 0.22).clamp(0.0, 1.0),
                                        sp.clamp(0.0, 1.0),
                                        (sp + 0.22).clamp(0.0, 1.0),
                                      ],
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFFFFE8A3).withValues(alpha: 0.50),
                                        Colors.transparent,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: size,
                                    height: size,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
