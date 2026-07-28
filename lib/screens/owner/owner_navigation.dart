import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/promotions_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'owner_dashboard_screen.dart';
import 'owner_events_management_screen.dart';
import 'owner_promotions_management_screen.dart';
import 'owner_analytics_screen.dart';
import 'owner_settings_screen.dart';

class OwnerNavigation extends StatefulWidget {
  const OwnerNavigation({super.key});

  @override
  State<OwnerNavigation> createState() => _OwnerNavigationState();
}

class _OwnerNavigationState extends State<OwnerNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    OwnerDashboardScreen(),
    OwnerEventsManagementScreen(),
    OwnerPromotionsManagementScreen(),
    OwnerAnalyticsScreen(),
    OwnerSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('OwnerNavigation.initState: starting owner data loads');
    // Start Firestore listeners so owner screens have data to render.
    // These are no-ops if already listening (guarded inside each provider).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        debugPrint('OwnerNavigation: calling loadGyms');
        context.read<GymProvider>().loadGyms();
        debugPrint('OwnerNavigation: calling loadEvents');
        context.read<EventsProvider>().loadEvents();
        debugPrint('OwnerNavigation: calling loadPromotions');
        context.read<PromotionsProvider>().loadPromotions();
        
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser != null) {
          debugPrint('OwnerNavigation: calling loadNotifications');
          context.read<NotificationProvider>().loadNotifications(authProvider.currentUser!.id);
        }
      } catch (e, stack) {
        debugPrint('Error loading owner data: $e');
        debugPrint(stack.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_outlined),
                activeIcon: Icon(Icons.event_rounded),
                label: 'Events',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_outlined),
                activeIcon: Icon(Icons.local_offer_rounded),
                label: 'Promotions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
