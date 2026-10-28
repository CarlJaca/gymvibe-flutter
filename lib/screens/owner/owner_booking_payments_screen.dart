import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/booking_model.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/gym_provider.dart';

/// Owner view: lists bookings for the owner's gym with their payment proof,
/// so the owner can open the screenshot full size and mark it Verified/Rejected.
class OwnerBookingPaymentsScreen extends StatelessWidget {
  const OwnerBookingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gymId = context.read<GymProvider>().ownerGym.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Booking Payments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('gymId', isEqualTo: gymId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load bookings.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final bookings = snapshot.data!.docs
              .map((d) => BookingModel.fromJson(d.data(), d.id))
              .toList()
            ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppPadding.md),
            itemCount: bookings.length,
            itemBuilder: (context, i) => _BookingPaymentCard(booking: bookings[i]),
          );
        },
      ),
    );
  }
}

class _BookingPaymentCard extends StatefulWidget {
  final BookingModel booking;
  const _BookingPaymentCard({required this.booking});

  @override
  State<_BookingPaymentCard> createState() => _BookingPaymentCardState();
}

class _BookingPaymentCardState extends State<_BookingPaymentCard> {
  bool _updating = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
        return AppColors.primary;
      case 'Rejected':
        return AppColors.error;
      default:
        return const Color(0xFFFFCA28);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    final ok = await context
        .read<BookingsProvider>()
        .updatePaymentStatus(widget.booking.id, status);
    if (!mounted) return;
    setState(() => _updating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Payment marked as $status'
            : 'Failed to update payment status.'),
        backgroundColor: ok ? AppColors.primary : AppColors.error,
      ),
    );
  }

  void _openFullSize(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Could not load image',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final color = _statusColor(b.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.refNo.isNotEmpty ? b.refNo : b.id,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  b.paymentStatus,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${b.bookingDate}  •  ${b.timeSlotDisplay}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('Booking status: ${b.status}  •  ${b.price}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (b.paymentProofUrl.isEmpty)
            const Text('No payment proof uploaded.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted))
          else ...[
            GestureDetector(
              onTap: () => _openFullSize(b.paymentProofUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Image.network(
                      b.paymentProofUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(Icons.zoom_out_map_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_updating)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: b.paymentStatus == 'Rejected'
                          ? null
                          : () => _setStatus('Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: b.paymentStatus == 'Verified'
                          ? null
                          : () => _setStatus('Verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

