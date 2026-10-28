import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class RatingProgressBar extends StatelessWidget {
  final String label;
  final double rating;

  const RatingProgressBar({
    super.key,
    required this.label,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    // rating is out of 5.0
    final fraction = rating / 5.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppColors.surfaceElevated,
                color: const Color(0xFFFFD700), // Yellow gold matching Figma
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
