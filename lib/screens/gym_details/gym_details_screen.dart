import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../models/gym_model.dart';
import '../../providers/gym_provider.dart';
import '../../providers/crowd_status_provider.dart';
import '../../services/crowd_service.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/rating_progress_bar.dart';
import '../../widgets/review_card.dart';
import '../../providers/auth_provider.dart';
import '../leaderboard/leaderboard_screen.dart';

class GymDetailsScreen extends StatelessWidget {
  final GymModel gym;

  const GymDetailsScreen({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md, vertical: AppPadding.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTagsSection(),
                      const SizedBox(height: AppPadding.xl),
                      _buildTodaysCrowdSection(context),
                      const SizedBox(height: AppPadding.xl),
                      _buildFacilitiesSection(),
                      const SizedBox(height: AppPadding.xl),
                      _buildPriceSection(),
                      const SizedBox(height: AppPadding.xl),
                      _buildAddressSection(),
                      const SizedBox(height: AppPadding.xl),
                      _buildLeaderboardCard(context),
                      const SizedBox(height: AppPadding.xl),
                      _buildSocialsSection(),
                      const SizedBox(height: AppPadding.xl),
                      _buildReviewsSection(context),
                      const SizedBox(
                          height: 120), // Bottom padding for sticky CTA
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomStickyCTA(context),
        ],
      ),
    );
  }

  // ─── 1. Hero App Bar ─────────────────────────────────────────────────────────
  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<GymProvider>(
          builder: (context, provider, child) {
            final isFav = provider.isFavorite(gym.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.heart : Colors.white,
              ),
              onPressed: () => provider.toggleFavorite(gym.id),
            );
          },
        ),
        Consumer<GymProvider>(
          builder: (context, provider, child) {
            final isSaved = provider.isSaved(gym.id);
            return IconButton(
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved ? AppColors.primary : Colors.white,
              ),
              onPressed: () => provider.toggleSaved(gym.id),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'gym_image_${gym.id}',
              child: CachedNetworkImage(
                imageUrl: gym.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.3, 0.8, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppPadding.md,
              right: AppPadding.md,
              bottom: AppPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StarRating(rating: gym.rating, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${gym.rating.toStringAsFixed(1)} (${gym.reviewCount})',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Tags Section ──────────────────────────────────────────────────────────
  Widget _buildTagsSection() {
    if (gym.categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: gym.categories.map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.primary),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Today's Crowd Section ────────────────────────────────────────────────────
  Widget _buildTodaysCrowdSection(BuildContext context) {
    return Consumer<CrowdStatusProvider>(
      builder: (context, crowdProv, _) {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        final dayCount = crowdProv.getBookingCount(dateStr);
        final estimatedLevel = CrowdService.calculateCrowdLevel(dayCount, gym.capacity);
        
        final liveStatus = gym.currentLiveStatus;
        final liveLevel = CrowdService.liveStatusToCrowdLevel(liveStatus);
        final updatedAt = gym.statusUpdatedAt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Crowd',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated from bookings',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            _buildCrowdBadge(estimatedLevel),
                          ],
                        ),
                      ),
                      if (liveLevel != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live status (by owner)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              _buildCrowdBadge(liveLevel),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$dayCount / ${gym.capacity} bookings',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Updated ${_timeAgoStr(updatedAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.busyDayCalendar, arguments: gym);
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                label: const Text('View Busy Day Calendar', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCrowdBadge(CrowdLevel level) {
    Color color;
    switch (level) {
      case CrowdLevel.low:
        color = const Color(0xFF4CAF50);
        break;
      case CrowdLevel.moderate:
        color = const Color(0xFFFFCA28);
        break;
      case CrowdLevel.busy:
        color = const Color(0xFFFF9800);
        break;
      case CrowdLevel.veryBusy:
        color = const Color(0xFFF44336);
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            CrowdService.crowdLevelLabel(level),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgoStr(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  // ─── 2b. Facilities Section ───────────────────────────────────────────────────
  Widget _buildFacilitiesSection() {
    if (gym.facilities.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Facilities',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: gym.facilities.map((facility) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(facility, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── 3. Price Section ─────────────────────────────────────────────────────────
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Membership Pricing',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        // One-Day Booking Only Info Card
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.event_available_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bookings are for one day only per time slot.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (gym.sessionPrice.isNotEmpty) ...[
          Text(
            'Session Pass: ${gym.sessionPrice}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: 4),
        ],
        if (gym.monthlyPrice.isNotEmpty) ...[
          Text(
            'Monthly Membership: ${gym.monthlyPrice}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ],
      ],
    );
  }

  // ─── 4. Address Section ───────────────────────────────────────────────────────
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        Text(
          gym.address,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {}, // Keep copy if needed, but 'View on Map' is better
              child: const Text('Copy',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _launchDirections(gym),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(gym.latitude, gym.longitude),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gymvibe.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(gym.latitude, gym.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 5. Leaderboard Card ──────────────────────────────────────────────────
  Widget _buildLeaderboardCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaderboardScreen(gym: gym),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceElevated,
              AppColors.primary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gym Leaderboard',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compare PRs with other members',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Rankings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 6. Socials Section ───────────────────────────────────────────────────────
  Widget _buildSocialsSection() {
    if (gym.socials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Socials',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 12),
        ...gym.socials.entries.map((entry) {
          IconData icon;
          if (entry.key.toLowerCase().contains('facebook')) {
            icon = Icons.facebook_rounded;
          } else if (entry.key.toLowerCase().contains('mail')) {
            icon = Icons.email_rounded;
          } else {
            icon = Icons.language_rounded;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── 7. Reviews & Ratings Section ───────────────────────────────────────────
  Widget _buildReviewsSection(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, gymProv, child) {
        // Find the most up-to-date version of this gym
        final currentGym = gymProv.allGyms.firstWhere(
          (g) => g.id == gym.id, 
          orElse: () => gym
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reviews & Ratings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showWriteReviewDialog(context),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Write a Review'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StarRating(rating: currentGym.rating, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${currentGym.rating.toStringAsFixed(1)} • ${currentGym.reviewCount} Reviews',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
    
            // Progress Bars
            if (currentGym.ratingBreakdown.isNotEmpty)
              ...currentGym.ratingBreakdown.entries
                  .map((e) => RatingProgressBar(label: e.key, rating: e.value)),
    
            const SizedBox(height: 32),
    
            // Review Cards
            if (currentGym.reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No reviews yet. Be the first!', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              ...currentGym.reviews.map((review) => ReviewCard(review: review)),
          ],
        );
      }
    );
  }

  void _showWriteReviewDialog(BuildContext context) {
    double rating = 5.0;
    final TextEditingController commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Write a Review', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tap a star to rate:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.star,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final authProv = context.read<AuthProvider>();
                    if (!authProv.isAuthenticated) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post a review.')));
                      return;
                    }
                    
                    final user = authProv.currentUser!;
                    final newReview = ReviewModel(
                      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                      userName: user.name,
                      userAvatarUrl: user.avatarUrl.isNotEmpty ? user.avatarUrl : 'https://i.pravatar.cc/150?u=${user.id}',
                      rating: rating,
                      comment: commentCtrl.text,
                      date: 'Just now',
                    );
                    
                    context.read<GymProvider>().addReview(gym.id, newReview);
                    
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review posted successfully!'), 
                        backgroundColor: AppColors.success
                      )
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Post', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── 8. Bottom Sticky CTA ───────────────────────────────────────────────────
  Widget _buildBottomStickyCTA(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Call button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.call_rounded, size: 20),
                  color: AppColors.textPrimary,
                  tooltip: 'Call',
                ),
              ),
              const SizedBox(width: 8),
              // Directions button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  onPressed: () => _launchDirections(gym),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  color: AppColors.textPrimary,
                  tooltip: 'Directions',
                ),
              ),
              const SizedBox(width: 8),
              // View Schedule button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  onPressed: () => _showSchedule(context, gym.dailySchedule),
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  color: AppColors.textPrimary,
                  tooltip: 'View Schedule',
                ),
              ),
              const SizedBox(width: 12),
              // Book Now button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.booking,
                    arguments: gym,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchDirections(GymModel gym) async {
    if (gym.latitude == 0.0 || gym.longitude == 0.0) return;
    
    // Create universal map URL that works on both Android and iOS
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${gym.latitude},${gym.longitude}');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch directions for ${gym.name}');
    }
  }

  void _showSchedule(BuildContext context, Map<String, String> schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppPadding.lg),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Operating Hours',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.md),
            ...schedule.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
                      Text(e.value,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: e.value == 'Closed'
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontSize: 15)),
                    ],
                  ),
                )),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      ),
    );
  }
}
