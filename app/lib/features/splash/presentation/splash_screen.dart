import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

/// Full-screen Splash Video Screen for ChronoMed
///
/// Automatically plays [assets/videos/splash.mp4] with audio on startup in true
/// edge-to-edge immersive full-screen mode (no margins, no letterboxing),
/// then smoothly transitions to the Onboarding Screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Hide system bars completely for 100% edge-to-edge full-screen video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Safety fallback timer: navigate if video fails to complete within 10 seconds
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (!_hasNavigated) {
        _navigateToOnboarding();
      }
    });

    try {
      _controller = VideoPlayerController.asset('assets/videos/splash.mp4');
      await _controller.initialize();
      await _controller.setVolume(1.0);
      await _controller.setLooping(false);

      _controller.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await _controller.play();
      }
    } catch (e) {
      debugPrint('SplashScreen: Error initializing splash video: $e');
      // If video asset fails to load, navigate after 1.5 seconds
      Timer(const Duration(milliseconds: 1500), _navigateToOnboarding);
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _hasNavigated) return;

    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    // Check if video reached its end (within 150ms of duration or position >= duration)
    if (dur > Duration.zero && (pos >= dur || dur - pos < const Duration(milliseconds: 150))) {
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    try {
      _controller.removeListener(_onVideoUpdate);
      _controller.pause();
    } catch (_) {}

    // Restore standard edge-to-edge system UI for normal app usage
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Smooth fade transition to the Onboarding screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
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
  void dispose() {
    _fallbackTimer?.cancel();
    try {
      _controller.removeListener(_onVideoUpdate);
      _controller.dispose();
    } catch (_) {}
    // Ensure system UI is restored on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14), // Midnight slate
      body: SizedBox.expand(
        child: _isInitialized && _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D9488).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xFF2DD4BF),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ChronoMed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
