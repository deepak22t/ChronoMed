import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/navigation/app_shell.dart';

/// Premium Onboarding Screen matching the exact design specification
///
/// Features:
/// - Top "Skip" button in SafeArea
/// - Background photography [assets/images/onboarding_bg.png]
/// - Organic asymmetrical curved bottom container
/// - Vector ChronoMed botanical twin-leaf logo
/// - High-contrast editorial typography
/// - 4-dot pagination indicator
/// - Deep medical teal pill "Continue  →" button
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
            // 1. Background Image (Top 65% of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.65,
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE2EBE9),
                    child: const Center(
                      child: Icon(Icons.medication_rounded, size: 64, color: Color(0xFF0E6266)),
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
                      color: Color(0xFF0E6266),
                      fontSize: 15,
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
                        stops: [0.0, 0.25, 1.0],
                        colors: [
                          Color(0xFFEAF5F2), // Very soft mint tint at curved top
                          Color(0xFFF7FAF9),
                          Color(0xFFFFFFFF), // Pure white bottom
                        ],
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      28,
                      70, // generous top padding inside the wave crest
                      28,
                      mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom + 16 : 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. Brand Header (Logo + ChronoMed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: const Size(22, 22),
                              painter: _ChronoMedLeafLogoPainter(
                                color: const Color(0xFF0E6266),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ChronoMed',
                              style: TextStyle(
                                color: Color(0xFF0E2E3B),
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
                            color: Color(0xFF0A222C),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // C. Subtitle / Description
                        const Text(
                          'ChronoMed intelligently organizes your medication timing, so you can stay on track, every day.',
                          style: TextStyle(
                            color: Color(0xFF5A7580),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            letterSpacing: -0.1,
                          ),
                        ),

                        const SizedBox(height: 26),

                        // D. Pagination Dots (Dot 2 Active)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(isActive: false),
                            const SizedBox(width: 7),
                            _buildDot(isActive: true),
                            const SizedBox(width: 7),
                            _buildDot(isActive: false),
                            const SizedBox(width: 7),
                            _buildDot(isActive: false),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // E. Deep Medical Teal "Continue  →" Pill Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _navigateToMain(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E6266),
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
                                  'Continue',
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
        color: isActive ? const Color(0xFF0E6266) : const Color(0xFFBED5D1),
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
    // Starts at left at y = 30
    path.moveTo(0, 30);
    // Smooth asymmetrical cubic bezier curve:
    // Crest on the left, soft downward swoop to the right edge at y = 72
    path.cubicTo(
      size.width * 0.30, 8,   // left crest
      size.width * 0.70, 78,  // right descent
      size.width, 68,         // right edge
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
    path.moveTo(0, 30);
    path.cubicTo(
      size.width * 0.30, 8,
      size.width * 0.70, 78,
      size.width, 68,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final shadowPaint = Paint()
      ..color = const Color(0xFF0E2E3B).withOpacity(0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path.shift(const Offset(0, -5)), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Precision Vector ChronoMed Botanical Twin-Leaf Logo
class _ChronoMedLeafLogoPainter extends CustomPainter {
  final Color color;

  _ChronoMedLeafLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Scale to bounds
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    // Left Leaf (angled upper-left)
    final leftLeaf = Path();
    leftLeaf.moveTo(11, 19);
    leftLeaf.cubicTo(8, 17, 3, 13, 2, 7);
    leftLeaf.cubicTo(2, 5, 4, 3, 7, 3);
    leftLeaf.cubicTo(12, 3, 13, 11, 11, 19);
    leftLeaf.close();
    canvas.drawPath(leftLeaf, paint);

    // Right Leaf (angled upper-right)
    final rightLeaf = Path();
    rightLeaf.moveTo(13, 19);
    rightLeaf.cubicTo(16, 17, 21, 13, 22, 7);
    rightLeaf.cubicTo(22, 5, 20, 3, 17, 3);
    rightLeaf.cubicTo(12, 3, 11, 11, 13, 19);
    rightLeaf.close();
    canvas.drawPath(rightLeaf, paint);

    // Central Stem Base
    final stem = Path();
    stem.moveTo(10.5, 18);
    stem.lineTo(13.5, 18);
    stem.lineTo(12.5, 22);
    stem.lineTo(11.5, 22);
    stem.close();
    canvas.drawPath(stem, paint);
  }

  @override
  bool shouldRepaint(covariant _ChronoMedLeafLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
