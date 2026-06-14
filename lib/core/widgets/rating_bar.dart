import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_colors.dart';

class AppRatingBar extends StatelessWidget {
  final double rating;
  final double itemSize;
  final bool ignoreGestures;

  const AppRatingBar({
    super.key,
    required this.rating,
    this.itemSize = 16,
    this.ignoreGestures = true,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemSize: itemSize,
      unratedColor: AppColors.textMuted.withOpacity(0.3),
      itemBuilder: (_, __) => const Icon(
        Icons.star_rounded,
        color: AppColors.accent,
      ),
    );
  }
}

class AppInteractiveRatingBar extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double> onRatingUpdate;
  final double itemSize;

  const AppInteractiveRatingBar({
    super.key,
    required this.initialRating,
    required this.onRatingUpdate,
    this.itemSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      unratedColor: AppColors.textMuted.withOpacity(0.3),
      itemBuilder: (_, __) => const Icon(
        Icons.star_rounded,
        color: AppColors.accent,
      ),
      onRatingUpdate: onRatingUpdate,
    );
  }
}
