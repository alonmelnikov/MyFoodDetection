import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../di/dependency_injection.dart';
import 'foodies_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start initialization immediately after first frame renders
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();
    const minDisplayDuration = Duration(seconds: 3);

    try {
      // 1. Wait for initialization to complete first
      await DependencyInjection.initialize();

      // 2. Then start cache cleanup in background (non-blocking)
      _cleanupCacheInBackground();

      // 3. Calculate elapsed time and ensure minimum 3 seconds display
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = minDisplayDuration - elapsed;

      if (remainingTime.compareTo(Duration.zero) > 0) {
        await Future.delayed(remainingTime);
      }

      // 4. Navigate to main screen after initialization is done and 3 seconds passed
      if (mounted) {
        Get.offAll(() => FoodiesScreen());
      }
    } catch (e) {
      // Still wait for minimum 3 seconds even if there's an error
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = minDisplayDuration - elapsed;

      if (remainingTime.compareTo(Duration.zero) > 0) {
        await Future.delayed(remainingTime);
      }

      if (mounted) {
        Get.offAll(() => FoodiesScreen());
      }
    }
  }

  void _cleanupCacheInBackground() {
    final historyStorageService = DependencyInjection.historyStorageService;
    if (historyStorageService == null) {
      return;
    }

    // Run cleanup in background without blocking:
    // - remove legacy disk cache files from previous versions
    historyStorageService.cleanupLegacyApiCacheFiles().catchError((error) {
      // Silently handle cleanup errors
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use hardcoded colors to avoid theme initialization delay
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon or logo
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            // App name
            const Text(
              'Food Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
