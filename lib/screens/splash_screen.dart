import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Premium, Minimal, Modern Splash Screen for CHOICE IRULAM
/// - Background: Deep Royal Blue (#102A43)
/// - Main Wordmark: White (#FFFFFF)
/// - Accent: Electric Blue (#38BDF8)
/// - Subtle Glow: Soft Blue (#60A5FA)
/// - Integrated tasteful lightning detail into the letter "C"
/// - Elegant sequential animation:
///   1. Royal Blue background
///   2. Fade in CHOICE wordmark
///   3. Subtle electric-blue highlight sweeps across the logo
///   4. Smooth reveal of IRULAM underneath
///   5. Gentle scale 0.92 -> 1.0
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Staggered Animations
  late final Animation<double> _logoScale;
  late final Animation<double> _choiceFade;
  late final Animation<double> _glowFade;
  late final Animation<double> _shimmerProgress;
  late final Animation<double> _irulamFade;
  late final Animation<Offset> _irulamSlide;

  // Color Palette Constants
  static const Color bgRoyalBlue = Color(0xFF102A43);
  static const Color darkRoyalBlue = Color(0xFF0C2135);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF38BDF8);
  static const Color softBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();

    // Set dark royal blue system status & navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bgRoyalBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Gentle logo scale from 0.92 to 1.0
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Fade in CHOICE wordmark & subtle background glow
    _choiceFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.10, 0.42, curve: Curves.easeOut),
    );

    _glowFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.10, 0.50, curve: Curves.easeOut),
    );

    // 3. Subtle electric blue highlight sweeps across the logo
    _shimmerProgress = Tween<double>(begin: -0.30, end: 1.30).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.38, 0.72, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Reveal IRULAM smoothly underneath
    _irulamFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.56, 0.84, curve: Curves.easeOut),
    );

    _irulamSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.56, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
    _initializeAndNavigate();
  }

  /// Concurrently load auth/onboarding states while running the 2.7s animation
  Future<void> _initializeAndNavigate() async {
    final apiService = context.read<ApiService>();

    try {
      final results = await Future.wait([
        apiService.loadPersistedToken(),
        SharedPreferences.getInstance(),
        Future.delayed(const Duration(milliseconds: 2700)),
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
    return Scaffold(
      backgroundColor: bgRoyalBlue,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: bgRoyalBlue,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  softBlue.withValues(alpha: 0.18 * _glowFade.value),
                  electricBlue.withValues(alpha: 0.08 * _glowFade.value),
                  bgRoyalBlue,
                  darkRoyalBlue,
                ],
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenW = constraints.maxWidth;

                    // Responsive geometric typography sizing
                    final double choiceFontSize = (screenW * 0.118).clamp(36.0, 48.0);
                    final double choiceSpacing = (screenW * 0.022).clamp(6.5, 9.0);
                    final double irulamFontSize = (screenW * 0.040).clamp(13.0, 16.5);
                    final double irulamSpacing = (screenW * 0.034).clamp(10.0, 14.5);
                    final double verticalGap = (screenW * 0.030).clamp(10.0, 14.0);

                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. "CHOICE" Main Wordmark with Integrated Lightning C
                          Opacity(
                            opacity: _choiceFade.value,
                            child: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) {
                                final double p = _shimmerProgress.value;
                                if (p <= -0.25 || p >= 1.25) {
                                  return const LinearGradient(
                                    colors: [textWhite, textWhite],
                                  ).createShader(bounds);
                                }
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [
                                    (p - 0.25).clamp(0.0, 1.0),
                                    (p - 0.08).clamp(0.0, 1.0),
                                    p.clamp(0.0, 1.0),
                                    (p + 0.08).clamp(0.0, 1.0),
                                    (p + 0.25).clamp(0.0, 1.0),
                                  ],
                                  colors: const [
                                    textWhite,
                                    electricBlue,
                                    Color(0xFFE0F2FE),
                                    electricBlue,
                                    textWhite,
                                  ],
                                ).createShader(bounds);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Distinctive C with Integrated Electric Blue Lightning
                                  _buildCWithLightning(choiceFontSize),
                                  SizedBox(width: choiceSpacing * 0.6),
                                  // Remaining bold letters
                                  Text(
                                    'HOICE',
                                    style: TextStyle(
                                      fontSize: choiceFontSize,
                                      fontWeight: FontWeight.w900,
                                      color: textWhite,
                                      fontFamily: 'sans-serif',
                                      letterSpacing: choiceSpacing,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: electricBlue.withValues(alpha: 0.35),
                                          blurRadius: 18,
                                        ),
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.50),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: verticalGap),

                          // 2. "IRULAM" Clean Subtitle Directly Underneath
                          FadeTransition(
                            opacity: _irulamFade,
                            child: SlideTransition(
                              position: _irulamSlide,
                              child: Text(
                                'IRULAM',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: irulamFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: textWhite,
                                  fontFamily: 'sans-serif',
                                  letterSpacing: irulamSpacing,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: electricBlue.withValues(alpha: 0.55),
                                      blurRadius: 14,
                                    ),
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.40),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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

  /// Distinctive letter "C" with a small, tasteful electric-blue lightning detail
  Widget _buildCWithLightning(double fontSize) {
    final double width = fontSize * 0.78;
    final double height = fontSize;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Base white geometric "C"
          Text(
            'C',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: textWhite,
              fontFamily: 'sans-serif',
              height: 1.0,
              shadows: [
                Shadow(
                  color: electricBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),

          // Small, tasteful electric blue lightning detail nested inside the C
          Positioned(
            right: width * 0.08,
            top: height * 0.24,
            child: CustomPaint(
              size: Size(width * 0.44, height * 0.52),
              painter: const _LightningBoltPainter(
                color: electricBlue,
                glowColor: softBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sharp, modern electric-blue lightning bolt accent
class _LightningBoltPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  const _LightningBoltPainter({
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Geometric lightning bolt path
    final path = Path()
      ..moveTo(w * 0.72, 0.0)             // Top arm
      ..lineTo(w * 0.12, h * 0.54)         // Zag down-left
      ..lineTo(w * 0.54, h * 0.50)         // Jog up-right
      ..lineTo(w * 0.22, h * 1.0)          // Sharp dart tip
      ..lineTo(w * 0.92, h * 0.42)         // Return zag
      ..lineTo(w * 0.50, h * 0.45)         // Return jog
      ..close();

    // 1. Soft electric-blue glow behind bolt
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, glowPaint);

    // 2. Sharp electric-blue solid core
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, corePaint);

    // 3. Crisp white center highlight spine
    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.10).clamp(1.0, 2.0)
      ..strokeCap = StrokeCap.round;

    final spine = Path()
      ..moveTo(w * 0.60, h * 0.12)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.32, h * 0.82);
    canvas.drawPath(spine, spinePaint);
  }

  @override
  bool shouldRepaint(covariant _LightningBoltPainter oldDelegate) => false;
}
