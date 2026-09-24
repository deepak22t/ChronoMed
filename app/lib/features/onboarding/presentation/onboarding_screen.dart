import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/navigation/app_shell.dart';

/// Premium Onboarding Screen matching the exact design specification
///
/// Features:
/// - Top "Skip" button in SafeArea
/// - Background photography [assets/images/onboarding_bg.png] perfectly framed
///   to show the water glass on the left, pill organizer, and notebook.
/// - Organic asymmetrical curved bottom container
/// - Exact ChronoMed botanical twin-leaf logo from reference
/// - High-contrast editorial typography
/// - 4-dot pagination indicator with generous spacing
/// - Softened medical teal pill "Get Started  →" button
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _navigateToMain(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F8),
        body: Stack(
          children: [
            // 1. Background Image (Framed to show glass of water on left and pillbox)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.62,
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                // Alignment shifted left so the full water glass is completely visible
                alignment: const Alignment(-0.62, -0.15),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE2EBE9),
                    child: const Center(
                      child: Icon(Icons.medication_rounded, size: 64, color: Color(0xFF196971)),
                    ),
                  );
                },
              ),
            ),

            // 2. Top-Right "Skip" Button (in SafeArea)
            Positioned(
              top: mediaQuery.padding.top + 8,
              right: 20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _navigateToMain(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF196971),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Organic Curved Bottom Card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: _OnboardingWaveShadowPainter(),
                child: ClipPath(
                  clipper: _OnboardingWaveClipper(),
                  child: Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.22, 1.0],
                        colors: [
                          Color(0xFFE8F4F1), // Very soft subtle mint tint at curved top
                          Color(0xFFF7FAF9),
                          Color(0xFFFFFFFF), // Pure clean white bottom
                        ],
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      28,
                      65, // top padding inside the organic wave crest
                      28,
                      mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom + 16 : 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. Brand Header (Exact Leaf Logo + ChronoMed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/chrono_leaf.png',
                              height: 17,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF196971),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ChronoMed',
                              style: TextStyle(
                                color: Color(0xFF0F323D),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // B. Headline: "Never miss the right medicine"
                        const Text(
                          'Never miss the\nright medicine',
                          style: TextStyle(
                            color: Color(0xFF082733),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // C. Subtitle / Description (Duller, refined weight)
                        const Text(
                          'ChronoMed intelligently organizes your medication timing, so you can stay on track, every day.',
                          style: TextStyle(
                            color: Color(0xFF6B8791), // Soft dull slate-teal
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            letterSpacing: -0.1,
                          ),
                        ),

                        const SizedBox(height: 26),

                        // D. Pagination Dots (Dot 2 Active with wider gap)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(isActive: false),
                            const SizedBox(width: 12), // Wider spacing as in reference
                            _buildDot(isActive: true),
                            const SizedBox(width: 12),
                            _buildDot(isActive: false),
                            const SizedBox(width: 12),
                            _buildDot(isActive: false),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // E. Softer Medical Teal "Get Started  →" Pill Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _navigateToMain(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF196971), // Softer, calmer teal
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 19),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDot({required bool isActive}) {
    return Container(
      width: isActive ? 7.5 : 6,
      height: isActive ? 7.5 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF196971) : const Color(0xFFC7DDD9),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Asymmetrical organic wave top clipper matching reference layout
class _OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Starts at left at y = 28
    path.moveTo(0, 28);
    // Smooth asymmetrical cubic bezier curve:
    // Crest on the left, soft downward swoop to the right edge at y = 68
    path.cubicTo(
      size.width * 0.30, 8,   // left crest
      size.width * 0.70, 76,  // right descent
      size.width, 66,         // right edge
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Soft ambient drop shadow along the organic wave top
class _OnboardingWaveShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 28);
    path.cubicTo(
      size.width * 0.30, 8,
      size.width * 0.70, 76,
      size.width, 66,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final shadowPaint = Paint()
      ..color = const Color(0xFF0E2E3B).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path.shift(const Offset(0, -5)), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
