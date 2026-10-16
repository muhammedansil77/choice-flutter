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

/// Cinematic Splash Screen for CHOICE ELECTRICALS & PLUMBING
/// Recreated to meet high-end brand commercial animation specifications:
/// - Phase 1: Pure deep black introduction (#050505)
/// - Phase 2: Golden particles stream in from left & right
/// - Phase 3: Dense horizontal particle band forms across the center
/// - Phase 4: Cinematic horizontal light streak with bloom and anamorphic flare
/// - Phase 5: Choice Electricals logo & subtitle revealed with subtle golden aura
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<_CinematicParticle> _particles;

  // Staggered Animations for Logo & Typography
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _subtitleFade;

  bool _isImagesPrecached = false;

  // Brand Color Palette
  static const Color bgBlack = Color(0xFF050505);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color brightGold = Color(0xFFFFD76A);
  static const Color darkGold = Color(0xFF8C6A15);
  static const Color softWhite = Color(0xFFEAEAEA);

  @override
  void initState() {
    super.initState();

    // Dark luxury status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bgBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 4.0-second unified cinematic timeline
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3900),
    );

    // Phase 5: Logo reveal animations (Starts as light streak passes center)
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.58, 0.78, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.68, 0.86, curve: Curves.easeOut),
    );

    // Pre-generate deterministic particles once (no GC/rebuild overhead)
    _particles = _generateParticles(140);

    _animController.forward();
    _initializeAndNavigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImagesPrecached) {
      _isImagesPrecached = true;
      precacheImage(const AssetImage('assets/images/logo_emblem.png'), context);
      precacheImage(const AssetImage('assets/images/logo.png'), context);
    }
  }

  /// Generate 140 layered, multi-sized circular particles with controlled golden tones
  List<_CinematicParticle> _generateParticles(int count) {
    final rand = math.Random(1987); // Deterministic seed for identical cinematic choreography
    final List<_CinematicParticle> list = [];

    const goldPalette = [
      primaryGold,
      brightGold,
      darkGold,
      Color(0xFFE8D382), // Champagne
      Color(0xFFB89738), // Metallic antique gold
      softWhite,         // Small touch of soft white (~8%)
      Color(0xFF2A2314), // Charcoal bronze
    ];

    for (int i = 0; i < count; i++) {
      // Balance entry: 50% left, 50% right
      final bool enterFromLeft = i % 2 == 0;
      final double startX = enterFromLeft
          ? -0.15 - rand.nextDouble() * 0.20
          : 1.15 + rand.nextDouble() * 0.20;

      // Target X rests across the horizontal center band (dense concentration between 0.25 and 0.75)
      final double targetX = 0.18 + (rand.nextDouble() * 0.64) + (rand.nextDouble() - 0.5) * 0.12;

      // Vertical offset: 20-30% screen height band centered vertically (-0.12 to +0.12)
      // with occasional outer floating particles up to -0.17 to +0.17
      final double yRatio = ((rand.nextDouble() - 0.5) * 0.24) * (rand.nextDouble() > 0.85 ? 1.4 : 1.0);

      // Particle Size Distribution:
      // - Tiny (1-2px): ~45%
      // - Small (2-4px): ~35%
      // - Medium (4-7px): ~15%
      // - Occasional large bubbles (8-11px): ~5%
      final double roll = rand.nextDouble();
      final double radius;
      final int layer;
      if (roll < 0.45) {
        radius = 1.0 + rand.nextDouble() * 1.5;
        layer = 0; // background
      } else if (roll < 0.80) {
        radius = 2.5 + rand.nextDouble() * 2.0;
        layer = 1; // midground
      } else if (roll < 0.95) {
        radius = 4.5 + rand.nextDouble() * 2.5;
        layer = 2; // foreground
      } else {
        radius = 7.5 + rand.nextDouble() * 3.5;
        layer = 2; // prominent foreground bubble
      }

      // Colors: predominantly gold, occasional soft white
      final Color color = (layer == 2 && rand.nextDouble() < 0.15)
          ? softWhite
          : goldPalette[rand.nextInt(goldPalette.length)];

      final double baseOpacity = layer == 0
          ? 0.30 + rand.nextDouble() * 0.25
          : layer == 1
              ? 0.55 + rand.nextDouble() * 0.25
              : 0.80 + rand.nextDouble() * 0.20;

      list.add(
        _CinematicParticle(
          startX: startX,
          targetX: targetX.clamp(0.08, 0.92),
          yRatio: yRatio,
          radius: radius,
          layer: layer,
          color: color,
          baseOpacity: baseOpacity,
          speed: 0.85 + rand.nextDouble() * 0.45,
          entryDelay: 0.08 + rand.nextDouble() * 0.18,
          driftFreq: 1.5 + rand.nextDouble() * 2.5,
          driftAmp: 2.5 + rand.nextDouble() * 4.5,
          phase: rand.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Sort by layer so background renders first, foreground on top
    list.sort((a, b) => a.layer.compareTo(b.layer));
    return list;
  }

  /// Coordinate background authentication & data load with cinematic animation
  Future<void> _initializeAndNavigate() async {
    final apiService = context.read<ApiService>();

    try {
      // Concurrently initialize auth and ensure exact 3.95s cinematic experience
      final results = await Future.wait([
        apiService.loadPersistedToken(),
        SharedPreferences.getInstance(),
        Future.delayed(const Duration(milliseconds: 3950)),
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
      backgroundColor: bgBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cinematic Particle & Light Streak Custom Painter
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CinematicCanvasPainter(
                    progress: _animController.value,
                    particles: _particles,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 2. Choice Electricals Brand Logo Reveal (Phase 5)
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

                      // Responsive dimensions preserving perfect proportions
                      final double emblemSize = (screenW * 0.24).clamp(72.0, 92.0);
                      final double titleSize = (screenW * 0.088).clamp(28.0, 38.0);
                      final double titleSpacing = (screenW * 0.020).clamp(5.5, 8.5);
                      final double subSize = (screenW * 0.028).clamp(10.0, 12.5);
                      final double subSpacing = (screenW * 0.010).clamp(3.0, 4.2);

                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Choice Golden Emblem with subtle ambient glow aura
                              Container(
                                width: emblemSize,
                                height: emblemSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGold.withValues(alpha: 0.28 * _logoFade.value),
                                      blurRadius: 36,
                                      spreadRadius: 6,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.70),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo_emblem.png',
                                  width: emblemSize,
                                  height: emblemSize,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // CHOICE Brand Title in Bold Metallic Gold
                              Text(
                                'CHOICE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: titleSpacing,
                                  color: primaryGold,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: brightGold.withValues(alpha: 0.45 * _logoFade.value),
                                      blurRadius: 22,
                                    ),
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.85),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ELECTRICALS & PLUMBING Subtitle in Elegant Crisp White
                              FadeTransition(
                                opacity: _subtitleFade,
                                child: Text(
                                  'ELECTRICALS & PLUMBING',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subSize,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: subSpacing,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.90),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
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

/// Particle model with precalculated properties
class _CinematicParticle {
  final double startX;
  final double targetX;
  final double yRatio;
  final double radius;
  final int layer;
  final Color color;
  final double baseOpacity;
  final double speed;
  final double entryDelay;
  final double driftFreq;
  final double driftAmp;
  final double phase;

  const _CinematicParticle({
    required this.startX,
    required this.targetX,
    required this.yRatio,
    required this.radius,
    required this.layer,
    required this.color,
    required this.baseOpacity,
    required this.speed,
    required this.entryDelay,
    required this.driftFreq,
    required this.driftAmp,
    required this.phase,
  });
}

/// High-performance Canvas Painter implementing:
/// - Phase 1: Pure deep black
/// - Phase 2 & 3: Flowing particles forming a dense horizontal band
/// - Phase 4: Cinematic horizontal light streak with bloom, flare & tail
/// - Phase 5: Central ambient golden aura
class _CinematicCanvasPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final List<_CinematicParticle> particles;

  _CinematicCanvasPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width * 0.50;
    final double centerY = size.height * 0.50;

    // 0. Base deep black background
    canvas.drawColor(const Color(0xFF050505), BlendMode.src);

    // Phase 1 (0.0 to 0.08): Pure darkness
    if (progress < 0.02) return;

    // =========================================================================
    // PHASE 4 & 5: CENTRAL GOLDEN AMBIENT AURA BEHIND LOGO
    // =========================================================================
    if (progress >= 0.48) {
      final double auraT = ((progress - 0.48) / 0.35).clamp(0.0, 1.0);
      final double curvedAura = Curves.easeOutCubic.transform(auraT);
      final double auraRadius = size.width * 0.45;

      final Rect auraRect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: auraRadius,
      );

      final Paint auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.16 * curvedAura),
            const Color(0xFF8C6A15).withValues(alpha: 0.06 * curvedAura),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(auraRect);

      canvas.drawCircle(Offset(centerX, centerY), auraRadius, auraPaint);
    }

    // Streak head position calculation (needed for particle brightness boost)
    double? streakX;
    double streakIntensity = 0.0;
    const double streakStart = 0.44;
    const double streakEnd = 0.70;

    if (progress >= streakStart && progress <= streakEnd) {
      final double localStreak = (progress - streakStart) / (streakEnd - streakStart);
      final double curvedStreak = Curves.easeInOutCubic.transform(localStreak);
      streakX = -size.width * 0.25 + curvedStreak * (size.width * 1.50);

      if (localStreak < 0.20) {
        streakIntensity = localStreak / 0.20;
      } else if (localStreak > 0.75) {
        streakIntensity = (1.0 - localStreak) / 0.25;
      } else {
        streakIntensity = 1.0;
      }
    }

    // =========================================================================
    // PHASES 2, 3, 5: DRAW PARTICLES
    // =========================================================================
    final Paint particlePaint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      // Staggered entry progress
      if (progress < p.entryDelay) continue;

      // Particle entry motion (0.0 to 1.0)
      final double moveDuration = 0.38 / p.speed;
      final double moveProgress = ((progress - p.entryDelay) / moveDuration).clamp(0.0, 1.0);
      final double moveEase = Curves.easeOutCubic.transform(moveProgress);

      // Current X position
      final double currentNormX = p.startX + (p.targetX - p.startX) * moveEase;
      final double baseX = currentNormX * size.width;

      // Subtle organic horizontal and vertical drift
      final double timeOffset = progress * 6.28 * p.driftFreq + p.phase;
      final double driftX = math.sin(timeOffset) * p.driftAmp;
      final double driftY = math.cos(timeOffset * 0.8) * (p.driftAmp * 0.8);

      final double px = baseX + driftX;
      final double py = centerY + (p.yRatio * size.height) + driftY;

      // Calculate particle opacity
      double alpha = p.baseOpacity;

      // Fade in smoothly at entry
      if (moveProgress < 0.30) {
        alpha *= (moveProgress / 0.30);
      }

      // Nearby particles brighten as the light streak sweeps past
      if (streakX != null && streakIntensity > 0.0) {
        final double distX = (px - streakX).abs();
        if (distX < 65.0) {
          final double proximityBoost = (1.0 - (distX / 65.0)) * 0.40 * streakIntensity;
          alpha = (alpha + proximityBoost).clamp(0.0, 1.0);
        }
      }

      // Phase 5: Soften particles near the center to keep logo text ultra-clean
      if (progress > 0.60) {
        final double distCenter = (px - centerX).abs();
        final double distY = (py - centerY).abs();
        if (distCenter < size.width * 0.32 && distY < 85.0) {
          final double fadeRatio = ((progress - 0.60) / 0.25).clamp(0.0, 1.0);
          alpha *= (1.0 - fadeRatio * 0.80);
        }
      }

      if (alpha <= 0.01) continue;

      particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius, particlePaint);
    }

    // =========================================================================
    // PHASE 4: CINEMATIC HORIZONTAL LIGHT STREAK WITH BLOOM & FLARE
    // =========================================================================
    if (streakX != null && streakIntensity > 0.0) {
      final double sX = streakX;
      final double sY = centerY;

      // 1. Soft Warm Horizontal Bloom along the center band
      final Rect bloomRect = Rect.fromCenter(
        center: Offset(sX - size.width * 0.12, sY),
        width: size.width * 0.75,
        height: 32.0,
      );
      final Paint bloomPaint = Paint()
        ..shader = RadialGradient(
          radius: 0.5,
          colors: [
            const Color(0xFFFFD76A).withValues(alpha: 0.36 * streakIntensity),
            const Color(0xFFD4AF37).withValues(alpha: 0.15 * streakIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(bloomRect);
      canvas.drawRect(bloomRect, bloomPaint);

      // 2. Trailing Light Core Line
      final Rect lineRect = Rect.fromCenter(
        center: Offset(sX - (size.width * 0.16), sY),
        width: size.width * 0.65,
        height: 2.8,
      );
      final Paint linePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFF8C6A15).withValues(alpha: 0.25 * streakIntensity),
            const Color(0xFFD4AF37).withValues(alpha: 0.75 * streakIntensity),
            const Color(0xFFFFD76A).withValues(alpha: 0.95 * streakIntensity),
            Colors.white.withValues(alpha: 1.0 * streakIntensity),
          ],
          stops: const [0.0, 0.28, 0.65, 0.85, 1.0],
        ).createShader(lineRect);
      canvas.drawRRect(RRect.fromRectAndRadius(lineRect, const Radius.circular(2)), linePaint);

      // 3. Anamorphic Lens Flare Beam at Streak Head
      final Rect flareBeamRect = Rect.fromCenter(
        center: Offset(sX, sY),
        width: (size.width * 0.40).clamp(140.0, 240.0),
        height: 3.5,
      );
      final Paint flareBeamPaint = Paint()
        ..shader = RadialGradient(
          radius: 0.5,
          colors: [
            Colors.white.withValues(alpha: 0.95 * streakIntensity),
            const Color(0xFFFFD76A).withValues(alpha: 0.70 * streakIntensity),
            const Color(0xFFD4AF37).withValues(alpha: 0.30 * streakIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.60, 1.0],
        ).createShader(flareBeamRect);
      canvas.drawRect(flareBeamRect, flareBeamPaint);

      // 4. Intense Central Highlight Core (Small glowing flare head)
      final Paint coreGlow = Paint()
        ..color = const Color(0xFFFFD76A).withValues(alpha: 0.80 * streakIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(Offset(sX, sY), 6.5, coreGlow);

      final Paint coreWhite = Paint()
        ..color = Colors.white.withValues(alpha: 0.98 * streakIntensity);
      canvas.drawCircle(Offset(sX, sY), 3.2, coreWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
