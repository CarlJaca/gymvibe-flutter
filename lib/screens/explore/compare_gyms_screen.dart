import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../models/gym_model.dart';

class CompareGymsScreen extends StatelessWidget {
  final List<GymModel> gyms;

  const CompareGymsScreen({super.key, required this.gyms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Gyms',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Gym Headers ──────────────────────────────────────────
          _buildGymHeaders(),
          const Divider(color: AppColors.border, height: 1),

          // ── Comparison Table ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildComparisonRow(
                    'Membership',
                    Icons.payments_rounded,
                    gyms.map((g) => _PriceCell(g.monthlyPrice)).toList(),
                  ),
                  _buildComparisonRow(
                    'Rating',
                    Icons.star_rounded,
                    gyms.map((g) => _RatingCell(g.rating, g.reviewCount)).toList(),
                  ),
                  _buildComparisonRow(
                    'Distance',
                    Icons.location_on_rounded,
                    gyms.map((g) => _DistanceCell('${g.distanceKm.toStringAsFixed(1)} km')).toList(),
                  ),
                  _buildComparisonRow(
                    'Status',
                    Icons.access_time_rounded,
                    gyms.map((g) => _StatusCell(g.isOpen)).toList(),
                  ),
                  _buildComparisonRow(
                    'Hours',
                    Icons.schedule_rounded,
                    gyms.map((g) => _TextCell(g.hours.isNotEmpty ? g.hours : 'N/A')).toList(),
                  ),
                  _buildComparisonRow(
                    'Facilities',
                    Icons.fitness_center_rounded,
                    gyms.map((g) => _ListCell(g.facilities)).toList(),
                  ),
                  _buildComparisonRow(
                    'Programs',
                    Icons.category_rounded,
                    gyms.map((g) => _ListCell(g.categories)).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Choose the gym that fits your goals!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gym Header Columns ──────────────────────────────────────────────────
  Widget _buildGymHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 78),
          ...gyms.map((gym) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: gym.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: gym.imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.surface,
                                child: const Icon(Icons.fitness_center_rounded,
                                    color: AppColors.textMuted, size: 18),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.surface,
                                child: const Icon(Icons.fitness_center_rounded,
                                    color: AppColors.textMuted, size: 18),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: AppColors.surface,
                              child: const Icon(Icons.fitness_center_rounded,
                                  color: AppColors.textMuted, size: 18),
                            ),
                    ),
                    const SizedBox(height: 4),
                    // Fixed-height name container so all columns align equally
                    SizedBox(
                      height: 30,
                      child: Text(
                        gym.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Generic Comparison Row ──────────────────────────────────────────────
  Widget _buildComparisonRow(String label, IconData icon, List<Widget> cells) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label column — narrower
            Container(
              width: 78,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Data columns
            ...cells.map((cell) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    child: cell,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cell Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Price cell — center-aligned
class _PriceCell extends StatelessWidget {
  final String price;
  const _PriceCell(this.price);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        price.isNotEmpty ? price : 'N/A',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Rating cell — center-aligned
class _RatingCell extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _RatingCell(this.rating, this.reviewCount);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            '($reviewCount)',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Distance cell — center-aligned
class _DistanceCell extends StatelessWidget {
  final String text;
  const _DistanceCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Text cell — center-aligned
class _TextCell extends StatelessWidget {
  final String text;
  const _TextCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Status cell — center-aligned
class _StatusCell extends StatelessWidget {
  final bool isOpen;
  const _StatusCell(this.isOpen);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            color: isOpen ? AppColors.primary : Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// List cell — center-aligned with tappable '+more'
class _ListCell extends StatelessWidget {
  final List<String> items;
  const _ListCell(this.items);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('N/A',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      );
    }

    final shown = items.take(3).toList();
    final remaining = items.length - 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...shown.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                item,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
        if (remaining > 0)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  title: const Text(
                    'All Items',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              '+$remaining more',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
