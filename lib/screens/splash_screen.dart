import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Premium Modern Splash Screen for CHOICE IRULAM
/// Design Direction:
/// - Navy-Blue & Metallic-Gold Palette:
///   • Primary background: #10243A
///   • Secondary background: #183653
///   • Primary gold: #D4AF62
///   • Highlight gold: #F5E6B8
///   • White: #FFFFFF
/// - Subtle navy gradient with soft golden radial glow behind the logo
/// - Small number of subtle gold particles gently converging towards the center
/// - Smooth fade and scale reveal of the existing CHOICE IRULAM logo
/// - Gentle golden highlight sweep across the logo
/// - Seamless 1.8-second transition into the ready application
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<_SubtleParticle> _particles;

  // Animation Curves
  late final Animation<double> _glowFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _sheenProgress;

  bool _isImagesPrecached = false;

  // Exact Brand Colors
  static const Color primaryBg = Color(0xFF10243A);
  static const Color secondaryBg = Color(0xFF183653);
  static const Color primaryGold = Color(0xFFD4AF62);
  static const Color highlightGold = Color(0xFFF5E6B8);
  static const Color pureWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    // Premium Navy status bar & navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: primaryBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1.8-second lightweight, fluid animation timeline
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Phase 1 (0.05 to 0.45): Soft radial glow fades in behind the center
    _glowFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
    );

    // Phase 2 (0.22 to 0.62): Logo fades and scales smoothly into view
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.22, 0.60, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.22, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 3 (0.55 to 0.88): Subtle golden highlight glint sweeps across the logo
    _sheenProgress = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 0.88, curve: Curves.easeInOutCubic),
    );

    // Generate 24 delicate, non-distracting gold particles
    _particles = _generateParticles(24);

    _animController.forward();
    _initializeAndNavigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImagesPrecached) {
      _isImagesPrecached = true;
      precacheImage(const AssetImage('assets/images/choice_irulam_logo.png'), context);
    }
  }

  /// Generate subtle gold particles distributed naturally around the logo center
  List<_SubtleParticle> _generateParticles(int count) {
    final rand = math.Random(42);
    final List<_SubtleParticle> list = [];

    const colors = [
      primaryGold,
      highlightGold,
      pureWhite,
    ];

    for (int i = 0; i < count; i++) {
      // Angle around center
      final double angle = (i / count) * 2 * math.pi + (rand.nextDouble() - 0.5) * 0.4;
      // Start distance from center (130 to 240 px)
      final double startDist = 130.0 + rand.nextDouble() * 110.0;
      // Target distance (gently floating inward to 65-125 px)
      final double targetDist = 65.0 + rand.nextDouble() * 60.0;

      final double radius = 1.2 + rand.nextDouble() * 2.2;
      final Color color = colors[rand.nextInt(colors.length)];
      final double baseAlpha = 0.35 + rand.nextDouble() * 0.45;
      final double entryDelay = rand.nextDouble() * 0.25;

      list.add(
        _SubtleParticle(
          angle: angle,
          startDist: startDist,
          targetDist: targetDist,
          radius: radius,
          color: color,
          baseAlpha: baseAlpha,
          entryDelay: entryDelay,
          phase: rand.nextDouble() * math.pi * 2,
        ),
      );
    }

    return list;
  }

  /// Preserve all existing authentication checks, startup data loading and navigation
  Future<void> _initializeAndNavigate() async {
    final apiService = context.read<ApiService>();

    try {
      // Concurrently run authentication check and 1850ms target timing
      final results = await Future.wait([
        apiService.loadPersistedToken(),
        SharedPreferences.getInstance(),
        Future.delayed(const Duration(milliseconds: 1850)),
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
      backgroundColor: primaryBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Subtle Navy Gradient Background (#10243A -> #183653)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryBg,
                  secondaryBg,
                ],
              ),
            ),
          ),

          // 2. Soft Golden Radial Glow behind the Logo
          AnimatedBuilder(
            animation: _glowFade,
            builder: (context, _) {
              if (_glowFade.value <= 0.001) return const SizedBox.shrink();
              return Center(
                child: Opacity(
                  opacity: _glowFade.value,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryGold.withValues(alpha: 0.18),
                          highlightGold.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Subtle Inward-Floating Golden Particles
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SubtleParticlePainter(
                    progress: _animController.value,
                    particles: _particles,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 4. Centered CHOICE IRULAM Logo with Fade, Scale & Golden Highlight
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  if (_logoFade.value <= 0.001) {
                    return const SizedBox.shrink();
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenW = constraints.maxWidth;
                      final double logoWidth = (screenW * 0.64).clamp(230.0, 290.0);

                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Stable High-Resolution Logo
                              Image.asset(
                                'assets/images/choice_irulam_logo.png',
                                width: logoWidth,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),

                              // Elegant Golden Highlight Sweep (Phase 3)
                              if (_sheenProgress.value > 0.001 && _sheenProgress.value < 0.999)
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    final double t = _sheenProgress.value;
                                    final double startX = -1.6 + (t * 3.2);
                                    final double endX = -0.4 + (t * 3.2);
                                    return LinearGradient(
                                      begin: Alignment(startX, -0.7),
                                      end: Alignment(endX, 0.7),
                                      colors: [
                                        Colors.transparent,
                                        highlightGold.withValues(alpha: 0.40),
                                        pureWhite.withValues(alpha: 0.75),
                                        highlightGold.withValues(alpha: 0.40),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.38, 0.50, 0.62, 1.0],
                                    ).createShader(bounds);
                                  },
                                  child: Image.asset(
                                    'assets/images/choice_irulam_logo.png',
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                    color: Colors.white,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight Particle Model
class _SubtleParticle {
  final double angle;
  final double startDist;
  final double targetDist;
  final double radius;
  final Color color;
  final double baseAlpha;
  final double entryDelay;
  final double phase;

  const _SubtleParticle({
    required this.angle,
    required this.startDist,
    required this.targetDist,
    required this.radius,
    required this.color,
    required this.baseAlpha,
    required this.entryDelay,
    required this.phase,
  });
}

/// High-Performance Lightweight Particle Canvas Painter
class _SubtleParticlePainter extends CustomPainter {
  final double progress;
  final List<_SubtleParticle> particles;

  _SubtleParticlePainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.04) return;

    final double centerX = size.width * 0.5;
    final double centerY = size.height * 0.5;
    final Paint paint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      if (progress < p.entryDelay) continue;

      // Particle entry motion (0.0 to 1.0)
      final double moveProgress = ((progress - p.entryDelay) / 0.55).clamp(0.0, 1.0);
      final double moveEase = Curves.easeOutCubic.transform(moveProgress);

      // Distance from center smoothly decreases inward towards the logo
      final double currentDist = p.startDist - ((p.startDist - p.targetDist) * moveEase);

      // Gentle organic drift
      final double angleDrift = math.sin((progress * 4.0) + p.phase) * 0.08;
      final double currentAngle = p.angle + angleDrift;

      final double px = centerX + math.cos(currentAngle) * currentDist;
      final double py = centerY + math.sin(currentAngle) * currentDist;

      // Smooth fade in, then gentle settle
      double alpha = p.baseAlpha;
      if (moveProgress < 0.35) {
        alpha *= (moveProgress / 0.35);
      }

      // Gently soften particles as logo becomes fully stable
      if (progress > 0.65) {
        final double fadeOut = ((progress - 0.65) / 0.30).clamp(0.0, 1.0);
        alpha *= (1.0 - fadeOut * 0.60);
      }

      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
