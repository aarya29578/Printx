import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavTab(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Categories'),
    _NavTab(icon: Icons.palette_outlined, activeIcon: Icons.palette_rounded, label: 'Designs', isCenter: true),
    _NavTab(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavTab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppSpacing.bottomNavShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == widget.currentIndex;

              if (tab.isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTabSelected(i);
                    },
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: AppSpacing.primaryShadow,
                        ),
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTabSelected(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          width: isActive ? 48 : 0,
                          height: isActive ? 32 : 0,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: isActive
                              ? Icon(
                                  tab.activeIcon,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                        ),
                        if (!isActive) ...[
                          Icon(
                            tab.icon,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: AppTextStyles.caption.copyWith(
                            color:
                                isActive ? AppColors.primary : AppColors.textMuted,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}
