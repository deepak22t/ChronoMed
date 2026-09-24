import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/navigation/app_shell.dart';

/// Full-screen Splash Video Screen for ChronoMed
///
/// Automatically plays [assets/videos/splash.mp4] with audio on startup,
/// then smoothly transitions into the main app shell.
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
    // System UI immersive mode during splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Safety fallback timer: navigate if video fails to complete within 10 seconds
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (!_hasNavigated) {
        _navigateToHome();
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
      Timer(const Duration(milliseconds: 1500), _navigateToHome);
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _hasNavigated) return;

    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    // Check if video reached its end (within 150ms of duration or position >= duration)
    if (dur > Duration.zero && (pos >= dur || dur - pos < const Duration(milliseconds: 150))) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    try {
      _controller.removeListener(_onVideoUpdate);
      _controller.pause();
    } catch (_) {}

    // Smooth fade transition to the main app shell
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
  void dispose() {
    _fallbackTimer?.cancel();
    try {
      _controller.removeListener(_onVideoUpdate);
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14), // Midnight slate
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background and Video Layer
          if (_isInitialized && _controller.value.isInitialized)
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            // Elegant loading placeholder with ChronoMed branding
            Center(
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

          // 2. Subtle top bar with "Skip" button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton.icon(
                  onPressed: _navigateToHome,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white70),
                  label: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
