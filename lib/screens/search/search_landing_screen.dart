import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/city_card_widget.dart';
import '../../widgets/gym_card.dart';

class SearchLandingScreen extends StatefulWidget {
  const SearchLandingScreen({super.key});

  @override
  State<SearchLandingScreen> createState() => _SearchLandingScreenState();
}

class _SearchLandingScreenState extends State<SearchLandingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<Map<String, String>> _cities = [
    {
      'name': 'Davao City',
      'image': 'https://images.unsplash.com/photo-1628148002936-39ee648a002b?q=80&w=600&auto=format&fit=crop'
    },
    {
      'name': 'Cebu City',
      'image': 'https://images.unsplash.com/photo-1518218105741-945763560bf9?q=80&w=600&auto=format&fit=crop'
    },
    {
      'name': 'Butuan City',
      'image': 'https://images.unsplash.com/photo-1542281286-9e0a16bb7366?q=80&w=600&auto=format&fit=crop'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Ensure gyms are loaded when search screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GymProvider>();
      if (provider.allGyms.isEmpty) {
        provider.loadGyms();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, GymProvider provider) {
    provider.search(query);
    setState(() {});
  }

  void _submitSearch(BuildContext context, String query, GymProvider provider) {
    if (query.isNotEmpty) {
      provider.addSearchHistory(query);
    }
    provider.search(query);
    Navigator.pushNamed(context, AppRoutes.searchResults);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.sm, vertical: AppPadding.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () {
                      if (_isSearching) {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                        provider.clearSearch();
                        FocusScope.of(context).unfocus();
                      } else {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                  const Spacer(),
                  const Text('Philippines', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus && !_isSearching) {
                    setState(() => _isSearching = true);
                  }
                },
                child: SearchBarWidget(
                  hintText: 'Search Gyms',
                  controller: _searchController,
                  onChanged: (val) => _onSearchChanged(val, provider),
                  onSubmitted: (val) => _submitSearch(context, val, provider),
                  onClear: () {
                    provider.clearSearch();
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: AppPadding.md),

            // ── Dynamic Body ─────────────────────────────────────────
            Expanded(
              child: _isSearching
                  ? (hasQuery
                      ? _buildLiveResults(provider)
                      : _buildSearchHistory(provider))
                  : _buildLandingContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  /// Live results — shown instantly as the user types
  Widget _buildLiveResults(GymProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.gyms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No gyms found for\n"${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
          child: Text(
            '${provider.gyms.length} result${provider.gyms.length == 1 ? '' : 's'} found',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(height: AppPadding.sm),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
            itemCount: provider.gyms.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppPadding.md),
            itemBuilder: (context, index) {
              final gym = provider.gyms[index];
              return GymCard(
                gym: gym,
                onTap: () {
                  provider.addSearchHistory(_searchController.text.trim());
                  Navigator.pushNamed(context, AppRoutes.gymDetails, arguments: gym);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory(GymProvider provider) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => provider.clearSearchHistory(),
              child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            )
          ],
        ),
        if (provider.searchHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('No recent searches.', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ...provider.searchHistory.map((term) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
              title: Text(term, style: const TextStyle(color: AppColors.textPrimary)),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                onPressed: () => provider.removeSearchHistory(term),
              ),
              onTap: () {
                _searchController.text = term;
                _onSearchChanged(term, provider);
              },
            )),
      ],
    );
  }

  Widget _buildLandingContent(GymProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── City Selection ────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
          child: Text(
            'Where to?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppPadding.md),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            itemBuilder: (context, index) {
              final city = _cities[index];
              return CityCardWidget(
                cityName: city['name']!,
                imageUrl: city['image']!,
                isSelected: provider.selectedCity == city['name'],
                onTap: () => provider.setCity(provider.selectedCity == city['name'] ? null : city['name']),
              );
            },
          ),
        ),
        const SizedBox(height: AppPadding.xl),

        // ── Actions ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
          child: Column(
            children: [
              _buildActionTile(
                title: 'Filters',
                onTap: () => Navigator.pushNamed(context, AppRoutes.filters),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                title: 'Sort by',
                onTap: () {},
              ),
            ],
          ),
        ),

        const Spacer(),

        // ── Footer CTA ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  provider.setCity(null);
                  provider.clearFilters();
                  _searchController.clear();
                },
                child: const Text('Clear all', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                onPressed: () => _submitSearch(context, _searchController.text, provider),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
