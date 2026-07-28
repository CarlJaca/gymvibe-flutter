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
                    gyms.map((g) => _TextCell('${g.distanceKm.toStringAsFixed(1)} km')).toList(),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Choose the gym that fits your goals!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: gyms.map((gym) {
          return Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: gym.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: gym.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.surface,
                            child: const Icon(Icons.fitness_center_rounded,
                                color: AppColors.textMuted),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.surface,
                            child: const Icon(Icons.fitness_center_rounded,
                                color: AppColors.textMuted),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: AppColors.surface,
                          child: const Icon(Icons.fitness_center_rounded,
                              color: AppColors.textMuted),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  gym.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
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
            // Label column
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                    alignment: Alignment.center,
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

class _PriceCell extends StatelessWidget {
  final String price;
  const _PriceCell(this.price);

  @override
  Widget build(BuildContext context) {
    return Text(
      price.isNotEmpty ? price : 'N/A',
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RatingCell extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _RatingCell(this.rating, this.reviewCount);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          '($reviewCount)',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  const _TextCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      textAlign: TextAlign.center,
    );
  }
}

class _StatusCell extends StatelessWidget {
  final bool isOpen;
  const _StatusCell(this.isOpen);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? AppColors.primary : Colors.redAccent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ListCell extends StatelessWidget {
  final List<String> items;
  const _ListCell(this.items);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('N/A',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }

    final shown = items.take(3).toList();
    final remaining = items.length - 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...shown.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
        if (remaining > 0)
          Text(
            '+$remaining more',
            style: const TextStyle(color: AppColors.primary, fontSize: 11),
          ),
      ],
    );
  }
}
