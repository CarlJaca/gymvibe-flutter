import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/utils/secure_logger.dart';
import 'providers/auth_provider.dart';
import 'providers/gym_provider.dart';
import 'providers/community_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/events_provider.dart';
import 'providers/promotions_provider.dart';
import 'providers/bookings_provider.dart';
import 'providers/location_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/super_admin_provider.dart';
import 'providers/job_provider.dart';
import 'providers/job_application_provider.dart';
import 'providers/owner_job_provider.dart';
import 'models/gym_model.dart';

// User App
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/events/events_screen.dart'; // User requested 'Events'
import 'screens/events/event_detail_screen.dart';
import 'screens/events/my_events_screen.dart';
import 'screens/events/event_registration_screen.dart';
import 'screens/events/event_registration_success_screen.dart';
import 'screens/events/event_reminders_screen.dart';
import 'screens/promotions/promotions_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/gym_details/gym_details_screen.dart';
import 'screens/search/search_landing_screen.dart';
import 'screens/search/search_results_screen.dart';
import 'screens/search/filters_screen.dart';
import 'screens/home/customer_notifications_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/my_bookings_screen.dart';
import 'screens/membership/membership_screen.dart';
import 'screens/profile/my_reviews_screen.dart';
import 'screens/profile/membership_history_screen.dart';
import 'screens/jobs/jobs_screen.dart';
import 'screens/jobs/my_applications_screen.dart';
// Owner Portal
import 'screens/owner/owner_login_screen.dart';
import 'screens/owner/owner_navigation.dart';
import 'screens/owner/owner_register_screen.dart';
import 'screens/owner/owner_create_event_screen.dart';
import 'screens/owner/owner_create_promotion_screen.dart';
import 'screens/owner/owner_edit_profile_screen.dart';
import 'screens/owner/owner_attendance_tracking_screen.dart';
import 'screens/owner/owner_notifications_screen.dart';
import 'screens/owner/owner_pr_verification_screen.dart';
import 'screens/owner/jobs/owner_job_postings_screen.dart';
// Super Admin Portal
import 'screens/super_admin/super_admin_shell.dart';


// Leaderboard & Calendar
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/calendar/workout_calendar_screen.dart';
import 'screens/calendar/workout_day_screen.dart';

// Widgets
import 'widgets/bottom_nav_bar.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'widgets/role_guard.dart';
import 'widgets/super_admin_guard.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Global navigator key for session expiry navigation.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Only log navigation in debug mode to prevent info leakage
    SecureLogger.log('Navigator didPush: ${route.settings.name} from ${previousRoute?.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    SecureLogger.log('Navigator didReplace: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    SecureLogger.log('Navigator didPop: ${route.settings.name} returning to ${previousRoute?.settings.name}');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    SecureLogger.log('Navigator didRemove: ${route.settings.name} previous ${previousRoute?.settings.name}');
    super.didRemove(route, previousRoute);
  }
}

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      SecureLogger.logError('Flutter framework error', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      SecureLogger.logError('PlatformDispatcher uncaught error', error, stack);
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              // Don't expose exception details to users in production
              kDebugMode
                  ? 'Something went wrong.\nPlease restart the app.\n\n${details.exception}'
                  : 'Something went wrong.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase App Check
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode ? const AppleDebugProvider() : const AppleDeviceCheckProvider(),
      );
    } catch (e, stack) {
      SecureLogger.logError('Firebase initialization error', e, stack);
    }

    // Initialize Google Sign In (must be after Firebase.initializeApp)
    try {
      await AuthService.instance.initGoogleSignIn();
    } catch (e, stack) {
      SecureLogger.logError('Google Sign-In initialization skipped/failed', e, stack);
    }

    // Seed Database removed

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => GymProvider()),
          ChangeNotifierProvider(create: (_) => CommunityProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => EventsProvider()),
          ChangeNotifierProvider(create: (_) => PromotionsProvider()),
          ChangeNotifierProvider(create: (_) => BookingsProvider(), lazy: false),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
          ChangeNotifierProvider(create: (_) => CalendarProvider()),
          ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
          ChangeNotifierProvider(create: (_) => JobProvider()),
          ChangeNotifierProvider(create: (_) => JobApplicationProvider()),
          ChangeNotifierProvider(create: (_) => OwnerJobProvider()),
        ],
        child: const GymVibeApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    SecureLogger.logError('Uncaught zone error', error, stack);
  });
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, stack) {
      SecureLogger.logError('Firebase initialization error', e, stack);
    }

    try {
      await AuthService.instance.initGoogleSignIn();
    } catch (e, stack) {
      SecureLogger.logError('Google Sign-In initialization skipped/failed', e, stack);
    }

    // Seed Database removed
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'Gym Vibe Davao',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => GymProvider()),
            ChangeNotifierProvider(create: (_) => CommunityProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => EventsProvider()),
            ChangeNotifierProvider(create: (_) => PromotionsProvider()),
            ChangeNotifierProvider(create: (_) => BookingsProvider(), lazy: false),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
            ChangeNotifierProvider(create: (_) => CalendarProvider()),
            ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
            ChangeNotifierProvider(create: (_) => JobProvider()),
            ChangeNotifierProvider(create: (_) => JobApplicationProvider()),
            ChangeNotifierProvider(create: (_) => OwnerJobProvider()),
          ],
          child: const GymVibeApp(),
        );
      },
    );
  }
}

class GymVibeApp extends StatefulWidget {
  const GymVibeApp({super.key});

  @override
  State<GymVibeApp> createState() => _GymVibeAppState();
}

