import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/promotions_provider.dart';

class MyClaimedPromotionsScreen extends StatefulWidget {
  const MyClaimedPromotionsScreen({super.key});

  @override
  State<MyClaimedPromotionsScreen> createState() => _MyClaimedPromotionsScreenState();
}

class _MyClaimedPromotionsScreenState extends State<MyClaimedPromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text('My Claimed Promotions', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: Consumer<PromotionsProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.myActiveClaimed),
              _buildList(provider.myExpiredClaimed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> promos) {
    if (promos.isEmpty) {
      return const Center(
        child: Text('No claimed promotions found.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: promos.length,
      itemBuilder: (context, index) {
        final promo = promos[index];
        final color = promo['color'] as Color;
        final bool isExpired = promo['status'] == 'Expired';
        final displayColor = isExpired ? AppColors.textSecondary : color;

        return Container(
          margin: const EdgeInsets.only(bottom: AppPadding.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            displayColor.withValues(alpha: isExpired ? 0.4 : 0.8),
                            displayColor.withValues(alpha: isExpired ? 0.1 : 0.3),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          promo['type'],
                          style: TextStyle(
                            color: isExpired ? Colors.white54 : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: displayColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                promo['status'],
                                style: TextStyle(color: displayColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promo['title'],
                              style: TextStyle(color: isExpired ? Colors.white54 : Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Claimed on ${promo['claimDate']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Savings Earned', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                Text('₱${promo['savings']}', style: const TextStyle(color: AppColors.star, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
