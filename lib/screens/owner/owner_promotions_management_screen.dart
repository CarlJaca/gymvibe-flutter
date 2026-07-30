import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/promotions_provider.dart';
import '../../providers/gym_provider.dart';
import '../../core/routes/app_router.dart';
import 'owner_promotion_detail_screen.dart';

class OwnerPromotionsManagementScreen extends StatefulWidget {
  const OwnerPromotionsManagementScreen({super.key});

  @override
  State<OwnerPromotionsManagementScreen> createState() =>
      _OwnerPromotionsManagementScreenState();
}

class _OwnerPromotionsManagementScreenState
    extends State<OwnerPromotionsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(AppPadding.md, AppPadding.md, AppPadding.md, AppPadding.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promotions',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage gym promotions and offers',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tabs ────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Scheduled'),
                Tab(text: 'Expired'),
                Tab(text: 'Paused'),
              ],
            ),
            
            // ── Search & Filter ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search promotions...',
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list_rounded, color: AppColors.textPrimary, size: 20),
                      onPressed: () {
                        // Show filter modal
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── List View ───────────────────────────────────────────
            Expanded(
              child: Consumer2<PromotionsProvider, GymProvider>(
                builder: (context, promoProv, gymProv, _) {
                  if (promoProv.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  
                  final ownerGymId = gymProv.ownerGym.id;
                  final active = promoProv.active.where((p) => p['gymId'] == ownerGymId).toList();
                  final scheduled = promoProv.scheduled.where((p) => p['gymId'] == ownerGymId).toList();
                  final paused = promoProv.paused.where((p) => p['gymId'] == ownerGymId).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(active, promoProv),
                      _buildList(scheduled, promoProv),
                      _buildEmptyState('No expired promotions', 'Check back later.'),
                      _buildList(paused, promoProv),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.ownerCreatePromotion),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> promos, PromotionsProvider promoProv) {
    if (promos.isEmpty) return _buildEmptyState('No promotions here', 'Create a new promotion to get started.');
    return ListView.builder(
      padding: const EdgeInsets.only(
          left: AppPadding.md, right: AppPadding.md, top: 4, bottom: 80),
      itemCount: promos.length,
      itemBuilder: (context, i) => _buildPromoCard(context, promos[i], promoProv),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.discount_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, Map<String, dynamic> promo, String status) {
    return ListTile(
      title: Text(status, style: const TextStyle(color: Colors.white)),
      trailing: promo['status'] == status ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        final newPromo = Map<String, dynamic>.from(promo);
        newPromo['status'] = status;
        context.read<PromotionsProvider>().updatePromotion(promo, newPromo);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status changed to $status')));
      },
    );
  }

  Widget _buildPromoCard(BuildContext context, Map<String, dynamic> promo, PromotionsProvider promoProv) {
    final Color cardColor = promo['color'] as Color;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OwnerPromotionDetailScreen(promotion: promo)
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppPadding.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left Side Badge ─────────────────────────────────────
                  Container(
                    width: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColor,
                          cardColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.surface,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(AppPadding.lg),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Change Promotion Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 16),
                                      _buildStatusOption(context, promo, 'Active'),
                                      _buildStatusOption(context, promo, 'Scheduled'),
                                      _buildStatusOption(context, promo, 'Paused'),
                                      _buildStatusOption(context, promo, 'Expired'),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    promo['status'] ?? 'Active',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            promo['type'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),

                  // ── Right Side Details ──────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promo['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(
                            promo['description'] ?? 'Enjoy special discounts on memberships.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(promo['dates'],
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.redeem_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('${promo['claimedCount'] ?? promo['redemptions'] ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                              const SizedBox(width: 4),
                              const Text('Redeemed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
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

}