class _GymVibeAppState extends State<GymVibeApp> {
  @override
  void initState() {
    super.initState();
    // Wire up session expiry navigation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.onSessionExpiredNavigation = () {
        // Navigate to login when session expires
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the app in a GestureDetector to detect any user interaction
    // and reset the session inactivity timer.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => context.read<AuthProvider>().resetInactivityTimer(),
      onPanDown: (_) => context.read<AuthProvider>().resetInactivityTimer(),
      child: MaterialApp(
        title: 'Gym Vibe Davao',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver, LoggingNavigatorObserver()],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          SecureLogger.log('Route requested: ${settings.name}');
          switch (settings.name) {
            // ── User App ────────────────────────────────────────────
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.onboarding:
              return MaterialPageRoute(builder: (_) => const OnboardingScreen());
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AppRoutes.register:
              return MaterialPageRoute(
                  builder: (_) => const RegistrationScreen());
            case AppRoutes.main:
              return MaterialPageRoute(builder: (_) => const MainNavigation());
            case AppRoutes.gymDetails:
              final gym = settings.arguments as GymModel;
              return MaterialPageRoute(
                  builder: (_) => GymDetailsScreen(gym: gym));
            case AppRoutes.searchLanding:
              return MaterialPageRoute(
                  builder: (_) => const SearchLandingScreen());
            case AppRoutes.searchResults:
              return MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen());
            case AppRoutes.filters:
              return MaterialPageRoute(builder: (_) => const FiltersScreen());
            case AppRoutes.booking:
              final gym = settings.arguments as GymModel;
              return MaterialPageRoute(builder: (_) => BookingScreen(gym: gym));
            case AppRoutes.myBookings:
              return MaterialPageRoute(builder: (_) => const MyBookingsScreen());
            case AppRoutes.membership:
              return MaterialPageRoute(builder: (_) => const MembershipScreen());
            case AppRoutes.events:
              return MaterialPageRoute(builder: (_) => const EventsScreen());
            case AppRoutes.eventDetails:
              return MaterialPageRoute(builder: (_) => const EventDetailScreen(), settings: settings);
            case AppRoutes.myEvents:
              return MaterialPageRoute(builder: (_) => const MyEventsScreen(), settings: settings);
            case AppRoutes.eventRegistration:
              return MaterialPageRoute(builder: (_) => const EventRegistrationScreen(), settings: settings);
            case AppRoutes.eventRegistrationSuccess:
              return MaterialPageRoute(builder: (_) => const EventRegistrationSuccessScreen(), settings: settings);
            case AppRoutes.eventReminders:
              return MaterialPageRoute(builder: (_) => const EventRemindersScreen(), settings: settings);
            case AppRoutes.favorites:
              return MaterialPageRoute(builder: (_) => const FavoritesScreen());
            case AppRoutes.notifications:
              return MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen());
            case AppRoutes.myReviews:
              return MaterialPageRoute(builder: (_) => const MyReviewsScreen());
            case AppRoutes.membershipHistory:
              return MaterialPageRoute(
                  builder: (_) => const MembershipHistoryScreen());

            // ── Leaderboard & Calendar ─────────────────────────────────
            case AppRoutes.workoutCalendar:
              return MaterialPageRoute(
                  builder: (_) => const WorkoutCalendarScreen());
            case AppRoutes.workoutDay:
              final date = settings.arguments as DateTime;
              return MaterialPageRoute(
                  builder: (_) => WorkoutDayScreen(date: date));
            case AppRoutes.leaderboard:
              final gym = settings.arguments as GymModel;
              return MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(gym: gym));

            // ── Owner Portal ─────────────────────────────────────────
            case AppRoutes.ownerLogin:
              return MaterialPageRoute(builder: (_) => const OwnerLoginScreen());
            case AppRoutes.ownerRegister:
              return MaterialPageRoute(
                  builder: (_) => const OwnerRegisterScreen());
            case AppRoutes.ownerPortal:
              return MaterialPageRoute(builder: (_) => const RoleGuard(routeName: AppRoutes.ownerPortal, child: OwnerNavigation()));
            case AppRoutes.ownerCreateEvent:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerCreateEvent, child: OwnerCreateEventScreen()));
            case AppRoutes.ownerCreatePromotion:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerCreatePromotion, child: OwnerCreatePromotionScreen()));
            case AppRoutes.ownerEditProfile:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerEditProfile, child: OwnerEditProfileScreen()));
            case AppRoutes.ownerAttendanceTracking:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerAttendanceTracking, child: OwnerAttendanceTrackingScreen()));
            case AppRoutes.ownerNotifications:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerNotifications, child: OwnerNotificationsScreen()));
            case AppRoutes.ownerPrVerification:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerPrVerification, child: OwnerPrVerificationScreen()));
            case AppRoutes.ownerJobs:
              return MaterialPageRoute(
                  builder: (_) => const RoleGuard(routeName: AppRoutes.ownerJobs, child: OwnerJobPostingsScreen()));
                  
            case AppRoutes.jobs:
              return MaterialPageRoute(builder: (_) => const JobsScreen());
            case AppRoutes.myApplications:
              return MaterialPageRoute(builder: (_) => const MyApplicationsScreen());

            case AppRoutes.superAdminPortal:
          return MaterialPageRoute(
            builder: (_) => const SuperAdminGuard(child: SuperAdminShell()),
          );
        default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ),
              );
          }
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // 0 – Home
    const ExploreScreen(), // 1 – Explore
    const EventsScreen(), // 2 – Events
    const PromotionsScreen(), // 3 - Promos
    const ProfileScreen(), // 4 – Profile
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
