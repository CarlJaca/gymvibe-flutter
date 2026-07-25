import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/promotions_provider.dart';
import 'claimed_users_screen.dart';

class PromotionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promo;

  const PromotionDetailScreen({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    final color = promo['color'] as Color;
    final claimed = (promo['claimedCount'] as num?)?.toInt() ?? 0;
    final total = (promo['totalSlots'] as num?)?.toInt() ?? 1;
    final progress = claimed / total;
    final bool isFullyClaimed = claimed >= total;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroBanner(context, color),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(color),
                      const SizedBox(height: 24),
                      _buildDescription(color),
                      const SizedBox(height: 24),
                      _buildProgressSection(context, progress, claimed, color),
                      const SizedBox(height: 24),
                      _buildTerms(),
                      const SizedBox(height: 120), // padding for bottom CTA
                    ],
                  ),
                ),
              )
            ],
          ),
          _buildBottomCTA(context, isFullyClaimed, color),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, Color color) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.backgroundDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.6),
                AppColors.backgroundDark,
              ],
              stops: const [0.0, 0.8],
            ),
          ),
          child: Center(
            child: Text(
              promo['type'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(blurRadius: 20, color: Colors.black54, offset: Offset(0, 4)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                promo['status'],
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Consumer<PromotionsProvider>(
              builder: (context, provider, _) => GestureDetector(
                onTap: () => provider.toggleSave(promo['id']),
                child: Icon(
                  promo['isSaved'] ? Icons.bookmark : Icons.bookmark_border,
                  color: promo['isSaved'] ? color : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          promo['title'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              promo['dates'],
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Promotion',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          promo['description'],
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, double progress, int claimed, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  const Text('Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$claimed claimed', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('${promo['totalSlots']} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const Divider(color: AppColors.border, height: 32),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClaimedUsersScreen(promo: promo)),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('View Claimed Users', style: TextStyle(color: Colors.white)),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List<String>.from(promo['terms'] ?? []).map((term) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              Expanded(
                child: Text(term, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context, bool isFullyClaimed, Color color) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(AppPadding.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.8),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Consumer<PromotionsProvider>(
                builder: (context, provider, _) {
                  final bool isClaimed = promo['isClaimed'] ?? false;
                  if (isClaimed) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: const Text('Already Claimed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isFullyClaimed ? null : () {
                        provider.claimOffer(promo['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Promotion claimed successfully!'),
                            backgroundColor: color,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFullyClaimed ? AppColors.border : color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text(
                        isFullyClaimed ? 'Fully Claimed' : 'Claim Offer',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}
