import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/promotions_provider.dart';
import '../../providers/leaderboard_provider.dart';
import 'owner_notifications_screen.dart';
import 'owner_gym_profile_screen.dart';
import 'owner_pr_verification_screen.dart';
import '../../providers/owner_job_provider.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String _period = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // The dropdown logic for 'period' remains for UI, but the metrics will be globally computed for the gym.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer5<AuthProvider, GymProvider, EventsProvider, PromotionsProvider, OwnerJobProvider>(
          builder: (context, auth, gymProv, eventsProv, promoProv, jobProv, _) {
            if (gymProv.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final ownerName = auth.userName;
            final gymName = gymProv.ownerGym.name;
            // For testing/demo purposes, we read ALL events/promos
            // to ensure they show up in the analytics regardless of gymId mismatches.
            final ownerEvents = eventsProv.allEvents.where((e) => e['gymId'] == gymProv.ownerGym.id).toList();
            final ownerPromos = promoProv.allPromotions.where((p) => p['gymId'] == gymProv.ownerGym.id).toList();
            
            final totalEvents = ownerEvents.length;
            final totalPromotions = ownerPromos.length;
            final totalMembers = gymProv.ownerGym.memberCount;
            final totalBookings = gymProv.ownerGym.bookingsCount;
            
            int totalInterested = 0;
            for (var e in ownerEvents) {
              totalInterested += (e['interested'] as int? ?? 0);
            }
            int totalGoing = 0;
            for (var e in ownerEvents) {
              totalGoing += (e['registeredCount'] as int? ?? 0);
            }

            // Compute proportional % for each metric
            final totalActivity = (totalEvents + totalPromotions + totalMembers + totalBookings + totalInterested + totalGoing).toDouble();
            String pctOf(int val) => totalActivity > 0
                ? '${((val / totalActivity) * 100).toStringAsFixed(1)}%'
                : '0%';

            final activeJobs = jobProv.activeJobs.length;
            final totalApplicants = jobProv.ownerJobs.fold(0, (sum, job) => sum + job.applicationCount);

            final List<Map<String, dynamic>> dynamicMetrics = [
              {'label': 'Active Jobs', 'value': activeJobs.toString(), 'change': 'Live', 'up': activeJobs > 0},
              {'label': 'Total Applicants', 'value': totalApplicants.toString(), 'change': 'New', 'up': totalApplicants > 0},
              {'label': 'Total Events', 'value': totalEvents.toString(), 'change': pctOf(totalEvents), 'up': totalEvents > 0},
              {'label': 'Total Promotions', 'value': totalPromotions.toString(), 'change': pctOf(totalPromotions), 'up': totalPromotions > 0},
              {'label': 'Total Members', 'value': totalMembers.toString(), 'change': pctOf(totalMembers), 'up': totalMembers > 0},
              {'label': 'Total Bookings', 'value': totalBookings.toString(), 'change': pctOf(totalBookings), 'up': totalBookings > 0},
            ];
            
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
          onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md, vertical: AppPadding.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, $ownerName! 👋',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Here's your gym overview.",
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: AppColors.textPrimary, size: 26),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Gym Profile Card ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md, vertical: AppPadding.xs),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceElevated),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppPadding.md),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.surfaceElevated,
                                child: Icon(
                                    Icons.fitness_center_rounded,
                                    color: AppColors.primary,
                                    size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      gymName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerGymProfileScreen()));
                                      },
                                      child: const Text(
                                        'View Public Profile →',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.md)),

              // ── Overview Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Overview',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _period,
                            isDense: true,
                            dropdownColor: AppColors.surfaceElevated,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: AppColors.textSecondary),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            items: _periods
                                .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary))))
                                .toList(),
                            onChanged: (v) => setState(() => _period = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.sm)),

              // ── Stats Grid ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.md),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.0,
                  ),
                  delegate: SliverChildListDelegate(
                    dynamicMetrics
                        .map((m) => _buildStatCard(
                            m['label'], m['value'], m['change'], m['up']))
                        .toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.lg)),

              // ── Pending PRs Card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                  child: Consumer<LeaderboardProvider>(
                    builder: (context, lbProv, _) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OwnerPrVerificationScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: lbProv.pendingCount > 0
                                  ? Colors.orange.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.emoji_events_rounded,
                                        color: Colors.orange, size: 22),
                                    if (lbProv.pendingCount > 0)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${lbProv.pendingCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending PR Verification',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lbProv.pendingCount > 0
                                          ? '${lbProv.pendingCount} record(s) awaiting review'
                                          : 'No pending records',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),
            ],
          ),
        );
        },
      ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String pct, bool isPositive) {
    return Container(
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
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                pct,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
