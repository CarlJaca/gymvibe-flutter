import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';

class EventRemindersScreen extends StatelessWidget {
  const EventRemindersScreen({super.key});

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
                      'Event Reminders',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Main Content ───────────────────────────────────────
            Expanded(
              child: Consumer<EventsProvider>(
                builder: (context, provider, _) {
                  final events = provider.upcomingEvents; // Typically we'd only show those we've registered/saved for reminders

                  if (events.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView(
                    padding: const EdgeInsets.all(AppPadding.md),
                    children: [
                      // Header Graphic
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: AppPadding.xl),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 48),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Never Miss an Event',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enable reminders and get notified\nbefore your events start.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: AppPadding.xl),
                          ],
                        ),
                      ),
                      
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppPadding.md),
                      
                      // List of reminder cards
                      ...events.map((e) => _buildReminderCard(context, e, provider)),
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

  Widget _buildReminderCard(BuildContext context, Map<String, dynamic> event, EventsProvider provider) {
    final bool hasReminder = event['hasReminder'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Event Info
          Padding(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    event['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'],
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${event['date']} • ${event['time']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event['location'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppColors.border, height: 1),
          
          // Reminder Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reminder', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                Switch(
                  value: hasReminder,
                  onChanged: (val) {
                    provider.toggleReminder(event['id']);
                  },
                  activeThumbColor: AppColors.backgroundDark,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceElevated,
                  inactiveThumbColor: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('No upcoming events to remind you of.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
