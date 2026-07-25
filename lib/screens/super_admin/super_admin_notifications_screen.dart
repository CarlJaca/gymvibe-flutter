import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';


class SuperAdminNotificationsScreen extends StatefulWidget {
  const SuperAdminNotificationsScreen({super.key});

  @override
  State<SuperAdminNotificationsScreen> createState() => _SuperAdminNotificationsScreenState();
}

class _SuperAdminNotificationsScreenState extends State<SuperAdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _audience = 'all';
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Send Announcement'),
              Tab(text: 'History'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendForm(context),
                _buildHistory(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendForm(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'New Maintenance Notice')),
            const SizedBox(height: 20),
            
            const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _msgCtrl, maxLines: 5, decoration: const InputDecoration(hintText: 'Type your message here...')),
            const SizedBox(height: 20),

            const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              dropdownColor: AppColors.surfaceElevated,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Users')),
                DropdownMenuItem(value: 'gym_seekers', child: Text('Gym Seekers Only')),
                DropdownMenuItem(value: 'gym_owners', child: Text('Gym Owners Only')),
              ],
              onChanged: (v) => setState(() => _audience = v!),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Radio<bool>(
                  value: false,
                  // ignore: deprecated_member_use
                  groupValue: _isScheduled,
                  activeColor: AppColors.primary,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _isScheduled = v!),
                ),
                const Text('Send Now'),
                const SizedBox(width: 24),
                Radio<bool>(
                  value: true,
                  // ignore: deprecated_member_use
                  groupValue: _isScheduled,
                  activeColor: AppColors.primary,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _isScheduled = v!),
                ),
                const Text('Schedule'),
              ],
            ),

            if (_isScheduled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_scheduledDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_scheduledDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _scheduledDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_scheduledTime == null ? 'Select Time' : _scheduledTime!.format(context)),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) setState(() => _scheduledTime = time);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSend,
                child: Text(_isScheduled ? 'Schedule Announcement' : 'Send Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(SuperAdminProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.notifications.isEmpty) {
      return const Center(child: Text('No announcements found', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final n = provider.notifications[index];
        final isSched = n.status == 'scheduled';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isSched ? AppColors.accentOrange : AppColors.success).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSched ? 'SCHEDULED' : 'SENT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSched ? AppColors.accentOrange : AppColors.success),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isSched ? 'For: ${DateFormat('MMM d, yyyy h:mm a').format(n.scheduledDate!)}'
                            : 'Sent: ${DateFormat('MMM d, yyyy h:mm a').format(n.sentDate!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(n.message, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Audience: ${n.targetAudience}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }

  void _handleSend() {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and message required')));
      return;
    }
    DateTime? schedDate;
    if (_isScheduled) {
      if (_scheduledDate == null || _scheduledTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select date and time for schedule')));
        return;
      }
      schedDate = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day, _scheduledTime!.hour, _scheduledTime!.minute);
      if (schedDate.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule time must be in the future')));
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    context.read<SuperAdminProvider>().sendNotification(
      title: _titleCtrl.text,
      message: _msgCtrl.text,
      targetAudience: _audience,
      scheduledDate: schedDate,
      senderId: authProvider.currentUser!.id,
      senderName: authProvider.userName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isScheduled ? 'Announcement scheduled' : 'Announcement sent')),
    );
    _titleCtrl.clear();
    _msgCtrl.clear();
    _tabController.animateTo(1); // switch to history
  }
}
