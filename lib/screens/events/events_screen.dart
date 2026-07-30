import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/events_provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final List<String> _categories = ['All', 'Workout', 'Dance', 'Strength', 'Wellness'];
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Consumer<EventsProvider>(
          builder: (context, provider, child) {
            // Filter events
            var upcomingEvents = provider.upcomingEvents;
            if (_selectedCategory != 'All') {
              upcomingEvents = upcomingEvents
                  .where((e) => e['category'] == _selectedCategory)
                  .toList();
            }

            final featuredEvents = provider.featuredEvents;

            return CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppPadding.md, AppPadding.md, AppPadding.md, AppPadding.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fitness Events',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover events near you',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search Bar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          icon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // ── Categories ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppPadding.md)),

                // ── Featured Events ────────────────────────────────────
                if (featuredEvents.isNotEmpty && _selectedCategory == 'All') ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                        itemCount: featuredEvents.length,
                        itemBuilder: (context, index) {
                          final event = featuredEvents[index];
                          return _buildFeaturedEventCard(context, event, provider);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppPadding.lg)),
                ],

                // ── Upcoming Events List ────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: 8),
                    child: Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                if (upcomingEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          'No events found for $_selectedCategory',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildEventCard(context, upcomingEvents[index], provider);
                        },
                        childCount: upcomingEvents.length,
                      ),
                    ),
                  ),
                  
                const SliverToBoxAdapter(child: SizedBox(height: AppSizes.bottomNavHeight + AppPadding.xl)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.pushNamed(context, '/my-events'), // Added quick access to My Events as requested
        backgroundColor: AppColors.surfaceElevated,
        child: const Icon(Icons.event_available_rounded, color: AppColors.primary),
      ),
    );
  }

  Widget _buildFeaturedEventCard(BuildContext context, Map<String, dynamic> event, EventsProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-details', arguments: event),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          image: DecorationImage(
            image: NetworkImage(event['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text('FEATURED', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event['title'],
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${event['date']} • ${event['time']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => provider.toggleEventSave(event['id']),
                    icon: Icon(
                      event['isSaved'] ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: event['isSaved'] ? AppColors.primary : Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event, EventsProvider provider) {
    final int slots = (event['maxSlots'] as num?)?.toInt() ?? 50;
    final int registered = (event['registeredCount'] as num?)?.toInt() ?? 0;
    final bool isFull = registered >= slots;
    final bool isRegistered = provider.myRegisteredEvents.any((e) => e['id'] == event['id']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-details', arguments: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppPadding.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  child: Image.network(
                    event['image'],
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      event['category'],
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => provider.toggleEventSave(event['id']),
                    icon: Icon(
                      event['isSaved'] ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: event['isSaved'] ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'],
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        event['distance'],
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${event['date']} at ${event['time']}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        event['location'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '$registered / $slots Joined',
                                style: TextStyle(
                                  color: isFull ? AppColors.error : AppColors.textPrimary, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFull ? 'Sold Out' : '${slots - registered} slots remaining',
                            style: TextStyle(
                              color: isFull ? AppColors.error : AppColors.primary, 
                              fontSize: 11
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: (isFull || isRegistered) ? null : () {
                          Navigator.pushNamed(context, '/event-details', arguments: event);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isFull || isRegistered) ? AppColors.surfaceElevated : AppColors.primary,
                          foregroundColor: (isFull || isRegistered) ? AppColors.textMuted : AppColors.backgroundDark,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        ),
                        child: Text(isRegistered ? 'Registered' : (isFull ? 'Full' : 'Register')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
