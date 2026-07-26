import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, outline }

enum AppButtonSize { small, medium, large, fullWidth }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool disabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget? child;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.disabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.child,
  });

  const AppButton.small({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.disabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.child,
  }) : size = AppButtonSize.small;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.disabled && !widget.isLoading) {
      setState(() => _pressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    if (!widget.disabled && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
      case AppButtonSize.fullWidth:
        return 52;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
      case AppButtonSize.fullWidth:
        return 15;
    }
  }

  double get _horizontalPadding {
    switch (widget.size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
      case AppButtonSize.fullWidth:
        return 24;
    }
  }

  bool get _isFullWidth => widget.size == AppButtonSize.fullWidth;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.disabled && !widget.isLoading;
    final opacity = widget.disabled ? 0.5 : 1.0;

    Widget buttonContent = Row(
      mainAxisSize:
          _isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.variant == AppButtonVariant.primary ||
                      widget.variant == AppButtonVariant.danger
                  ? Colors.white
                  : AppColors.primary,
            ),
          )
        else ...[
          if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, size: _fontSize + 4),
            const SizedBox(width: 8),
          ],
          if (widget.child != null)
            widget.child!
          else
            Text(
              widget.label,
              style: AppTextStyles.button.copyWith(
                fontSize: _fontSize,
                color: _textColor,
              ),
            ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.trailingIcon, size: _fontSize + 4),
          ],
        ],
      ],
    );

    Widget buttonContainer = AnimatedScale(
      scale: _pressed && isEnabled ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Container(
            height: _height,
            width: _isFullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            decoration: _decoration,
            child: buttonContent,
          ),
        ),
      ),
    );

    return buttonContainer;
  }

  Color get _textColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
        return Colors.white;
      case AppButtonVariant.ghost:
        return AppColors.primary;
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.outline:
        return AppColors.primary;
    }
  }

  BoxDecoration get _decoration {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: AppSpacing.primaryShadow,
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          gradient: AppColors.gradientSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        );
      case AppButtonVariant.danger:
        return BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
    }
  }
}
