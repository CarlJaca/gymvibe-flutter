// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/gym_card.dart';
import '../community/community_screen.dart';
import '../calendar/workout_calendar_screen.dart';
import '../home/customer_notifications_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GymProvider>().loadGyms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const WorkoutCalendarScreen()));
                      },
                      icon: Icon(Icons.calendar_month_rounded,
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
                      icon: Icon(Icons.people_outline_rounded,
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
                      icon: Icon(Icons.notifications_none_rounded,
                          color: AppColors.textPrimary, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ─────────────────────────────────────────
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.searchLanding),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Search gyms...',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab Bar ────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'All Gyms'),
                  Tab(text: 'Explore'),
                ],
              ),
            ),

            // ── Tab Content ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllGymsTab(),
                  _buildExploreMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: All Gyms
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAllGymsTab() {
    return Consumer<GymProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final gyms = provider.allGyms;
        if (gyms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center_rounded,
                    size: 48, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('No gyms available.',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            final gym = gyms[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GymCard(
                gym: gym,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.gymDetails,
                    arguments: gym),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: Explore (Map-style location view)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExploreMapTab() {
    return Consumer<GymProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final gyms = List.from(provider.allGyms)
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

        if (gyms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded,
                    size: 48, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('No gyms to explore.',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Map placeholder area
            Container(
              height: 220,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  // Map background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.surfaceElevated,
                      child: CustomPaint(
                        painter: _MapGridPainter(),
                      ),
                    ),
                  ),
                  // Gym pin markers
                  ...gyms.take(6).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final gym = entry.value;
                    // Distribute pins across the map area
                    final positions = [
                      Offset(0.3, 0.35),
                      Offset(0.65, 0.25),
                      Offset(0.5, 0.55),
                      Offset(0.2, 0.65),
                      Offset(0.75, 0.6),
                      Offset(0.45, 0.3),
                    ];
                    final pos = positions[index % positions.length];
                    return Positioned(
                      left: pos.dx *
                          (MediaQuery.of(context).size.width - 40) -
                          16,
                      top: pos.dy * 220 - 32,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.gymDetails,
                            arguments: gym),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                gym.name.length > 12
                                    ? '${gym.name.substring(0, 12)}...'
                                    : gym.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 24),
                          ],
                        ),
                      ),
                    );
                  }),
                  // "Davao City" label
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Davao City',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Gym count badge
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${gyms.length} gyms nearby',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Nearby header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.near_me_rounded,
                      size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Nearby Gyms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Sorted by distance',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Nearby gym list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: gyms.length,
                itemBuilder: (context, index) {
                  final gym = gyms[index];
                  return _buildExploreGymTile(gym);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExploreGymTile(dynamic gym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.pushNamed(context, AppRoutes.gymDetails,
            arguments: gym),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Gym image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.network(
                    gym.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.fitness_center_rounded,
                          color: AppColors.textMuted, size: 24),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textMuted),
                        SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${gym.address}, ${gym.city}',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        SizedBox(width: 3),
                        Text(
                          gym.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gym.isOpen
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            gym.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: gym.isOpen
                                  ? AppColors.primary
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance badge
              Column(
                children: [
                  Icon(Icons.near_me_rounded,
                      size: 16, color: AppColors.primary),
                  SizedBox(height: 4),
                  Text(
                    gym.distanceKm > 0
                        ? '${gym.distanceKm.toStringAsFixed(1)} km'
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a subtle grid to simulate a map background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw a couple of "road" lines
    final roadPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    canvas.drawLine(
        Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.45),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.35, 0),
        Offset(size.width * 0.4, size.height),
        roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
