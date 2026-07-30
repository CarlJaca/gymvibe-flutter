import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';
import '../../core/routes/app_router.dart';

class OwnerEventsManagementScreen extends StatefulWidget {
  const OwnerEventsManagementScreen({super.key});

  @override
  State<OwnerEventsManagementScreen> createState() =>
      _OwnerEventsManagementScreenState();
}

class _OwnerEventsManagementScreenState
    extends State<OwnerEventsManagementScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: AppColors.backgroundDark, // added for dark mode theme
      body: SafeArea(
        child: Consumer2<EventsProvider, GymProvider>(
          builder: (context, eventsProv, gymProv, _) {
            if (eventsProv.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            
            final ownerGymId = gymProv.ownerGym.id;
            final activeEvents = eventsProv.activeEvents.where((e) => e['gymId'] == ownerGymId).toList();
            final upcomingEvents = eventsProv.upcomingEvents.where((e) => e['gymId'] == ownerGymId).toList();
            final inactiveEvents = eventsProv.inactiveEvents.where((e) => e['gymId'] == ownerGymId).toList();

            final activeCount = activeEvents.length;
            final upcomingCount = upcomingEvents.length;
            final inactiveCount = inactiveEvents.length;



            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md, vertical: AppPadding.sm),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Events',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Row(
                              children: [
                                Icon(Icons.shield_outlined, color: AppColors.primary, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Gym Owner Dashboard',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                
                // ── Tabs ────────────────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Active ($activeCount)'),
                    Tab(text: 'Upcoming ($upcomingCount)'),
                    Tab(text: 'Inactive ($inactiveCount)'),
                  ],
                ),
                const SizedBox(height: AppPadding.md),


                // ── Content ─────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventList(activeEvents),
                      _buildEventList(upcomingEvents),
                      _buildEventList(inactiveEvents),
                    ],
                  ),
                ),
                
                // Disclaimer Note
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'All event metrics are based on registered customer users only.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.ownerCreateEvent),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }



  Widget _buildEventList(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return _buildEmptyState(
          'No events here', 'Events will appear here once created.');
    }
    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: 4),
      itemCount: events.length,
      itemBuilder: (context, index) =>
          _buildEventCard(context, events[index]),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  event['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 160, color: AppColors.surfaceElevated),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Change Event Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('Active', style: TextStyle(color: Colors.white)),
                              trailing: event['status'] == 'Active' ? const Icon(Icons.check, color: AppColors.primary) : null,
                              onTap: () {
                                final newEvent = Map<String, dynamic>.from(event);
                                newEvent['status'] = 'Active';
                                context.read<EventsProvider>().updateEvent(event, newEvent);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status changed to Active')));
                              },
                            ),
                            ListTile(
                              title: const Text('Upcoming', style: TextStyle(color: Colors.white)),
                              trailing: event['status'] == 'Upcoming' ? const Icon(Icons.check, color: AppColors.primary) : null,
                              onTap: () {
                                final newEvent = Map<String, dynamic>.from(event);
                                newEvent['status'] = 'Upcoming';
                                context.read<EventsProvider>().updateEvent(event, newEvent);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status changed to Upcoming')));
                              },
                            ),
                            ListTile(
                              title: const Text('Inactive', style: TextStyle(color: Colors.white)),
                              trailing: event['status'] == 'Inactive' ? const Icon(Icons.check, color: AppColors.primary) : null,
                              onTap: () {
                                final newEvent = Map<String, dynamic>.from(event);
                                newEvent['status'] = 'Inactive';
                                context.read<EventsProvider>().updateEvent(event, newEvent);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status changed to Inactive')));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event['status'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  color: AppColors.surfaceElevated,
                  onSelected: (value) {
                    // Placeholder for additional actions
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'publish', child: Text('Publish Event', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'archive', child: Text('Archive Event', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'cancel', child: Text('Cancel Event', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
            ],
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today_rounded,
                    '${event['date']} • ${event['time']}'),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_rounded, event['location']),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _countChip(Icons.people_alt_rounded, '${event['registeredCount'] ?? 0} Going'),
                    const SizedBox(width: 16),
                    _countChip(Icons.favorite_border_rounded, '${event['interested'] ?? 0} Interested'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _actionBtn(context, Icons.edit_outlined, 'Edit', onPressed: () => _editEvent(context, event)),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.people_outline_rounded, 'Attendees', onPressed: () => Navigator.pushNamed(context, AppRoutes.ownerAttendanceTracking, arguments: event)),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.copy_rounded, 'Duplicate', onPressed: () => _duplicateEvent(event)),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.delete_outline_rounded, 'Delete',
                        color: AppColors.error, onPressed: () => _deleteEvent(event)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _countChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      {Color color = AppColors.textSecondary, required VoidCallback onPressed}) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: color), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  void _deleteEvent(Map<String, dynamic> event) {
    context.read<EventsProvider>().removeEvent(event);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted')),
    );
  }

  void _duplicateEvent(Map<String, dynamic> event) {
    context.read<EventsProvider>().duplicateEvent(event);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event duplicated')),
    );
  }



  void _editEvent(BuildContext context, Map<String, dynamic> event) {
    final titleCtrl = TextEditingController(text: event['title']);
    final dateCtrl = TextEditingController(text: event['date']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(labelText: 'Date'),
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
              final newEvent = Map<String, dynamic>.from(event);
              newEvent['title'] = titleCtrl.text;
              newEvent['date'] = dateCtrl.text;
              context.read<EventsProvider>().updateEvent(event, newEvent);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
