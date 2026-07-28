// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/recommendation_service.dart';
import '../preferences/gym_preferences_screen.dart';
import '../community/community_screen.dart';
import '../calendar/workout_calendar_screen.dart';
import '../home/customer_notifications_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _showAllGyms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GymProvider>().loadGyms();

      // Load user fitness preferences into GymProvider
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        final prefs = authProvider.currentUser!.fitnessPreferences;
        if (prefs.isNotEmpty) {
          context.read<GymProvider>().setUserPreferences(prefs);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer2<GymProvider, AuthProvider>(
          builder: (context, gymProvider, authProvider, _) {
            final hasPreferences = authProvider.currentUser != null &&
                authProvider.currentUser!.fitnessPreferences.isNotEmpty;
            final matchResults = gymProvider.matchResults;

            return CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Your Matches',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const WorkoutCalendarScreen()));
                          },
                          icon: const Icon(Icons.calendar_month_rounded,
                              color: AppColors.textPrimary, size: 24),
                          tooltip: 'Workout Calendar',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CommunityScreen()));
                          },
                          icon: const Icon(Icons.people_outline_rounded,
                              color: AppColors.textPrimary, size: 24),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomerNotificationsScreen()));
                          },
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: AppColors.textPrimary, size: 24),
                        ),
                        if (hasPreferences)
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                            tooltip: 'Edit Preferences',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GymPreferencesScreen(isFirstTime: false),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // ── No Preferences State ───────────────────────────
                if (!hasPreferences)
                  SliverFillRemaining(
                    child: _buildEmptyState(context),
                  ),

                // ── Loading State ──────────────────────────────────
                if (hasPreferences && gymProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),

                // ── Has Preferences + Results ──────────────────────
                if (hasPreferences && !gymProvider.isLoading) ...[
                  // Hero summary card
                  SliverToBoxAdapter(
                    child: _buildHeroCard(matchResults),
                  ),

                  // Match count banner
                  if (matchResults.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Best Matches',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${matchResults.length} found',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Ranked gym cards
                  if (matchResults.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final displayCount = _showAllGyms
                              ? matchResults.length
                              : matchResults.length.clamp(0, 3);
                          if (index >= displayCount) return null;

                          final result = matchResults[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 6),
                            child: _buildMatchCard(context, result, index + 1),
                          );
                        },
                        childCount: _showAllGyms
                            ? matchResults.length
                            : matchResults.length.clamp(0, 3),
                      ),
                    ),

                  // View more button
                  if (matchResults.length > 3 && !_showAllGyms)
                    SliverToBoxAdapter(
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showAllGyms = true),
                          icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
                          label: const Text(
                            'View more gyms',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                  // Why these gyms match you section
                  if (matchResults.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildWhyMatchSection(authProvider),
                    ),

                  // Empty matches
                  if (matchResults.isEmpty && !gymProvider.isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              const Text(
                                'No matches found',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try updating your preferences for better results.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Matches Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set your fitness preferences to get\npersonalized gym matches.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GymPreferencesScreen(isFirstTime: false),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Set Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(List<GymMatchResult> results) {
    final topMatch = results.isNotEmpty ? results.first.matchPercentage : 0;
    final matchedCount = results.where((r) => r.matchPercentage > 50).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'We found your perfect matches!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Based on your preferences using\nJaccard Similarity Algorithm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Match summary badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$matchedCount gym${matchedCount == 1 ? '' : 's'} matched',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  Top: $topMatch%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, GymMatchResult result, int rank) {
    final gym = result.gym;
    final matchPct = result.matchPercentage;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.gymDetails, arguments: gym);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gym image with rank badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                  child: SizedBox(
                    width: 110,
                    height: 140,
                    child: Image.network(
                      gym.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.fitness_center_rounded,
                            color: AppColors.textMuted, size: 32),
                      ),
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match badge + heart
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _matchColor(matchPct).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '$matchPct% Match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _matchColor(matchPct),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Gym name
                    Text(
                      gym.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Distance + location
                    Row(
                      children: [
                        if (gym.distanceKm > 0) ...[
                          Text(
                            '${gym.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                        Expanded(
                          child: Text(
                            '${gym.address}, ${gym.city}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          gym.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' (${gym.reviewCount})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            context.read<GymProvider>().toggleFavorite(gym.id);
                          },
                          child: Icon(
                            gym.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: gym.isFavorite ? Colors.red : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Facility tags
                    SizedBox(
                      height: 22,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...gym.facilities.take(3).map((f) => _buildTag(f)),
                          if (gym.facilities.length > 3)
                            _buildTag('+${gym.facilities.length - 3}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Price
                    Text(
                      gym.monthlyPrice.isNotEmpty ? '${gym.monthlyPrice} / month' : '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }

  Color _matchColor(int pct) {
    if (pct >= 80) return AppColors.primary;
    if (pct >= 60) return AppColors.success;
    if (pct >= 40) return Colors.amber;
    return AppColors.textSecondary;
  }

  Widget _buildWhyMatchSection(AuthProvider authProvider) {
    final prefs = authProvider.currentUser?.fitnessPreferences ?? [];

    // Build human-readable reasons from preferences
    final reasons = <String>[];
    bool hasFacilities = false;
    bool hasDistance = false;
    bool hasBudget = false;
    bool hasGoals = false;

    for (final p in prefs) {
      if (p.startsWith('facility:')) hasFacilities = true;
      if (p.startsWith('distance:')) hasDistance = true;
      if (p.startsWith('budget:')) hasBudget = true;
      if (p.startsWith('goal:')) hasGoals = true;
    }

    if (hasFacilities) reasons.add('High similarity in facilities you prefer');
    if (hasDistance) reasons.add('Within your preferred distance');
    if (hasBudget) reasons.add('Fits your budget range');
    if (hasGoals) reasons.add('Supports your fitness goals');

    if (reasons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why these gyms match you?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
