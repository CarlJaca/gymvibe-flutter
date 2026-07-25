import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/section_header.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadCommunityData();
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.sm, vertical: AppPadding.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.searchLanding),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<CommunityProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    onRefresh: () => provider.loadCommunityData(),
                    child: ListView(
                      padding: const EdgeInsets.all(AppPadding.md),
                      children: [
                        // ── All Communities Horizontal List ─────────────
                        SectionHeader(
                          title: AppStrings.allCommunities,
                          actionLabel: AppStrings.viewAll,
                          onAction: () {},
                        ),
                        const SizedBox(height: AppPadding.md),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.communities.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final comm = provider.communities[index];
                                    final isSelected = provider.selectedCommunity?.id == comm.id;
                                    return GestureDetector(
                                      onTap: () {
                                        provider.selectCommunity(isSelected ? null : comm);
                                      },
                                      child: SizedBox(
                                        width: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: isSelected
                                                    ? Border.all(color: AppColors.primary, width: 2)
                                                    : null,
                                              ),
                                              child: CircleAvatar(
                                                radius: 30,
                                                backgroundImage: NetworkImage(comm.imageUrl),
                                                backgroundColor: AppColors.surfaceElevated,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              comm.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                            },
                          ),
                        ),
                        const SizedBox(height: AppPadding.xl),

                        // ── Post Composer ───────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(AppPadding.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) => CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(auth.userAvatar),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _postController,
                                      onChanged: provider.updatePostText,
                                      decoration: const InputDecoration(
                                        hintText: AppStrings.writeYourPost,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      maxLines: null,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.image_outlined, size: 20),
                                    label: const Text('Add your post in', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                                  ),
                                  ElevatedButton(
                                    onPressed: provider.postText.trim().isEmpty
                                        ? null
                                        : () {
                                            final auth = context.read<AuthProvider>();
                                            provider.publishPost(
                                              userId: auth.currentUser?.id ?? '',
                                              userName: auth.userName,
                                              userAvatarUrl: auth.userAvatar,
                                              userLocation: auth.userLocation,
                                            );
                                            _postController.clear();
                                            FocusScope.of(context).unfocus();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                                    ),
                                    child: const Text('Publish Post', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppPadding.xl),

                        // ── Feed ─────────────────────────────────────────
                        ...provider.filteredPosts.map((post) => PostCard(post: post)),
                      ],
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
}
