import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_posting_model.dart';
import '../../providers/job_provider.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chip_widget.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().loadJobs();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<JobProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Opportunities'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppPadding.md, AppPadding.sm, AppPadding.md, 0),
              child: SearchBarWidget(
                hintText: 'Search job title or gym...',
                controller: _searchController,
                onChanged: (query) {
                  context.read<JobProvider>().setSearchQuery(query);
                },
                onClear: () {
                  context.read<JobProvider>().setSearchQuery('');
                },
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Filter chips ──────────────────────────────────────────
            SizedBox(
              height: 40,
              child: Consumer<JobProvider>(
                builder: (context, prov, _) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.md),
                    children: [
                      FilterChipWidget(
                        label: 'All',
                        isSelected: prov.categoryFilter == null &&
                            prov.employmentTypeFilter == null,
                        onTap: () => prov.clearFilters(),
                      ),
                      const SizedBox(width: 8),
                      ...['Full Time', 'Part Time', 'Contract', 'Internship']
                          .map((type) {
                        final value = type
                            .toLowerCase()
                            .replaceAll(' ', '_');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChipWidget(
                            label: type,
                            isSelected:
                                prov.employmentTypeFilter == value,
                            onTap: () => prov.setEmploymentTypeFilter(
                              prov.employmentTypeFilter == value
                                  ? null
                                  : value,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Sort row ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Consumer<JobProvider>(
                builder: (context, prov, _) {
                  return Row(
                    children: [
                      Text(
                        '${prov.jobs.length} jobs found',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      _buildSortDropdown(prov),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppPadding.xs),

            // ── Job list ──────────────────────────────────────────────
            Expanded(
              child: Consumer<JobProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading && prov.jobs.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  if (prov.errorMessage != null && prov.jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(prov.errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => prov.loadJobs(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (prov.jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_off_outlined,
                              size: 64,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No job postings found',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Try adjusting your filters',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    onRefresh: () => prov.loadJobs(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.md),
                      itemCount:
                          prov.jobs.length + (prov.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= prov.jobs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2),
                            ),
                          );
                        }
                        return _buildJobCard(context, prov.jobs[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown(JobProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: prov.sortBy,
          isDense: true,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.textSecondary),
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          items: const [
            DropdownMenuItem(
                value: 'newest',
                child: Text('Newest',
                    style: TextStyle(color: AppColors.textPrimary))),
            DropdownMenuItem(
                value: 'deadline',
                child: Text('Nearest Deadline',
                    style: TextStyle(color: AppColors.textPrimary))),
            DropdownMenuItem(
                value: 'salary',
                child: Text('Highest Salary',
                    style: TextStyle(color: AppColors.textPrimary))),
          ],
          onChanged: (v) => prov.setSortBy(v!),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobPostingModel job) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(job: job),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: logo + title + bookmark
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gym logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: AppColors.surfaceElevated,
                    child: job.gymLogoUrl.isNotEmpty
                        ? Image.network(job.gymLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 22))
                        : const Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.gymName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<JobProvider>(
                  builder: (context, prov, _) {
                    final isSaved = prov.isJobSaved(job.jobId);
                    return GestureDetector(
                      onTap: () => prov.toggleSaveJob(job.jobId),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isSaved
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 22,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip(Icons.location_on_outlined, job.location),
                _infoChip(Icons.schedule_rounded,
                    employmentTypeLabel(job.employmentType)),
                _infoChip(Icons.payments_outlined, job.salaryDisplay),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom row: openings + deadline
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${job.numberOfOpenings} opening${job.numberOfOpenings > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (job.applicationDeadline != null) ...[
                  const Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${_formatDate(job.applicationDeadline!)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
