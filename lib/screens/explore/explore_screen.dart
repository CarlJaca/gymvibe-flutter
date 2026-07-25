import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/explore_gym_tile.dart';
import '../../widgets/section_header.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.sm, vertical: AppPadding.sm),
              child: Row(
                children: [
                  const SizedBox(width: 48), // Balance the search icon for centered tabs
                  const Spacer(),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabAlignment: TabAlignment.center,
                    tabs: const [
                      Tab(text: AppStrings.topRated),
                      Tab(text: AppStrings.explore),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    onPressed: () => Navigator.pushNamed(context, '/search-landing'),
                  ),
                ],
              ),
            ),

            // ── Title ───────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.sm),
              child: Center(
                child: Text(
                  AppStrings.davaoCityTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ── Tab 1: For You (List) ──
                  Consumer<GymProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      final topRated = provider.topRatedGyms;

                      return ListView(
                        padding: const EdgeInsets.all(AppPadding.md),
                        children: [
                          const SectionHeader(
                            title: AppStrings.topRated,
                            leadingIcon: Icons.emoji_events_rounded,
                          ),
                          const SizedBox(height: AppPadding.md),
                          ...topRated.map((gym) => ExploreGymTile(
                                gym: gym,
                                onTap: () {
                                  Navigator.pushNamed(context, '/gym-details', arguments: gym);
                                },
                              )),
                        ],
                      );
                    },
                  ),

                  // ── Tab 2: Explore (Map) ──
                  Stack(
                    children: [
                      _buildMapView(),
                      _buildMyLocationButton(),
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

  Widget _buildMapView() {
    return Consumer<GymProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final gyms = provider.allGyms.where((g) => g.latitude != 0.0 && g.longitude != 0.0).toList();
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  }).toList()..addAll(
                    userLoc != null ? [
                      Marker(
                        point: userLoc,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      )
                    ] : []
                  ),
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
                  SnackBar(content: Text(locProvider.errorMessage!), backgroundColor: AppColors.error),
                );
              }
            },
            child: locProvider.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, color: AppColors.primary),
          );
        },
      ),
    );
  }

  void _showGymPreview(BuildContext context, gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppPadding.md),
            ExploreGymTile(
              gym: gym,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gym-details', arguments: gym);
              },
            ),
            const SizedBox(height: AppPadding.lg),
          ],
        ),
      ),
    );
  }
}
