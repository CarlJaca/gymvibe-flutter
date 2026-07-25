import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/gym_model.dart';
import '../../models/user_model.dart';

class SuperAdminGymsScreen extends StatefulWidget {
  const SuperAdminGymsScreen({super.key});

  @override
  State<SuperAdminGymsScreen> createState() => _SuperAdminGymsScreenState();
}

class _SuperAdminGymsScreenState extends State<SuperAdminGymsScreen> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadGyms();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<SuperAdminProvider>().loadGyms(
      searchQuery: query.isNotEmpty ? query : null,
      statusFilter: _statusFilter,
    );
  }

  void _setStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<SuperAdminProvider>().loadGyms(
      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      statusFilter: status,
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
          Text('Gyms', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by gym name or address',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(label: 'All', isSelected: _statusFilter == null, onTap: () => _setStatusFilter(null)),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Active', isSelected: _statusFilter == 'active', onTap: () => _setStatusFilter('active')),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Suspended', isSelected: _statusFilter == 'suspended', onTap: () => _setStatusFilter('suspended')),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'Flagged', isSelected: _statusFilter == 'flagged', onTap: () => _setStatusFilter('flagged')),
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
    if (provider.isLoading && provider.gyms.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.gyms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No gyms found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Approved gyms will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.loadGyms(statusFilter: _statusFilter),
      child: ListView.separated(
        itemCount: provider.gyms.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final gym = provider.gyms[index];
          return FutureBuilder<UserModel?>(
            future: provider.getGymOwner(gym.ownerId),
            builder: (context, snapshot) {
              return _buildGymTile(gym, snapshot.data, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildGymTile(GymModel gym, UserModel? owner, SuperAdminProvider provider) {
    final authProvider = context.read<AuthProvider>();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          image: DecorationImage(
            image: NetworkImage(gym.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(gym.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gym.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (owner != null)
            Text('Owner: ${owner.name} (${owner.email})', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(gym.status),
          PopupMenuButton<String>(
            color: AppColors.surfaceElevated,
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (val) => _handleAction(val, gym, authProvider),
            itemBuilder: (context) => [
              if (gym.status != 'suspended')
                const PopupMenuItem(value: 'suspend', child: Text('Suspend Gym')),
              if (gym.status == 'suspended')
                const PopupMenuItem(value: 'reactivate', child: Text('Reactivate Gym')),
              if (gym.status != 'flagged' && gym.status != 'suspended')
                const PopupMenuItem(value: 'flag', child: Text('Flag for Review')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
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
    Color color;
    switch (status) {
      case 'active': color = AppColors.success; break;
      case 'suspended': color = AppColors.error; break;
      case 'flagged': color = AppColors.accentOrange; break;
      case 'pending': color = Colors.orange; break;
      case 'rejected': color = AppColors.error; break;
      default: color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _handleAction(String action, GymModel gym, AuthProvider authProvider) {
    if (action == 'reactivate') {
      context.read<SuperAdminProvider>().reactivateGym(
        gymId: gym.id,
        adminId: authProvider.currentUser!.id,
        adminName: authProvider.userName,
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(action == 'suspend' ? 'Suspend Gym' : 'Flag Gym'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Reason to ${action == 'suspend' ? 'suspend' : 'flag'} (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              if (action == 'suspend') {
                context.read<SuperAdminProvider>().suspendGym(
                  gymId: gym.id,
                  reason: reasonCtrl.text.trim(),
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              } else {
                context.read<SuperAdminProvider>().flagGym(
                  gymId: gym.id,
                  reason: reasonCtrl.text.trim(),
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: action == 'suspend' ? AppColors.error : AppColors.accentOrange),
            child: Text(action == 'suspend' ? 'Suspend' : 'Flag'),
          ),
        ],
      ),
    );
  }
}
