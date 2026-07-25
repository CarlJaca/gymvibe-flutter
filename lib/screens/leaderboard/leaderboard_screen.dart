import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/gym_model.dart';
import '../../models/leaderboard_model.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/auth_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  final GymModel gym;

  const LeaderboardScreen({super.key, required this.gym});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().loadRecords(widget.gym.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.gym.name} Leaderboard'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Column(
            children: [
              // ── Category Tabs ──────────────────────────────────────
              _buildCategoryTabs(provider),
              const SizedBox(height: 16),

              // ── Leaderboard Content ────────────────────────────────
              Expanded(
                child: provider.selectedCategory == null
                    ? _buildAllCategoriesView(provider)
                    : provider.leaderboard.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.md),
                            children: [
                              // Podium
                              if (provider.podium.isNotEmpty) ...[
                                _buildPodium(provider.podium),
                                const SizedBox(height: 24),
                              ],

                              // Remaining entries
                              if (provider.remainingEntries.isNotEmpty) ...[
                                const Text(
                                  'Rankings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...provider.remainingEntries.asMap().entries.map(
                                      (entry) => _buildRankingTile(
                                          entry.value, entry.key + 4),
                                    ),
                              ],

                              // User's pending submissions
                              _buildUserPendingSection(provider),

                              const SizedBox(height: 100),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitPRSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Submit PR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─── Category Tabs ──────────────────────────────────────────────────────────
  Widget _buildCategoryTabs(LeaderboardProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
        children: [
          _buildTabItem(provider, null, 'Overview', Icons.list_alt_rounded),
          ...LeaderboardCategory.values.map((cat) =>
              _buildTabItem(provider, cat, cat.displayName, cat.icon)),
        ],
      ),
    );
  }

  Widget _buildTabItem(LeaderboardProvider provider,
      LeaderboardCategory? category, String label, IconData icon) {
    final isSelected = provider.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setCategory(category),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Overview State ─────────────────────────────────────────────────────────
  Widget _buildAllCategoriesView(LeaderboardProvider provider) {
    final allLeaderboards = provider.allLeaderboards;

    if (provider.records.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      children: [
        ...LeaderboardCategory.values.map((category) {
          final top3 = allLeaderboards[category] ?? [];
          if (top3.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(category.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${category.displayName} Champions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPodium(top3),
              ],
            ),
          );
        }),
        _buildUserPendingSection(provider),
        const SizedBox(height: 100),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to submit a personal record!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Podium ─────────────────────────────────────────────────────────────────
  Widget _buildPodium(List<PersonalRecord> top3) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (top3.length > 1)
            _buildPodiumItem(top3[1], 2, 140)
          else
            const SizedBox(width: 100),
          const SizedBox(width: 8),
          // 1st place
          _buildPodiumItem(top3[0], 1, 180),
          const SizedBox(width: 8),
          // 3rd place
          if (top3.length > 2)
            _buildPodiumItem(top3[2], 3, 110)
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(PersonalRecord record, int rank, double height) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Medal
          Text(medals[rank - 1], style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          // Avatar
          CircleAvatar(
            radius: rank == 1 ? 28 : 22,
            backgroundColor: colors[rank - 1].withValues(alpha: 0.3),
            child: CircleAvatar(
              radius: rank == 1 ? 25 : 19,
              backgroundImage: record.userAvatarUrl.isNotEmpty
                  ? NetworkImage(record.userAvatarUrl)
                  : null,
              backgroundColor: AppColors.surfaceElevated,
              child: record.userAvatarUrl.isEmpty
                  ? Text(
                      record.userName.isNotEmpty ? record.userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: rank == 1 ? 20 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            record.userName.split(' ').first,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Weight
          Text(
            '${record.weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              color: colors[rank - 1],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Podium block
          Container(
            height: height - 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[rank - 1].withValues(alpha: 0.4),
                  colors[rank - 1].withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: colors[rank - 1].withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: colors[rank - 1],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ranking Tile ───────────────────────────────────────────────────────────
  Widget _buildRankingTile(PersonalRecord record, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: record.userAvatarUrl.isNotEmpty
                ? NetworkImage(record.userAvatarUrl)
                : null,
            backgroundColor: AppColors.surface,
            child: record.userAvatarUrl.isEmpty
                ? Text(
                    record.userName.isNotEmpty ? record.userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.userName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.date,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Weight
          Text(
            '${record.weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── User Pending Section ───────────────────────────────────────────────────
  Widget _buildUserPendingSection(LeaderboardProvider provider) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) return const SizedBox.shrink();

    final userRecords = provider.getUserRecords(auth.currentUser!.id);
    final pending = userRecords.where((r) => r.status == RecordStatus.pending).toList();

    if (pending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Your Pending Submissions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...pending.map((record) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(record.category.icon, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.category.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${record.weight.toStringAsFixed(1)} kg • ${record.date}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⏳ ', style: TextStyle(fontSize: 12)),
                        Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ─── Submit PR Bottom Sheet ─────────────────────────────────────────────────
  void _showSubmitPRSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a personal record.')),
      );
      return;
    }

    LeaderboardCategory selectedCategory = LeaderboardCategory.deadlift;
    final weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: AppPadding.lg,
              right: AppPadding.lg,
              top: AppPadding.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppPadding.lg,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Submit Personal Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category selector
                const Text(
                  'Exercise Category',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeaderboardCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 16,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              cat.displayName,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Weight input
                const Text(
                  'Weight (kg)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'e.g. 100.0',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: 'kg',
                    suffixStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your record will be reviewed by the gym staff before appearing on the leaderboard.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final weight = double.tryParse(weightController.text);
                      if (weight == null || weight <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid weight.')),
                        );
                        return;
                      }

                      final user = auth.currentUser!;
                      try {
                        await context.read<LeaderboardProvider>().submitRecord(
                              gymId: widget.gym.id,
                              userId: user.id,
                              userName: user.name,
                              userAvatarUrl: user.avatarUrl,
                              category: selectedCategory,
                              weight: weight,
                            );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PR submitted! Awaiting verification.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to submit record. Try again.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'Submit for Verification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
