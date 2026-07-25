import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';

class SuperAdminBookingsScreen extends StatefulWidget {
  const SuperAdminBookingsScreen({super.key});

  @override
  State<SuperAdminBookingsScreen> createState() => _SuperAdminBookingsScreenState();
}

class _SuperAdminBookingsScreenState extends State<SuperAdminBookingsScreen> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  String? _typeFilter;
  DateTime? _dateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadBookings();
    });
  }

  void _onSearch(String query) {
    context.read<SuperAdminProvider>().loadBookings(
      searchQuery: query.isNotEmpty ? query : null,
      statusFilter: _statusFilter,
    );
  }

  void _setStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    _reloadBookings();
  }

  void _setTypeFilter(String? type) {
    setState(() => _typeFilter = type);
    _reloadBookings();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _dateFilter = date);
      _reloadBookings();
    }
  }

  void _clearDateFilter() {
    setState(() => _dateFilter = null);
    _reloadBookings();
  }

  void _reloadBookings() {
    // In a real app, date and type filters would be passed to the provider
    // For now, we'll pass status and search, and handle extra filtering in memory or backend
    context.read<SuperAdminProvider>().loadBookings(
      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      statusFilter: _statusFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search by booking ID, user name, or gym name',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Status: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                _buildFilterChip('All', _statusFilter == null, () => _setStatusFilter(null)),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmed', _statusFilter == 'Confirmed', () => _setStatusFilter('Confirmed')),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', _statusFilter == 'Completed', () => _setStatusFilter('Completed')),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', _statusFilter == 'Cancelled', () => _setStatusFilter('Cancelled')),
                const SizedBox(width: 16),
                const Text('Type: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                _buildFilterChip('All', _typeFilter == null, () => _setTypeFilter(null)),
                const SizedBox(width: 8),
                _buildFilterChip('Class', _typeFilter == 'Class', () => _setTypeFilter('Class')),
                const SizedBox(width: 8),
                _buildFilterChip('Session', _typeFilter == 'Session', () => _setTypeFilter('Session')),
                const SizedBox(width: 16),
                if (_dateFilter != null) ...[
                  Chip(
                    label: Text('${_dateFilter!.year}-${_dateFilter!.month}-${_dateFilter!.day}', style: const TextStyle(fontSize: 12)),
                    onDeleted: _clearDateFilter,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    deleteIconColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _buildContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SuperAdminProvider provider) {
    if (provider.isLoading && provider.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No bookings found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('When users book gym sessions, they will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: provider.bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final booking = provider.bookings[index];
        return _buildBookingTile(booking);
      },
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> booking) {
    final authProvider = context.read<AuthProvider>();
    final isFlagged = booking['flagged'] == true;

    return InkWell(
      onTap: () => _viewBookingDetails(context, booking, isFlagged),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(booking['gymName'] ?? 'Unknown Gym', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${booking['userName'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('Date: ${booking['dateStr']} at ${booking['time']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text('ID: ${booking['id']}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            if (isFlagged)
              const Text('FLAGGED', style: TextStyle(fontSize: 10, color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(booking['status'] ?? ''),
            if (!isFlagged)
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppColors.textSecondary, size: 20),
                onPressed: () => _flagBooking(booking['id'], authProvider),
              ),
          ],
        ),
      ),
    );
  }

  void _viewBookingDetails(BuildContext context, Map<String, dynamic> booking, bool isFlagged) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', booking['id']),
            _detailRow('Gym', booking['gymName'] ?? 'Unknown'),
            _detailRow('User', booking['userName'] ?? 'Unknown'),
            _detailRow('Status', booking['status'] ?? 'Unknown'),
            _detailRow('Date', '${booking['dateStr']} at ${booking['time']}'),
            if (booking['notes'] != null && booking['notes'].toString().isNotEmpty)
              _detailRow('Notes', booking['notes']),
            if (isFlagged) ...[
              const SizedBox(height: 8),
              const Text('⚠️ This booking has been flagged.', style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.textSecondary;
    if (status == 'Confirmed') color = AppColors.primary;
    if (status == 'Completed') color = AppColors.success;
    if (status == 'Cancelled') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _flagBooking(String id, AuthProvider authProvider) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Flag Booking'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(hintText: 'Reason for flagging...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<SuperAdminProvider>().flagBooking(
                bookingId: id,
                notes: noteCtrl.text,
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}
