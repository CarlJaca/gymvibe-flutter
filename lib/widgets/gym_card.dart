import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/gym_model.dart';
import '../providers/gym_provider.dart';
import '../providers/location_provider.dart';
import '../core/constants/app_constants.dart';
import 'star_rating.dart';

class GymCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback? onTap;

  const GymCard({super.key, required this.gym, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppPadding.md, vertical: AppPadding.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              // ── Gym Image ────────────────────────────────────────────────
              CachedNetworkImage(
                imageUrl: gym.imageUrl,
                height: AppSizes.gymCardHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: AppSizes.gymCardHeight,
                  color: AppColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: AppSizes.gymCardHeight,
                  color: AppColors.surface,
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.textSecondary, size: 40),
                ),
              ),

              // ── Gradient Overlay ─────────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Open Badge ───────────────────────────────────────────────
              if (gym.isOpen)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

              // ── Favorite Button ───────────────────────────────────────────
              Positioned(
                top: 8,
                right: 8,
                child: _FavoriteButton(gymId: gym.id),
              ),

              // ── Bottom Info ──────────────────────────────────────────────
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gym.hours,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StarRating(rating: gym.rating, size: 13),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white54, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gym.address,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
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
                                  fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final String gymId;

  const _FavoriteButton({required this.gymId});

  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (_, provider, __) {
        final isFav = provider.isFavorite(gymId);
        return GestureDetector(
          onTap: () => provider.toggleFavorite(gymId),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFav
                  ? AppColors.heart.withValues(alpha: 0.2)
                  : Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.heart : Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
