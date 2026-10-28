import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/gym_model.dart';
import '../providers/gym_provider.dart';
import '../providers/location_provider.dart';
import '../core/constants/app_constants.dart';
import 'star_rating.dart';

class ExploreGymTile extends StatelessWidget {
  final GymModel gym;
  final VoidCallback? onTap;

  const ExploreGymTile({super.key, required this.gym, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: gym.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.textSecondary, size: 24),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.textSecondary, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StarRating(
                    rating: gym.rating,
                    size: 13,
                    reviewCount: gym.reviewCount,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Consumer<LocationProvider>(
                        builder: (context, locProv, _) {
                          final dynamicDist = locProv.calculateDistance(gym.latitude, gym.longitude);
                          return Text(
                            dynamicDist != null ? '${dynamicDist.toStringAsFixed(1)} km' : '${gym.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Favorite ─────────────────────────────────────────────────
            Consumer<GymProvider>(
              builder: (_, provider, __) {
                final isFav = provider.isFavorite(gym.id);
                return GestureDetector(
                  onTap: () => provider.toggleFavorite(gym.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.heart : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
