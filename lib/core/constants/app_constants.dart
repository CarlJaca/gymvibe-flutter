import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFF22C55E); // Neon Green
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color accentOrange = Color(0xFFFF6D00); // Neon Orange
  static const Color accentPurple = Color(0xFFD500F9); // Neon Purple
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF5A5A5A);
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF1F1F1F);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF4CAF50);
  static const Color star = Color(0xFFFFD700);
  static const Color heart = Color(0xFFFF4466);
  static const Color overlay = Color(0x99000000);
}

class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

class AppPadding {
  AppPadding._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppSizes {
  AppSizes._();

  static const double gymCardHeight = 210.0;
  static const double exploreTileHeight = 72.0;
  static const double bottomNavHeight = 68.0;
  static const double avatarSm = 36.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 80.0;
  static const double avatarXL = 100.0;
  static const double heroImageHeight = 300.0;
  static const double communityAvatarSize = 60.0;
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Gym Vibe Davao';
  static const String appNameLine1 = 'GYM VIBE';
  static const String appNameLine2 = 'DAVAO';
  static const String tagline = 'Find. Fit. Thrive.';
  static const String forYou = 'For You';
  static const String explore = 'Explore';
  static const String events = 'Events';
  static const String favorites = 'Favorites';
  static const String community = 'Community';
  static const String profile = 'Profile';
  static const String location = 'Location';
  static const String topRated = 'Top Rated';
  static const String recommended = 'Recommended for You';
  static const String nearbyGyms = 'Nearby Gyms';
  static const String allCommunities = 'All communities';
  static const String viewAll = 'View all';
  static const String seeAll = 'See All';
  static const String publishPost = 'Publish Post';
  static const String writeYourPost = 'Write your post here...';
  static const String bookVisit = 'Book a Visit';
  static const String joinNow = 'Join Now';
  static const String findMyGym = 'Find My Gym';
  static const String davaoCityTitle = 'Davao City';
  static const String fitnessEvents = 'Fitness Events';
  static const String discoverEvents = 'Discover events near you';
  static const String savedGyms = 'Saved Gyms';
}
