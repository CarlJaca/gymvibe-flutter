import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/booking_model.dart';
import '../../providers/bookings_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BookingsProvider>().cancelBooking(bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Bookings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ─── Tabs ────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),

            // ─── Tab Views ───────────────────────────────────────
            Expanded(
              child: Consumer<BookingsProvider>(
                builder: (context, provider, _) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(provider.upcomingBookings, BookingTab.upcoming),
                      _buildBookingsList(provider.completedBookings, BookingTab.completed),
                      _buildBookingsList(provider.cancelledBookings, BookingTab.cancelled),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, BookingTab tab) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab == BookingTab.upcoming
                  ? Icons.event_available_rounded
                  : tab == BookingTab.completed
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              tab == BookingTab.upcoming
                  ? 'No upcoming bookings.'
                  : tab == BookingTab.completed
                      ? 'No completed bookings.'
                      : 'No cancelled bookings.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: bookings.length + 1, // +1 for the info notice at the bottom
      itemBuilder: (context, index) {
        if (index == bookings.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                SizedBox(width: 6),
                Text(
                  'All bookings are for one day only.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }
        final booking = bookings[index];
        return _buildBookingCard(booking, tab);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking, BookingTab tab) {
    final statusColor = tab == BookingTab.upcoming
        ? AppColors.primary
        : tab == BookingTab.completed
            ? AppColors.textSecondary
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Row ────────────────────────────────────
          Row(
            children: [
              // Gym image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: booking.gymImageUrl.isNotEmpty
                    ? Image.network(
                        booking.gymImageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.fitness_center_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 24),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.gymName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatBookingDate(booking.bookingDate),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // ─── Details ───────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                booking.timeSlotDisplay,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                booking.price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          if (booking.refNo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.tag_rounded, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Ref. No.  ${booking.refNo}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],

          // ─── Cancel Button (upcoming only) ─────────────────
          if (tab == BookingTab.upcoming) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(booking.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBookingDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

enum BookingTab { upcoming, completed, cancelled }
