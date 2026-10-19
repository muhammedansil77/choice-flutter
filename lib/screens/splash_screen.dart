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

/// Ultra-Cinematic Luxury Splash Screen for CHOICE IRULAM
/// Masterpiece Design Specifications:
/// - Palette: Midnight Navy (#0B1726 -> #10243A -> #183653) & 24K Metallic Gold (#D4AF62, #F5E6B8)
/// - Multi-layered Depth: Breathing golden radial ambient core + subtle harmonic electric energy rings
/// - Starlight Gold Micro-Particles with natural parallax drift & delicate twinkling
/// - Hero Logo Reveal: CHOICE IRULAM with elastic ease, breathing golden aura & 3D presence
/// - Metallic Sheen Glint: Fluid diagonal light sweep across the golden emblem & lettering
/// - Diamond Star Glint: Luminous lens sparkle igniting at the apex of the golden emblem
/// - Refined Brand Tagline with micro-spaced typography & gold diamond accent
/// - 2.2s fluid pacing transitioning seamlessly into the destination screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<_CinematicParticle> _particles;

  // Staggered Animation Channels
  late final Animation<double> _glowFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _sheenProgress;
  late final Animation<double> _glintProgress;
  late final Animation<double> _taglineFade;

  bool _isImagesPrecached = false;

  // Curated Luxury Color Tokens
  static const Color midnightBase = Color(0xFF0B1726);
  static const Color deepNavy = Color(0xFF10243A);
  static const Color radiantNavy = Color(0xFF183653);
  static const Color primaryGold = Color(0xFFD4AF62);
  static const Color highlightGold = Color(0xFFF5E6B8);
  static const Color pureWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    // High-end Dark Luxury System UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: midnightBase,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 2.2-Second Cinematic Unified Choreography
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 1. Ambient Golden Core Glow
    _glowFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.06, 0.45, curve: Curves.easeOut),
    );

    // 2. Hero Logo Emergence
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.18, 0.52, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.18, 0.58, curve: Curves.easeOutBack),
      ),
    );

    // 3. Metallic Light Sheen Sweep across Logo
    _sheenProgress = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.50, 0.82, curve: Curves.easeInOutCubic),
    );

    // 4. Diamond Star Sparkle at Emblem Apex
    _glintProgress = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.66, 0.88, curve: Curves.easeOut),
    );

    // 5. Luxury Brand Tagline Fade
    _taglineFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.64, 0.90, curve: Curves.easeOut),
    );

    // Generate 32 delicate, multi-depth golden particles
    _particles = _generateParticles(32);

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

  /// Generate 32 layered, organic floating particles with twinkle phases
  List<_CinematicParticle> _generateParticles(int count) {
    final rand = math.Random(77);
    final List<_CinematicParticle> list = [];

    const colors = [
      primaryGold,
      highlightGold,
      Color(0xFFFFEEBA),
      pureWhite,
    ];

    for (int i = 0; i < count; i++) {
      final double angle = (i / count) * 2 * math.pi + (rand.nextDouble() - 0.5) * 0.45;
      final double startDist = 120.0 + rand.nextDouble() * 140.0;
      final double targetDist = 55.0 + rand.nextDouble() * 75.0;

      final double radius = 1.0 + rand.nextDouble() * 2.5;
      final Color color = colors[rand.nextInt(colors.length)];
      final double baseAlpha = 0.30 + rand.nextDouble() * 0.45;
      final double entryDelay = 0.02 + rand.nextDouble() * 0.22;
      final double twinkleSpeed = 8.0 + rand.nextDouble() * 10.0;
      final double driftFreq = 1.2 + rand.nextDouble() * 2.0;

      list.add(
        _CinematicParticle(
          angle: angle,
          startDist: startDist,
          targetDist: targetDist,
          radius: radius,
          color: color,
          baseAlpha: baseAlpha,
          entryDelay: entryDelay,
          twinkleSpeed: twinkleSpeed,
          driftFreq: driftFreq,
          phase: rand.nextDouble() * math.pi * 2,
        ),
      );
    }

    return list;
  }

  /// Concurrently execute auth check and seamless 2.25s cinematic timeline
  Future<void> _initializeAndNavigate() async {
    final apiService = context.read<ApiService>();

    try {
      final results = await Future.wait([
        apiService.loadPersistedToken(),
        SharedPreferences.getInstance(),
        Future.delayed(const Duration(milliseconds: 2250)),
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
          transitionDuration: const Duration(milliseconds: 450),
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
      backgroundColor: midnightBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Multi-Tier Luxury Navy Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.15),
                radius: 1.15,
                colors: [
                  radiantNavy,  // #183653
                  deepNavy,     // #10243A
                  midnightBase, // #0B1726
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 2. Concentric Harmonic Electric Gold Energy Waves
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HarmonicEnergyRingsPainter(
                    progress: _animController.value,
                    ringColor: primaryGold,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 3. Central Ambient Golden Aura Bloom
          AnimatedBuilder(
            animation: _glowFade,
            builder: (context, _) {
              if (_glowFade.value <= 0.001) return const SizedBox.shrink();
              return Center(
                child: Opacity(
                  opacity: _glowFade.value,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryGold.withValues(alpha: 0.22),
                          highlightGold.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.44, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. Floating Starlight Gold Micro-Particles
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CinematicParticleCanvasPainter(
                    progress: _animController.value,
                    particles: _particles,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 5. Centered CHOICE IRULAM Logo & Dynamic Effects
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
                      final double logoWidth = (screenW * 0.68).clamp(230.0, 295.0);

                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Hero Logo Stack with Sheen & Star Sparkle
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Base Ambient Golden Shadow behind Logo
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryGold.withValues(alpha: 0.22 * _logoFade.value),
                                          blurRadius: 42,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/choice_irulam_logo.png',
                                      width: logoWidth,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),

                                  // Golden Metallic Sheen Sweep (Phase 3)
                                  if (_sheenProgress.value > 0.001 && _sheenProgress.value < 0.999)
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) {
                                        final double t = _sheenProgress.value;
                                        final double startX = -1.8 + (t * 3.6);
                                        final double endX = -0.3 + (t * 3.6);
                                        return LinearGradient(
                                          begin: Alignment(startX, -0.7),
                                          end: Alignment(endX, 0.7),
                                          colors: [
                                            Colors.transparent,
                                            highlightGold.withValues(alpha: 0.35),
                                            pureWhite.withValues(alpha: 0.80),
                                            highlightGold.withValues(alpha: 0.35),
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

                                  // Diamond Star Lens Glint at Golden Plug Apex
                                  if (_glintProgress.value > 0.001 && _glintProgress.value < 0.999)
                                    Positioned(
                                      top: logoWidth * 0.22,
                                      right: logoWidth * 0.38,
                                      child: CustomPaint(
                                        painter: _StarGlintPainter(
                                          progress: _glintProgress.value,
                                          color: pureWhite,
                                          glowColor: highlightGold,
                                        ),
                                        size: const Size(36, 36),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // Refined Brand Tagline & Luxury Divider Line
                              Opacity(
                                opacity: _taglineFade.value,
                                child: Column(
                                  children: [
                                    // Elegant hairline divider with center diamond
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                primaryGold.withValues(alpha: 0.6),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '❖',
                                            style: TextStyle(
                                              fontSize: 7,
                                              color: primaryGold.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 38,
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryGold.withValues(alpha: 0.6),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      'PREMIUM ELECTRICAL ACCESSORIES',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.8,
                                        color: highlightGold.withValues(alpha: 0.90),
                                      ),
                                    ),
                                  ],
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

/// Particle Entity with Organic Oscillation Properties
class _CinematicParticle {
  final double angle;
  final double startDist;
  final double targetDist;
  final double radius;
  final Color color;
  final double baseAlpha;
  final double entryDelay;
  final double twinkleSpeed;
  final double driftFreq;
  final double phase;

  const _CinematicParticle({
    required this.angle,
    required this.startDist,
    required this.targetDist,
    required this.radius,
    required this.color,
    required this.baseAlpha,
    required this.entryDelay,
    required this.twinkleSpeed,
    required this.driftFreq,
    required this.phase,
  });
}

/// Canvas Painter for Concentric Harmonic Electric Energy Waves
class _HarmonicEnergyRingsPainter extends CustomPainter {
  final double progress;
  final Color ringColor;

  _HarmonicEnergyRingsPainter({
    required this.progress,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.44;

    // Harmonic Wave 1
    if (progress >= 0.12 && progress <= 0.72) {
      final double t1 = ((progress - 0.12) / 0.60).clamp(0.0, 1.0);
      final double ease1 = Curves.easeOutCubic.transform(t1);
      final double r1 = 55.0 + (ease1 * 125.0);
      final double alpha1 = math.sin(t1 * math.pi) * 0.20;

      final Paint p1 = Paint()
        ..color = ringColor.withValues(alpha: alpha1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawCircle(Offset(cx, cy), r1, p1);
    }

    // Harmonic Wave 2
    if (progress >= 0.26 && progress <= 0.88) {
      final double t2 = ((progress - 0.26) / 0.62).clamp(0.0, 1.0);
      final double ease2 = Curves.easeOutCubic.transform(t2);
      final double r2 = 70.0 + (ease2 * 145.0);
      final double alpha2 = math.sin(t2 * math.pi) * 0.14;

      final Paint p2 = Paint()
        ..color = ringColor.withValues(alpha: alpha2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas.drawCircle(Offset(cx, cy), r2, p2);
    }
  }

  @override
  bool shouldRepaint(covariant _HarmonicEnergyRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Canvas Painter for Shimmering Golden Dust Particles
class _CinematicParticleCanvasPainter extends CustomPainter {
  final double progress;
  final List<_CinematicParticle> particles;

  _CinematicParticleCanvasPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.03) return;

    final double centerX = size.width * 0.5;
    final double centerY = size.height * 0.44;
    final Paint paint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      if (progress < p.entryDelay) continue;

      final double moveProgress = ((progress - p.entryDelay) / 0.52).clamp(0.0, 1.0);
      final double moveEase = Curves.easeOutCubic.transform(moveProgress);

      final double currentDist = p.startDist - ((p.startDist - p.targetDist) * moveEase);
      final double angleDrift = math.sin((progress * p.driftFreq * 4.0) + p.phase) * 0.08;
      final double currentAngle = p.angle + angleDrift;

      final double px = centerX + math.cos(currentAngle) * currentDist;
      final double py = centerY + math.sin(currentAngle) * currentDist;

      // Micro-twinkling oscillation
      final double twinkle = (math.sin((progress * p.twinkleSpeed) + p.phase) + 1.0) * 0.5;
      double alpha = p.baseAlpha * (0.65 + twinkle * 0.35);

      if (moveProgress < 0.30) {
        alpha *= (moveProgress / 0.30);
      }

      if (progress > 0.68) {
        final double fadeOut = ((progress - 0.68) / 0.28).clamp(0.0, 1.0);
        alpha *= (1.0 - fadeOut * 0.55);
      }

      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicParticleCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom Painter for Radiant Diamond Star Sparkle
class _StarGlintPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color glowColor;

  _StarGlintPainter({
    required this.progress,
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001 || progress >= 0.999) return;

    final double intensity = math.sin(progress * math.pi);
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.5;

    final double rayLen = 13.0 * intensity;
    final double rayThick = 1.8 * intensity;

    // Warm radial glow behind sparkle
    final Paint glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.75 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx, cy), 6.0 * intensity, glowPaint);

    // Primary Horizontal & Vertical Diamond Rays
    final Paint rayPaint = Paint()
      ..color = color.withValues(alpha: intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = rayThick;

    canvas.drawLine(Offset(cx - rayLen, cy), Offset(cx + rayLen, cy), rayPaint);
    canvas.drawLine(Offset(cx, cy - rayLen), Offset(cx, cy + rayLen), rayPaint);

    // Secondary Diagonal Shimmer Rays
    final double diagLen = rayLen * 0.50;
    final Paint diagPaint = Paint()
      ..color = color.withValues(alpha: 0.65 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = rayThick * 0.65;

    canvas.drawLine(Offset(cx - diagLen, cy - diagLen), Offset(cx + diagLen, cy + diagLen), diagPaint);
    canvas.drawLine(Offset(cx - diagLen, cy + diagLen), Offset(cx + diagLen, cy - diagLen), diagPaint);

    // Intense White Center Point
    final Paint corePaint = Paint()..color = Colors.white.withValues(alpha: intensity);
    canvas.drawCircle(Offset(cx, cy), 2.2 * intensity, corePaint);
  }

  @override
  bool shouldRepaint(covariant _StarGlintPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
