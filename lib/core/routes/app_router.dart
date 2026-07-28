class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String gymPreferences = '/gym-preferences';
  static const String gymDetails = '/gym-details';
  static const String booking = '/booking';
  static const String myBookings = '/my-bookings';
  static const String membership = '/membership';
  static const String searchLanding = '/search-landing';
  static const String searchResults = '/search-results';
  static const String filters = '/filters';
  static const String events = '/events';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String myReviews = '/my-reviews';
  static const String membershipHistory = '/membership-history';
  
  // ── Fitness Events ────────────────────────────────────────────────
  static const String eventDetails = '/event-details';
  static const String myEvents = '/my-events';
  static const String eventRegistration = '/event-registration';
  static const String eventRegistrationSuccess = '/event-registration-success';
  static const String eventReminders = '/event-reminders';

  // ── Leaderboard & Calendar ─────────────────────────────────────────
  static const String workoutCalendar = '/workout-calendar';
  static const String workoutDay = '/workout-day';
  static const String leaderboard = '/leaderboard';

  // ── Owner Portal ──────────────────────────────────────────────────
  static const String ownerPrVerification = '/owner-pr-verification';
  static const String ownerLogin     = '/owner-login';
  static const String ownerRegister  = '/owner-register';
  static const String ownerPortal    = '/owner-portal';
  static const String ownerCreateEvent      = '/owner-create-event';
  static const String ownerCreatePromotion  = '/owner-create-promotion';
  static const String ownerEditProfile      = '/owner-edit-profile';
  static const String ownerAttendanceTracking = '/owner-attendance-tracking';
  static const String ownerNotifications      = '/owner-notifications';
  static const String ownerJobs = '/owner-jobs';

  // ── Super Admin Portal ────────────────────────────────────────────
  static const String superAdminPortal = '/super-admin';

  // ── Jobs (Seeker) ─────────────────────────────────────────────────
  static const String jobs = '/jobs';
  static const String myApplications = '/my-applications';
}

