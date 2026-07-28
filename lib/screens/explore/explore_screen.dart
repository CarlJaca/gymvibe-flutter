// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/gym_card.dart';
import '../../widgets/explore_gym_tile.dart';
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
  final MapController _mapController = MapController();

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
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildAllGymsTab(),
                      _buildExploreMapTab(),
                    ],
                  );
                },
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
  // TAB 2: Explore (Real Map with flutter_map + OpenStreetMap)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExploreMapTab() {
    return Stack(
      children: [
        _buildMapView(),
        _buildMyLocationButton(),
      ],
    );
  }

  Widget _buildMapView() {
    return Consumer<GymProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final gyms = provider.allGyms
            .where((g) => g.latitude != 0.0 && g.longitude != 0.0)
            .toList();
        // Center on Davao City
        const initialCenter = LatLng(7.0700, 125.6000);

        return Consumer<LocationProvider>(
          builder: (context, locProvider, _) {
            final userLoc = locProvider.currentLocation;

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLoc ?? initialCenter,
                initialZoom: userLoc != null ? 14.0 : 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gymvibe',
                ),
                MarkerLayer(
                  markers: gyms.map((gym) {
                    return Marker(
                      point: LatLng(gym.latitude, gym.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          _showGymPreview(context, gym);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(userLoc != null
                        ? [
                            Marker(
                              point: userLoc,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            )
                          ]
                        : []),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Consumer<LocationProvider>(
        builder: (context, locProvider, _) {
          return FloatingActionButton(
            heroTag: 'my_location_fab',
            backgroundColor: AppColors.surface,
            onPressed: () async {
              await locProvider.fetchCurrentLocation();
              if (locProvider.currentLocation != null) {
                _mapController.move(locProvider.currentLocation!, 15.0);
              }
              if (locProvider.errorMessage != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(locProvider.errorMessage!),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: locProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : const Icon(Icons.my_location_rounded,
                    color: AppColors.primary),
          );
        },
      ),
    );
  }

  void _showGymPreview(BuildContext context, dynamic gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppPadding.md),
            ExploreGymTile(
              gym: gym,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.gymDetails,
                    arguments: gym);
              },
            ),
            const SizedBox(height: AppPadding.lg),
          ],
        ),
      ),
    );
  }
}
