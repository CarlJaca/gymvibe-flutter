import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../models/user_model.dart';
import 'super_admin_user_details_sheet.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<SuperAdminProvider>().loadUsers(
      searchQuery: query.isNotEmpty ? query : null,
      roleFilter: _roleFilter,
    );
  }

  void _setRoleFilter(String? role) {
    setState(() => _roleFilter = role);
    context.read<SuperAdminProvider>().loadUsers(
      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      roleFilter: role,
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
          // ── Title ────────────────────────────────────────────
          Text('Users', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),

          // ── Search ───────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
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

          // ── Filter chips ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${provider.totalUserCount})',
                  isSelected: _roleFilter == null,
                  onTap: () => _setRoleFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Gym Users (${provider.seekerCount})',
                  isSelected: _roleFilter == 'gym_seeker',
                  onTap: () => _setRoleFilter('gym_seeker'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Gym Owners (${provider.ownerCount})',
                  isSelected: _roleFilter == 'gym_owner',
                  onTap: () => _setRoleFilter('gym_owner'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── User list ────────────────────────────────────────
          Expanded(
            child: _buildContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SuperAdminProvider provider) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.errorMessage != null && provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadUsers(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.loadUsers(roleFilter: _roleFilter),
      child: ListView.separated(
        itemCount: provider.users.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final user = provider.users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceElevated,
        backgroundImage: NetworkImage(user.avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: user.avatarUrl.isEmpty
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.textPrimary),
              )
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          if (user.createdAt != null)
            Text(
              'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(user.accountStatus),
          const SizedBox(width: 6),
          _buildRoleChip(user.role),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SuperAdminUserDetailsSheet(user: user),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
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
      case 'active':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.accentOrange;
        break;
      case 'suspended':
        color = AppColors.error;
        break;
      case 'deactivated':
        color = AppColors.textMuted;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    String label;
    switch (role) {
      case 'gym_seeker':
        color = const Color(0xFF4FC3F7);
        label = 'Gym User';
        break;
      case 'gym_owner':
        color = const Color(0xFFBA68C8);
        label = 'Gym Owner';
        break;
      case 'super_admin':
        color = AppColors.primary;
        label = 'Admin';
        break;
      default:
        color = AppColors.textSecondary;
        label = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
