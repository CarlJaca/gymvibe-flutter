import 'package:flutter/material.dart';
import '../community/community_screen.dart';
import '../calendar/workout_calendar_screen.dart';
import 'customer_notifications_screen.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/promotions_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/gym_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<GymProvider>().loadGyms();
      context.read<CommunityProvider>().loadCommunityData();
      context.read<EventsProvider>().loadEvents();
      context.read<PromotionsProvider>().loadPromotions();

      // Load user fitness preferences into GymProvider for Jaccard recommendations
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        // Load notifications from Firestore
        context.read<NotificationProvider>().loadNotifications(authProvider.currentUser!.id);

        final rawPrefs = authProvider.currentUser!.fitnessPreferences;
        final jaccardPrefs = <String>[];
        for (final p in rawPrefs) {
          if (p.startsWith('goal:')) {
            jaccardPrefs.add(p.substring(5));
          } else if (!p.startsWith('budget:') && !p.startsWith('trainer:')) {
            jaccardPrefs.add(p);
          }
        }
        context.read<GymProvider>().setUserPreferences(jaccardPrefs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () async { context.read<GymProvider>().loadGyms(); },
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md, vertical: AppPadding.sm),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${auth.userName.split(' ').first}!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Ready to crush your goals today?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutCalendarScreen()));
                              },
                              icon: const Icon(Icons.calendar_month_rounded,
                                  color: AppColors.textPrimary, size: 26),
                              tooltip: 'Workout Calendar',
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                              },
                              icon: const Icon(Icons.people_outline_rounded,
                                  color: AppColors.textPrimary, size: 26),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen()));
                              },
                              icon: const Icon(Icons.notifications_none_rounded,
                                  color: AppColors.textPrimary, size: 26),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search Bar ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.searchLanding),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppPadding.md, vertical: AppPadding.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.md, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Search gyms, events, promos...',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.md)),

              // ── Recommended For You ────────────────────────────────
              SliverToBoxAdapter(
                child: Consumer<GymProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      );
                    }
                    final gyms = provider.recommendedGyms;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                AppStrings.recommended,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.searchResults),
                                child: const Text(AppStrings.seeAll,
                                    style:
                                        TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                        // Horizontal carousel
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.md),
                            itemCount: gyms.length,
                            itemBuilder: (context, index) {
                              final gym = gyms[index];
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

              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.lg)),

              // ── Nearby Gyms ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.nearbyGyms,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.searchResults),
                        child: const Text(AppStrings.seeAll,
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.sm)),

              Consumer<GymProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  if (provider.errorMessage != null) {
                    return SliverToBoxAdapter(
                        child: Center(child: Text(provider.errorMessage!)));
                  }
                  if (provider.allGyms.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: Center(child: Text('No gyms found.')));
                  }

                  final nearbyGyms = provider.allGyms.skip(2).toList();
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final gym = nearbyGyms[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.md, vertical: 4),
                          child: GymCard(
                            gym: gym,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.gymDetails,
                                arguments: gym),
                          ),
                        );
                      },
                      childCount: nearbyGyms.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppPadding.xl)),
            ],
          ),
        ),
      ),
    );
  }
}
