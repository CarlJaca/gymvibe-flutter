import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/promotions_provider.dart';
import '../../providers/gym_provider.dart';

class OwnerCreatePromotionScreen extends StatefulWidget {
  const OwnerCreatePromotionScreen({super.key});

  @override
  State<OwnerCreatePromotionScreen> createState() =>
      _OwnerCreatePromotionScreenState();
}

class _OwnerCreatePromotionScreenState
    extends State<OwnerCreatePromotionScreen> {
  final _titleCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _discountType = 'Percentage (%)';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _discountTypes = [
    'Percentage (%)',
    'Fixed Amount',
    'Membership Offer',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _valueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: isStart ? 0 : 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() => isStart ? _startDate = d : _endDate = d);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.sm, vertical: AppPadding.xs),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Promotion',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Text(
                'Build a new promotion for your gym',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Form ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppPadding.sm),

                    // ── Banner Upload ──────────────────────────────
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: AppColors.primary,
                                  size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text('Add Promotion Image',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Title ─────────────────────────────────────
                    _label('Promotion Title'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g., 20% Off on All Memberships',
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Discount Type ─────────────────────────────
                    _label('Discount Type'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _discountType,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary),
                          items: _discountTypes
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _discountType = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Discount Value ────────────────────────────
                    _label('Discount Value'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: _discountType == 'Percentage (%)'
                            ? 'e.g., 20'
                            : 'e.g., 500',
                        prefixText: _discountType == 'Percentage (%)'
                            ? null
                            : '₱ ',
                        suffixText: _discountType == 'Percentage (%)'
                            ? '%'
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Dates Row ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Start Date'),
                              const SizedBox(height: 8),
                              _dateTile(_startDate, () => _pickDate(true)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('End Date'),
                              const SizedBox(height: 8),
                              _dateTile(_endDate, () => _pickDate(false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Description ───────────────────────────────
                    _label('Description'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Enter promotion details'),
                    ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ),

            // ── CTA ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final notifProv = context.read<NotificationProvider>();
                    notifProv.addNotification(NotificationItem(
                      icon: Icons.local_offer_rounded,
                      title: 'New Promotion: ${_titleCtrl.text.isEmpty ? 'Special Offer' : _titleCtrl.text}',
                      subtitle: _descCtrl.text.isEmpty ? 'Don\'t miss our latest promotion!' : _descCtrl.text,
                      time: 'Just now',
                    ));

                    final promoProv = context.read<PromotionsProvider>();
                    final gymProv = context.read<GymProvider>();
                    promoProv.addPromotion({
                      'gymId': gymProv.ownerGym.id,
                      'title': _titleCtrl.text.isEmpty ? 'Special Offer' : _titleCtrl.text,
                      'dates': _startDate != null && _endDate != null
                          ? '${_startDate!.month}/${_startDate!.day} - ${_endDate!.month}/${_endDate!.day}'
                          : 'TBA',
                      'type': _discountType,
                      'value': double.tryParse(_valueCtrl.text) ?? 0.0,
                      'reach': 0,
                      'redemptions': 0,
                      'color': AppColors.primary.toARGB32(), // Fix: Must save as integer to Firebase
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Promotion published!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Publish Promotion'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _dateTile(DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null
                    ? 'Select date'
                    : '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  color: date == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
