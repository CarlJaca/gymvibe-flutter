import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/gym_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../core/routes/app_router.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GymProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.sm, vertical: AppPadding.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Search Gyms',
                      controller: _searchController,
                      onChanged: (val) => provider.search(val),
                      onClear: () => provider.clearSearch(),
                    ),
                  ),
                  const SizedBox(width: AppPadding.sm),
                ],
              ),
            ),
            
            // ── Active Filters Row ───────────────────────────────────
            if (provider.activeFilters.isNotEmpty || provider.selectedCity != null)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                  children: [
                    if (provider.selectedCity != null)
                      _buildActiveChip(
                        provider.selectedCity!, 
                        onTap: () => provider.setCity(null)
                      ),
                    ...provider.activeFilters.map((f) => _buildActiveChip(
                      f, 
                      onTap: () => provider.toggleFilter(f)
                    )),
                  ],
                ),
              ),
              
            const SizedBox(height: AppPadding.md),

            // ── Results ──────────────────────────────────────────────
            Expanded(
              child: provider.gyms.isEmpty
                  ? const Center(
                      child: Text(
                        'No gyms found matching your criteria.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppPadding.md),
                      itemCount: provider.gyms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppPadding.lg),
                      itemBuilder: (context, index) {
                        final gym = provider.gyms[index];
                        return GymCard(
                          gym: gym,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.gymDetails,
                            arguments: gym,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip(String label, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onTap,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
