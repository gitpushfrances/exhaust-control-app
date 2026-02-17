import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();

    // Check permissions and navigate
    _initializeApp();
  }

  /// Initialize app with permission checks
  Future<void> _initializeApp() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    print('>>> Splash: mounted = $mounted');
    if (!mounted) return;

    print('>>> Splash: requesting permissions now');
    final permissionsGranted = await AppPermissionHandler.requestAllPermissions(
      context,
    );
    print('>>> Splash: permissions result = $permissionsGranted');

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Navigate regardless - app handles limited functionality without permissions
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ReWatch Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo not found
                          return const Icon(
                            Icons.directions_car,
                            size: 60,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Name
                  Text(
                    'Exhaust Controller',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Smart Noise Management',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading Indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
