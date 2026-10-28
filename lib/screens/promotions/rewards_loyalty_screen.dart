import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/promotions_provider.dart';

class RewardsLoyaltyScreen extends StatelessWidget {
  const RewardsLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text('Rewards & Loyalty', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PromotionsProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(provider.loyaltyLevel, provider.loyaltyPoints),
                const SizedBox(height: 32),
                const Text('Milestones', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMilestone('Bronze', '0 - 500 points', 'Basic access to offers', provider.loyaltyPoints >= 0, Colors.brown[300]!),
                _buildMilestone('Silver', '501 - 1000 points', 'Early access to seasonal promos', provider.loyaltyPoints >= 501, Colors.grey[400]!),
                _buildMilestone('Gold', '1001 - 2500 points', 'Exclusive VIP discounts', provider.loyaltyPoints >= 1001, AppColors.star),
                _buildMilestone('Platinum', '2501+ points', 'Free premium merch every month', provider.loyaltyPoints >= 2501, Colors.blueGrey[200]!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String level, int points) {
    Color levelColor = AppColors.star;
    if (level == 'Bronze') levelColor = Colors.brown[300]!;
    if (level == 'Silver') levelColor = Colors.grey[400]!;
    if (level == 'Platinum') levelColor = Colors.blueGrey[200]!;

    final double progress = points / 2500; // max points for next major tier calculation

    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: levelColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text(level, style: TextStyle(color: levelColor, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.workspace_premium, color: levelColor, size: 48),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$points points', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Platinum at 2501', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestone(String title, String subtitle, String desc, bool unlocked, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.sm),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            color: unlocked ? color : AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: unlocked ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: unlocked ? Colors.white70 : AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
