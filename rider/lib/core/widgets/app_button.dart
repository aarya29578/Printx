import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, outline }
enum AppButtonSize { small, medium, large, fullWidth }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.fullWidth,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  double get _height => switch (widget.size) {
        AppButtonSize.small => 36,
        AppButtonSize.medium => 44,
        AppButtonSize.large || AppButtonSize.fullWidth => 52,
      };

  double get _fontSize => switch (widget.size) {
        AppButtonSize.small => 12,
        AppButtonSize.medium => 14,
        AppButtonSize.large || AppButtonSize.fullWidth => 15,
      };

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!isDisabled) {
          HapticFeedback.lightImpact();
          widget.onPressed?.call();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: _buildButton(isDisabled),
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.size == AppButtonSize.fullWidth
          ? MainAxisSize.max
          : MainAxisSize.min,
      children: [
        if (widget.isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        else ...[
          if (widget.prefixIcon != null) ...[
            Icon(widget.prefixIcon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            widget.label,
            style: TextStyle(
                fontSize: _fontSize, fontWeight: FontWeight.w600),
          ),
          if (widget.suffixIcon != null) ...[
            const SizedBox(width: 6),
            Icon(widget.suffixIcon, size: 16),
          ],
        ],
      ],
    );

    if (widget.variant == AppButtonVariant.primary) {
      return Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          width: widget.size == AppButtonSize.fullWidth
              ? double.infinity
              : widget.width,
          height: _height,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: isDisabled ? [] : AppSpacing.primaryShadow,
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.variant == AppButtonVariant.outline) {
      return Container(
        width: widget.size == AppButtonSize.fullWidth
            ? double.infinity
            : widget.width,
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600),
            child: IconTheme(
              data: const IconThemeData(color: AppColors.primary),
              child: content,
            ),
          ),
        ),
      );
    }

    if (widget.variant == AppButtonVariant.danger) {
      return Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          width: widget.size == AppButtonSize.fullWidth
              ? double.infinity
              : widget.width,
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    // Ghost
    return Container(
      width: widget.size == AppButtonSize.fullWidth
          ? double.infinity
          : widget.width,
      height: _height,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(
        child: DefaultTextStyle(
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.primary),
            child: content,
          ),
        ),
      ),
    );
  }
}
