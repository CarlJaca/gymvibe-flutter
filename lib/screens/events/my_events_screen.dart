import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
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
                      'My Events',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Tabs ───────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.divider,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Registered'),
                Tab(text: 'Past'),
              ],
            ),

            // ── Tab Views ──────────────────────────────────────────
            Expanded(
              child: Consumer<EventsProvider>(
                builder: (context, provider, _) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUpcomingView(provider.upcomingEvents),
                      _buildRegisteredView(provider.myRegisteredEvents),
                      _buildPastView(provider.pastEvents),
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

  Widget _buildUpcomingView(List<Map<String, dynamic>> events) {
    // Show top 3 upcoming events just as recommendations or reminders
    return ListView(
      padding: const EdgeInsets.all(AppPadding.md),
      children: [
        // Reminder Card
        if (events.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppPadding.md),
            margin: const EdgeInsets.only(bottom: AppPadding.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upcoming Reminder', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${events[0]['title']} is in 2 days!', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/event-details', arguments: events[0]),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                  child: const Text('Details', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
          ),
        
        const Text('Explore More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...events.map((e) => _buildEventCard(e, status: 'Upcoming')),
      ],
    );
  }

  Widget _buildRegisteredView(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No registered events yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index], status: 'Registered', isRegistered: true);
      },
    );
  }

  Widget _buildPastView(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No past events', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index], status: 'Completed', isPast: true);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, {required String status, bool isRegistered = false, bool isPast = false}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-details', arguments: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppPadding.md),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Date Box
            Builder(
              builder: (context) {
                final dateStr = event['date'] ?? 'TBA';
                final dateParts = dateStr.split(' ');
                String dayStr = '-';
                String monthStr = 'TBA';
                
                if (dateParts.length >= 2) {
                  // Format: 'May 25, 2025'
                  monthStr = dateParts[0];
                  dayStr = dateParts[1].replaceAll(',', '');
                } else if (dateParts.length == 1 && dateParts[0].contains('/')) {
                  // Format: '5/25/2025'
                  final parts = dateParts[0].split('/');
                  if (parts.length >= 2) {
                    final month = int.tryParse(parts[0]) ?? 1;
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    monthStr = (month >= 1 && month <= 12) ? months[month - 1] : '';
                    dayStr = parts[1];
                  }
                }

                return Container(
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPast ? AppColors.surfaceElevated : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayStr,
                        style: TextStyle(
                          color: isPast ? AppColors.textMuted : AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        monthStr,
                        style: TextStyle(
                          color: isPast ? AppColors.textMuted : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'],
                          style: TextStyle(
                            color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isRegistered ? AppColors.success.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isRegistered ? AppColors.success : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        event['time'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'],
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
