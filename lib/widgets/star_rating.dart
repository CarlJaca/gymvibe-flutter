import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;
  final int? reviewCount;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 14,
    this.showNumber = true,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.star, size: size),
        const SizedBox(width: 3),
        if (showNumber) ...[
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: size - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 3),
            Text(
              '($reviewCount)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: size - 2,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class StarRatingRow extends StatelessWidget {
  final double rating;
  final double starSize;

  const StarRatingRow({super.key, required this.rating, this.starSize = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, color: AppColors.star, size: starSize);
        } else if (i < rating && rating - i >= 0.5) {
          return Icon(Icons.star_half_rounded, color: AppColors.star, size: starSize);
        } else {
          return Icon(Icons.star_outline_rounded,
              color: AppColors.textMuted, size: starSize);
        }
      }),
    );
  }
}
