import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/gym_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/gym_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Gyms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Your favorite and saved gyms',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Fav Gyms', icon: Icon(Icons.favorite_rounded, size: 18)),
              Tab(text: 'Saved Gyms', icon: Icon(Icons.bookmark_rounded, size: 18)),
              Tab(text: 'Events', icon: Icon(Icons.event_rounded, size: 18)),
            ],
          ),
        ),
        body: Consumer2<GymProvider, EventsProvider>(
          builder: (context, gymProvider, eventsProvider, _) {
            if (gymProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final favoriteGyms = gymProvider.favoriteGyms;
            final savedGyms = gymProvider.savedGyms;
            final savedEvents = eventsProvider.savedEvents;

            return TabBarView(
              children: [
                _buildList(favoriteGyms, Icons.favorite_border_rounded, 'No favorite gyms', 'Tap the heart icon to save gyms here.', isEvent: false),
                _buildList(savedGyms, Icons.bookmark_border_rounded, 'No saved gyms', 'Tap the bookmark icon to save gyms here.', isEvent: false),
                _buildList(savedEvents, Icons.event_busy_rounded, 'No saved events', 'Tap the bookmark icon to save events here.', isEvent: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, IconData icon, String title, String subtitle, {bool isEvent = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppPadding.md, bottom: 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (isEvent) {
          final event = items[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppPadding.sm),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(event['image'], width: 60, height: 60, fit: BoxFit.cover),
              ),
              title: Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('${event['date']} • ${event['time']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.bookmark, color: AppColors.primary),
                onPressed: () => context.read<EventsProvider>().toggleEventSave(event['id']),
              ),
              onTap: () => Navigator.pushNamed(context, '/event-details', arguments: event),
            ),
          );
        }

        return GymCard(
          gym: items[index],
          onTap: () {
            context.read<GymProvider>().selectGym(items[index]);
            Navigator.pushNamed(context, AppRoutes.gymDetails, arguments: items[index]);
          },
        );
      },
    );
  }
}
