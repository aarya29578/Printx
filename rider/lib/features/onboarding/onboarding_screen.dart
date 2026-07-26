import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../services/storage_service.dart';

class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      title: 'Get Delivery Assignments',
      subtitle:
          'Admin assigns orders to you instantly. Accept and start earning right away.',
      icon: Icons.assignment_rounded,
      color: Color(0xFF4F46E5),
    ),
    _OnboardPage(
      title: 'Pick Up & Deliver',
      subtitle:
          'Pick up printed products from vendors and deliver them to customers doorstep.',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF10B981),
    ),
    _OnboardPage(
      title: 'Real-Time Tracking',
      subtitle:
          'Customers and admin track your delivery in real-time. Keep everyone updated.',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFF06B6D4),
    ),
    _OnboardPage(
      title: 'Earn Every Delivery',
      subtitle:
          'Track your daily earnings, completed deliveries, and performance all in one place.',
      icon: Icons.currency_rupee_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _done();
    }
  }

  Future<void> _done() async {
    await StorageService.setOnboardingDone();
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _done,
                child: const Text('Skip',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(p.icon, size: 56, color: p.color),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FadeInUp(
                          child: Text(
                            p.title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            p.subtitle,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl,
                    count: _pages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: _page == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _next,
                    suffixIcon: _page < _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
