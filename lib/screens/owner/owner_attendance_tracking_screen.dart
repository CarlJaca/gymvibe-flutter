import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';

class OwnerAttendanceTrackingScreen extends StatefulWidget {
  const OwnerAttendanceTrackingScreen({super.key});

  @override
  State<OwnerAttendanceTrackingScreen> createState() => _OwnerAttendanceTrackingScreenState();
}

class _OwnerAttendanceTrackingScreenState extends State<OwnerAttendanceTrackingScreen> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    // We expect the event object to be passed via arguments
    final event = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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
                      'Attendance (Staff View)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Event Summary ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.sm),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(event['image'], width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['title'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${event['date']} • ${event['time']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${event['registeredCount']} / ${event['maxSlots']} Registered', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search & Stats ─────────────────────────────────────
            Consumer<EventsProvider>(
              builder: (context, provider, child) {
                // Ensure we get the latest state of this event
                final currentEvent = provider.upcomingEvents.firstWhere(
                  (e) => e['id'] == event['id'], 
                  orElse: () => event
                );
                
                final List attendees = currentEvent['attendees'] ?? [];
                final int totalRegistered = attendees.length;
                final int attendedCount = attendees.where((a) => a['attended'] == true).length;
                
                // Filter attendees
                final filteredAttendees = attendees.where((a) {
                  return a['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                return Expanded(
                  child: Column(
                    children: [
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Registered', '$totalRegistered', AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard('Attended', '$attendedCount', AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search participant name...',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attendees List
                      Expanded(
                        child: filteredAttendees.isEmpty 
                          ? const Center(child: Text('No participants found.', style: TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                              itemCount: filteredAttendees.length,
                              itemBuilder: (context, index) {
                                final participant = filteredAttendees[index];
                                final bool hasAttended = participant['attended'] == true;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: hasAttended ? AppColors.success.withValues(alpha: 0.5) : AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(participant['avatar']),
                                        radius: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    participant['name'],
                                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: hasAttended ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                                  ),
                                                  child: Text(
                                                    hasAttended ? 'Attended' : 'Registered',
                                                    style: TextStyle(
                                                      color: hasAttended ? AppColors.success : AppColors.primary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ID: ${participant['memberId'] ?? 'N/A'} • ${participant['membershipType'] ?? 'N/A'}',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Registered: ${participant['registrationDate'] ?? 'N/A'}',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!hasAttended)
                                        OutlinedButton(
                                          onPressed: () {
                                            provider.markAttendance(event['id'], participant['id']);
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Text('${participant['name']} marked as attended.'),
                                              duration: const Duration(seconds: 1),
                                            ));
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                          ),
                                          child: const Text('Mark Attended', style: TextStyle(fontSize: 12)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
