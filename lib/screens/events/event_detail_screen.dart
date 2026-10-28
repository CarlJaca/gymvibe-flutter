import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final eventsProv = Provider.of<EventsProvider>(context);
    final isRegistered = eventsProv.myRegisteredEvents.any((e) => e['id'] == event['id']);
    
    final int slots = (event['maxSlots'] as num?)?.toInt() ?? 50;
    final int registered = (event['registeredCount'] as num?)?.toInt() ?? 0;
    final bool isFull = registered >= slots;
    
    // Safety check for whatToBring
    final List<String> whatToBring = event['whatToBring'] != null 
        ? List<String>.from(event['whatToBring']) 
        : [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero Banner ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  eventsProv.markInterested(event['id']);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Interested!')));
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing event...')));
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event['image'],
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.backgroundDark.withValues(alpha: 0.8),
                          AppColors.backgroundDark,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          event['category'] ?? 'General',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.lg),

                  // Date, Time & Venue
                  _buildIconRow(Icons.calendar_month_rounded, '${event['date']}'),
                  const SizedBox(height: 12),
                  _buildIconRow(Icons.access_time_rounded, '${event['time']}'),
                  const SizedBox(height: 12),
                  _buildIconRow(Icons.location_on_rounded, '${event['location']}\n${event['address']}', isMultiline: true),
                  const SizedBox(height: 12),
                  _buildIconRow(Icons.directions_run_rounded, event['distance'] ?? 'Unknown distance'),
                  const SizedBox(height: AppPadding.xl),

                  // Event Description
                  const Text(
                    'About This Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['description'] ?? 'No description provided.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: AppPadding.xl),

                  // Grid Details
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildGridItem('Instructor', event['instructor'] ?? 'TBA'),
                      _buildGridItem('Difficulty', event['difficulty'] ?? 'All Levels'),
                      _buildGridItem('Duration', event['duration'] ?? 'Unknown'),
                      _buildGridItem('Max Slots', '$slots'),
                    ],
                  ),
                  const SizedBox(height: AppPadding.xl),

                  // What to Bring
                  if (whatToBring.isNotEmpty) ...[
                    const Text(
                      'What to Bring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...whatToBring.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(item, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                    )),
                    const SizedBox(height: AppPadding.xl),
                  ],

                  // Registration Progress
                  const Text(
                    'Registration Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$registered / $slots Joined',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isFull ? 'Sold Out' : '${slots - registered} Spots Left!',
                              style: TextStyle(
                                color: isFull ? AppColors.error : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: registered / slots,
                          backgroundColor: AppColors.backgroundDark,
                          valueColor: AlwaysStoppedAnimation<Color>(isFull ? AppColors.error : AppColors.primary),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (isFull || isRegistered) ? null : () {
                Navigator.pushNamed(context, '/event-registration', arguments: event);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (isFull || isRegistered) ? AppColors.surface : AppColors.primary,
                foregroundColor: (isFull || isRegistered) ? AppColors.textMuted : AppColors.backgroundDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
              child: Text(
                isRegistered ? 'Registered' : (isFull ? 'Registration Full' : 'Register Now'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconRow(IconData icon, String text, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
