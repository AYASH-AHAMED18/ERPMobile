import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_started) return;
    _started = true;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const BrandLogo(size: 70),
              ),
            ),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: _fade,
              child: Text(
                'Staff Enterprise Resource Planning',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Spacer(flex: 4),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Securing your workspace...',
              style: TextStyle(fontSize: 11.5, color: context.textSecondary),
            ),
            const SizedBox(height: 30),
            Text(
              'v${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
