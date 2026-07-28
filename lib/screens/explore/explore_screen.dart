import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/promotions_provider.dart';
import '../../widgets/gym_card.dart';
import '../community/community_screen.dart';
import '../calendar/workout_calendar_screen.dart';
import '../home/customer_notifications_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'All';
  static const List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Nearby', 'icon': Icons.near_me_rounded},
    {'label': 'Top Rated', 'icon': Icons.star_rounded},
    {'label': 'Popular', 'icon': Icons.trending_up_rounded},
    {'label': 'Facilities', 'icon': Icons.fitness_center_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<GymProvider>().loadGyms();
      context.read<EventsProvider>().loadEvents();
      context.read<PromotionsProvider>().loadPromotions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${auth.userName.split(' ').first}! 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Discover gyms in Davao City',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutCalendarScreen()));
                        },
                        icon: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.textPrimary, size: 24),
                        tooltip: 'Workout Calendar',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                        },
                        icon: const Icon(Icons.people_outline_rounded,
                            color: AppColors.textPrimary, size: 24),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen()));
                        },
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: AppColors.textPrimary, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Search Bar ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.searchLanding),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Search gyms, events, promos...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Filter Chips ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final f = _filters[index];
                    final isSelected = _selectedFilter == f['label'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f['label'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                f['icon'] as IconData,
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Featured Gyms (Horizontal Carousel) ────────────────
            SliverToBoxAdapter(
              child: Consumer<GymProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }

                  final gyms = _getFilteredGyms(provider);
                  if (gyms.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No gyms found.', style: TextStyle(color: AppColors.textSecondary))),
                    );
                  }

                  // Show horizontal carousel for top gyms
                  final topGyms = gyms.take(6).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Featured Gyms',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.searchResults),
                              child: const Text('See All',
                                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: topGyms.length,
                          itemBuilder: (context, index) {
                            final gym = topGyms[index];
                            return SizedBox(
                              width: 220,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GymCard(
                                  gym: gym,
                                  onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.gymDetails,
                                      arguments: gym),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Nearby Gyms (Vertical List) ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Gyms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.searchResults),
                      child: const Text('See All',
                          style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            Consumer<GymProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final nearbyGyms = _getFilteredGyms(provider);
                if (nearbyGyms.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No gyms found.', style: TextStyle(color: AppColors.textSecondary))),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final gym = nearbyGyms[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: GymCard(
                          gym: gym,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.gymDetails,
                              arguments: gym),
                        ),
                      );
                    },
                    childCount: nearbyGyms.length.clamp(0, 5),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Upcoming Events ────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<EventsProvider>(
                builder: (context, eventsProv, _) {
                  final events = eventsProv.allEvents;
                  if (events.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Events',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See All',
                                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: events.take(5).length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event['title'] ?? 'Event',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    event['location'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.people_rounded, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${event['registeredCount'] ?? 0} going',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Active Promotions ──────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<PromotionsProvider>(
                builder: (context, promoProv, _) {
                  final promos = promoProv.allPromotions;
                  if (promos.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Promotions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See All',
                                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: promos.take(5).length,
                          itemBuilder: (context, index) {
                            final promo = promos[index];
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          promo['title'] ?? 'Promo',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    promo['description'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredGyms(GymProvider provider) {
    switch (_selectedFilter) {
      case 'Nearby':
        final sorted = List.from(provider.allGyms)
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        return sorted;
      case 'Top Rated':
        return provider.topRatedGyms;
      case 'Popular':
        final sorted = List.from(provider.allGyms)
          ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return sorted;
      case 'Facilities':
        final sorted = List.from(provider.allGyms)
          ..sort((a, b) => b.facilities.length.compareTo(a.facilities.length));
        return sorted;
      default:
        return provider.allGyms;
    }
  }
}
