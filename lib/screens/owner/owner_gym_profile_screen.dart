import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import 'dart:io';
import '../../models/gym_model.dart';
import '../../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/routes/app_router.dart';
import 'edit_gym_location_screen.dart';

class OwnerGymProfileScreen extends StatefulWidget {
  const OwnerGymProfileScreen({super.key});

  @override
  State<OwnerGymProfileScreen> createState() => _OwnerGymProfileScreenState();
}

class _OwnerGymProfileScreenState extends State<OwnerGymProfileScreen> {
  bool _isUploading = false;

  Future<void> _uploadCoverImage(GymModel gym) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        
        final file = File(result.files.single.path!);
        final newUrl = await storageService.uploadGymCoverImage(gym.id, file);
        
        if (!mounted) return;
        
        // Update gym model
        final gymProv = context.read<GymProvider>();
        await gymProv.updateOwnerGym(gym.copyWith(imageUrl: newUrl));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover image updated!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showEditPlanDialog(MembershipPlan plan, int index) {
    final nameCtrl = TextEditingController(text: plan.name);
    final priceCtrl = TextEditingController(text: plan.monthlyPrice.toStringAsFixed(0));
    final featuresCtrl = TextEditingController(text: plan.features);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Membership Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₱)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: featuresCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final gymProv = context.read<GymProvider>();
              final gym = gymProv.ownerGym;
              final updatedPlans = List<MembershipPlan>.from(gym.membershipPlans);

              updatedPlans[index] = MembershipPlan(
                id: plan.id,
                name: nameCtrl.text.trim(),
                monthlyPrice: double.tryParse(priceCtrl.text.trim()) ?? plan.monthlyPrice,
                features: featuresCtrl.text.trim(),
                isRecommended: plan.isRecommended,
              );

              gymProv.updateOwnerGym(gym.copyWith(membershipPlans: updatedPlans));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(GymModel gym) {
    final nameCtrl = TextEditingController(text: gym.name);
    final addressCtrl = TextEditingController(text: gym.address);
    final hoursCtrl = TextEditingController(text: gym.hours);
    final descCtrl = TextEditingController(text: gym.description);
    final priceCtrl = TextEditingController(text: gym.monthlyPrice);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Gym Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Gym Name')),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Operating Hours')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Monthly Price')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final gymProv = context.read<GymProvider>();
              gymProv.updateOwnerGym(gym.copyWith(
                name: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                hours: hoursCtrl.text.trim(),
                monthlyPrice: priceCtrl.text.trim(),
                description: descCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GymProvider>(
        builder: (context, gymProv, _) {
          if (gymProv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final gym = gymProv.ownerGym;
          
          return CustomScrollView(
            slivers: [
          // ── Hero ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => _showEditProfileDialog(gym),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    gym.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.surfaceElevated),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          AppColors.background,
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  if (_isUploading)
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                        onPressed: _isUploading ? null : () => _uploadCoverImage(gym),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppPadding.sm),

                  // ── Gym Identity ─────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.surfaceElevated,
                        child: Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    gym.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full),
                                  ),
                                  child: const Icon(Icons.verified_rounded,
                                      color: AppColors.primary, size: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.star, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${gym.rating} (${gym.reviewCount} Reviews)',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.location_on_rounded,
                                    color: AppColors.textMuted, size: 12),
                                const Text('0.8 km',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.md),

                  // ── Categories ───────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gym.categories
                        .map((c) => _chip(c))
                        .toList(),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── About ────────────────────────────────────────
                  const Text('About',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    gym.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── Price ─────────────────────────────────────────
                  const Text('Membership Pricing',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (gym.sessionPrice.isNotEmpty) ...[
                    Text(
                      'Session Pass: ${gym.sessionPrice}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (gym.monthlyPrice.isNotEmpty) ...[
                    Text(
                      'Monthly Membership: ${gym.monthlyPrice}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: AppPadding.lg),

                  // ── Address ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Address',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditGymLocationScreen()));
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Edit on Map'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gym.address,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── Schedule ──────────────────────────────────────
                  if (gym.dailySchedule.isNotEmpty) ...[
                    const Text('Schedule',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...gym.dailySchedule.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 14)),
                            ),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppPadding.lg),
                  ],

                  // ── Socials ───────────────────────────────────────
                  if (gym.socials.isNotEmpty) ...[
                    const Text('Socials',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...gym.socials.entries.map((entry) {
                      IconData icon;
                      if (entry.key.toLowerCase().contains('facebook')) {
                        icon = Icons.facebook_rounded;
                      } else if (entry.key.toLowerCase().contains('mail')) {
                        icon = Icons.email_rounded;
                      } else {
                        icon = Icons.language_rounded;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(icon, color: AppColors.primary, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppPadding.lg),
                  ],

                  // ── Facilities ───────────────────────────────────
                  const Text('Facilities',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppPadding.sm),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.start,
                    children: gym.facilities.map((f) {
                      return SizedBox(
                        width: 70,
                        child: _facilityItem(Icons.check_circle_outline, f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // ── Membership Plans ─────────────────────────────
                  const Text('Membership Plans',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Tap a plan to edit it',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: AppPadding.sm),
                  ...gym.membershipPlans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _showEditPlanDialog(plan, index),
                        child: _membershipCard(
                          plan.name,
                          '₱${plan.monthlyPrice.toStringAsFixed(0)}',
                          plan.features,
                          highlight: plan.isRecommended,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppPadding.xl),

                  // ── Edit Profile CTA ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.ownerEditProfile);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),
                ],
              ),
            ),
          ),
        ],
      );
      },
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _facilityItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2),
      ],
    );
  }

  Widget _membershipCard(String title, String price, String subtitle,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highlight
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(price,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? AppColors.primary
                      : AppColors.textPrimary)),
          if (highlight) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text('Popular',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}
