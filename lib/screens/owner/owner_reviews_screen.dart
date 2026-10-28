import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  int _filterStars = 0; // 0 = All

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'John D.',
      'avatar': 'https://i.pravatar.cc/80?img=11',
      'rating': 5,
      'text': 'Great equipment and amazing trainers! Very recommended gym in Davao.',
      'time': '2h ago',
    },
    {
      'name': 'Sarah M.',
      'avatar': 'https://i.pravatar.cc/80?img=47',
      'rating': 5,
      'text': 'I love the atmosphere and friendly staff. The classes are motivating!',
      'time': '5d ago',
    },
    {
      'name': 'Mike R.',
      'avatar': 'https://i.pravatar.cc/80?img=13',
      'rating': 4,
      'text': 'Good facilities and clean environment. Keep it up!',
      'time': '30d ago',
    },
    {
      'name': 'Ana L.',
      'avatar': 'https://i.pravatar.cc/80?img=32',
      'rating': 4,
      'text': 'Nice gym! Love the morning classes. Could use more cardio machines.',
      'time': '45d ago',
    },
    {
      'name': 'Carlos P.',
      'avatar': 'https://i.pravatar.cc/80?img=58',
      'rating': 3,
      'text': 'Decent gym but parking can be an issue on peak hours.',
      'time': '60d ago',
    },
  ];

  List<Map<String, dynamic>> get _filtered => _filterStars == 0
      ? _reviews
      : _reviews.where((r) => r['rating'] == _filterStars).toList();

  double get _avgRating =>
      _reviews.fold(0.0, (s, r) => s + (r['rating'] as int)) / _reviews.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.md, vertical: AppPadding.sm),
              child: Text('Reviews',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),

            // ── Stats Row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md),
              child: Container(
                padding: const EdgeInsets.all(AppPadding.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < _avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.star,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('${_reviews.length} Reviews',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: AppPadding.lg),
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((stars) {
                          final count = _reviews
                              .where((r) => r['rating'] == stars)
                              .length;
                          final frac = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('$stars',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: frac,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.star),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('$count',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Filter Chips ─────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.md),
                children: [
                  _filterChip('All', 0),
                  _filterChip('5 ★', 5),
                  _filterChip('4 ★', 4),
                  _filterChip('3 ★', 3),
                  _filterChip('2 ★', 2),
                  _filterChip('1 ★', 1),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Review List ──────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('No reviews for this rating.',
                          style:
                              TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.md),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildReviewCard(_filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int stars) {
    final bool selected = _filterStars == stars;
    return GestureDetector(
      onTap: () => setState(() => _filterStars = stars),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reviewer ─────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review['avatar']),
                backgroundColor: AppColors.surfaceElevated,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (review['rating'] as int)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.star,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(review['time'],
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: AppPadding.sm),

          // ── Review Text ──────────────────────────────────────────
          Text(review['text'],
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: AppPadding.sm),

          // ── Actions ──────────────────────────────────────────────
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.reply_rounded, size: 14),
                label: const Text('Reply', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.star_border_rounded, size: 14),
                label: const Text('Highlight',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flag_outlined, size: 14),
                label:
                    const Text('Report', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
