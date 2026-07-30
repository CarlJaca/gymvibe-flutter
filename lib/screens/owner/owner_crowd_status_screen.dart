import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';
import '../../providers/crowd_status_provider.dart';
import '../../services/crowd_service.dart';

class OwnerCrowdStatusScreen extends StatefulWidget {
  const OwnerCrowdStatusScreen({super.key});

  @override
  State<OwnerCrowdStatusScreen> createState() => _OwnerCrowdStatusScreenState();
}

class _OwnerCrowdStatusScreenState extends State<OwnerCrowdStatusScreen> {
  final _capacityController = TextEditingController();
  bool _isEditingCapacity = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch today's data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gymProv = context.read<GymProvider>();
      final crowdProv = context.read<CrowdStatusProvider>();
      
      if (gymProv.ownerGym.id != 'placeholder') {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        crowdProv.loadBookingCountForDate(gymProv.ownerGym.id, dateStr);
        _capacityController.text = gymProv.ownerGym.capacity.toString();
      }
    });
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GymProvider, CrowdStatusProvider>(
      builder: (context, gymProv, crowdProv, _) {
        if (gymProv.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final gym = gymProv.ownerGym;
        if (gym.id == 'placeholder') {
          return const Center(
            child: Text('Please register a gym first.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final dayCount = crowdProv.getBookingCount(dateStr);
        final estimatedLevel = CrowdService.calculateCrowdLevel(dayCount, gym.capacity);
        final liveLevel = CrowdService.liveStatusToCrowdLevel(gym.currentLiveStatus);

        return ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            // ─── Today's Overview ──────────────────────────────────────────
            const Text("Today's Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(now),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '$dayCount / ${gym.capacity} Bookings',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated (Auto)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            _buildCrowdBadge(estimatedLevel),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Live Status (Manual)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            if (liveLevel != null) 
                              _buildCrowdBadge(liveLevel)
                            else
                              const Text('Not set', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.xl),

            // ─── Update Live Status ────────────────────────────────────────
            const Text('Update Live Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('This status will be visible to all users.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            
            _buildStatusOption(context, gym.id, 'notBusy', 'Not Busy (Low)', CrowdLevel.low, gym.currentLiveStatus),
            _buildStatusOption(context, gym.id, 'moderatelyBusy', 'Moderately Busy', CrowdLevel.moderate, gym.currentLiveStatus),
            _buildStatusOption(context, gym.id, 'busy', 'Busy', CrowdLevel.busy, gym.currentLiveStatus),
            _buildStatusOption(context, gym.id, 'veryBusy', 'Very Busy', CrowdLevel.veryBusy, gym.currentLiveStatus),
            
            const SizedBox(height: AppPadding.xl),

            // ─── Manage Settings ───────────────────────────────────────────
            const Text('Manage Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            
            // 1. Capacity Setting
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Daily Capacity', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_isEditingCapacity ? Icons.check : Icons.edit, color: AppColors.primary, size: 20),
                        onPressed: () async {
                          if (_isEditingCapacity) {
                            final newCapacity = int.tryParse(_capacityController.text);
                            if (newCapacity != null && newCapacity > 0) {
                              await context.read<CrowdStatusProvider>().updateCapacity(gym.id, newCapacity);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capacity updated')));
                            }
                          }
                          setState(() {
                            _isEditingCapacity = !_isEditingCapacity;
                          });
                        },
                      )
                    ],
                  ),
                  if (_isEditingCapacity)
                    TextField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Enter total daily capacity',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    )
                  else
                    Text('${gym.capacity} people', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            
            // 2. Block Dates Setting
            GestureDetector(
              onTap: () => _showBlockDateDialog(context, gym),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Block Dates', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('${gym.blockedDates.length} dates blocked', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(
    BuildContext context, 
    String gymId, 
    String statusKey, 
    String title, 
    CrowdLevel level,
    String? currentStatus,
  ) {
    final isSelected = currentStatus == statusKey;
    final color = _crowdLevelColor(level);
    
    return GestureDetector(
      onTap: () async {
        if (!isSelected) {
          final success = await context.read<CrowdStatusProvider>().updateLiveStatus(gymId, statusKey);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live status updated'), backgroundColor: AppColors.primary),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdBadge(CrowdLevel level) {
    final color = _crowdLevelColor(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            CrowdService.crowdLevelLabel(level),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Color _crowdLevelColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return const Color(0xFF4CAF50);
      case CrowdLevel.moderate:
        return const Color(0xFFFFCA28);
      case CrowdLevel.busy:
        return const Color(0xFFFF9800);
      case CrowdLevel.veryBusy:
        return const Color(0xFFF44336);
    }
  }

  void _showBlockDateDialog(BuildContext context, GymModel gym) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Block Dates', style: TextStyle(color: AppColors.textPrimary)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Users will not be able to book on these dates.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: AppColors.surface,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (picked != null) {
                          final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          if (ctx.mounted) {
                            await ctx.read<CrowdStatusProvider>().toggleBlockedDate(
                              gym.id,
                              dateStr,
                              gym.blockedDates,
                            );
                            setStateDialog(() {});
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Blocked Date'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (gym.blockedDates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No blocked dates.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: gym.blockedDates.length,
                          itemBuilder: (context, index) {
                            final date = gym.blockedDates[index];
                            return ListTile(
                              title: Text(date, style: const TextStyle(color: AppColors.textPrimary)),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: AppColors.error),
                                onPressed: () async {
                                  await ctx.read<CrowdStatusProvider>().toggleBlockedDate(
                                    gym.id,
                                    date,
                                    gym.blockedDates,
                                  );
                                  setStateDialog(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
