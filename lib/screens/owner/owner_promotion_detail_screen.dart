import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/promotions_provider.dart';

class OwnerPromotionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promotion;

  const OwnerPromotionDetailScreen({super.key, required this.promotion});

  @override
  Widget build(BuildContext context) {
    final promoProv = context.watch<PromotionsProvider>();
    final bool isPaused = promoProv.paused.contains(promotion);
    final Color cardColor = promotion['color'] as Color? ?? AppColors.primary;
    final int redeemedCount = promotion['claimedCount'] ?? promotion['redemptions'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Promotion Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),

                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppPadding.md),
                children: [
                  // ── Hero Banner ────────────────────────────────────────
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cardColor.withValues(alpha: 0.9), Colors.transparent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text(
                                promotion['type'] ?? '20% OFF',
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'LIMITED TIME OFFER!',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── Title & Description ────────────────────────────────
                  Text(
                    promotion['title'] ?? 'Promotion Title',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promotion['description'] ?? 'Enjoy special discounts on all membership plans. Build your fitness journey with us!',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── Information List ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.calendar_today_rounded, 'Duration', promotion['dates'] ?? 'May 1 – May 31, 2025', subtitle: '31 days remaining'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.people_alt_outlined, 'Applicable To', 'All Membership Plans'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.local_offer_outlined, 'Discount Type', 'Percentage Discount'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.percent_rounded, 'Discount Value', promotion['type'] ?? '20%'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.person_outline_rounded, 'Usage Limit', '1 time per user'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.shopping_bag_outlined, 'Minimum Purchase', 'No Minimum'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.access_time_rounded, 'Created On', 'April 25, 2025 at 10:30 AM'),
                        const Divider(height: 1, color: AppColors.border),
                        _buildInfoRow(Icons.account_circle_outlined, 'Created By', 'John Doe (Owner)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),

                  // ── Redemption Information ─────────────────────────────
                  const Text('Promotion Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.redeem_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Redeemed', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('$redeemedCount Members', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),

                  // ── Terms & Conditions ─────────────────────────────────
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text('Terms & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: Colors.white,
                      iconColor: AppColors.primary,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BulletText('Valid for all membership plans.'),
                              SizedBox(height: 8),
                              _BulletText('Cannot be combined with other promotions.'),
                              SizedBox(height: 8),
                              _BulletText('One redemption per member.'),
                              SizedBox(height: 8),
                              _BulletText('Valid only during promotional period.'),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl * 1.5),

                  // ── Action Buttons ─────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: () => _editPromo(context, promotion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Promotion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      promoProv.togglePause(promotion);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isPaused ? 'Promotion resumed' : 'Promotion paused')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isPaused ? Icons.play_arrow_outlined : Icons.pause_circle_outline),
                    label: Text(isPaused ? 'Resume Promotion' : 'Pause Promotion', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      promoProv.duplicatePromotion(promotion);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promotion duplicated')),
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.file_copy_outlined),
                    label: const Text('Duplicate Promotion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      promoProv.removePromotion(promotion);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promotion deleted')),
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Promotion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: AppPadding.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.success, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _editPromo(BuildContext context, Map<String, dynamic> promo) {
    final titleCtrl = TextEditingController(text: promo['title']);
    final datesCtrl = TextEditingController(text: promo['dates']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: datesCtrl,
              decoration: const InputDecoration(labelText: 'Dates'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Mock update action
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Promotion updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4))),
      ],
    );
  }
}
