# GymVibe Flutter App

A modern, premium fitness mobile application built with Flutter.

## Features

- **Splash Screen** - Welcoming onboarding with gym imagery
- **3-Step Onboarding** - Interactive carousel introducing app features
- **Login System** - Secure authentication with social login options
- **Registration** - Complete sign-up flow with validation
- **Home Dashboard** - Personalized gym discovery interface
- **Gym Details** - Comprehensive gym information with tabs
- **Membership Plans** - Pricing tiers with monthly/yearly toggle
- **User Profile** - Account management and settings
- **Booking System** - Schedule gym visits, trainers, and classes
- **Bottom Navigation** - Seamless app navigation

## Design

- **Dark Theme** - Modern black background (#000000)
- **Typography** - Clean white text (#FFFFFF)
- **Accent Color** - Vibrant orange (#FF6B00)
- **Glassmorphism** - Elegant frosted glass effects
- **Rounded Corners** - Smooth 16-24px border radius
- **iOS-Inspired** - Premium mobile-first design

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (IDE)

## Setup Instructions

### 1. Navigate to the project directory
```bash
cd gymvibe-flutter
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the app

**For Android:**
```bash
flutter run
```

**For iOS:**
```bash
flutter run -d ios
```

**For Web:**
```bash
flutter run -d chrome
```

## Project Structure

```
gymvibe-flutter/
├── lib/
│   ├── main.dart                 # App entry point and navigation
│   ├── screens/
│   │   ├── splash_screen.dart    # Splash screen
│   │   ├── onboarding_screen.dart # Onboarding carousel
│   │   ├── login_screen.dart     # Login screen
│   │   ├── registration_screen.dart # Registration screen
│   │   ├── home_screen.dart      # Home dashboard
│   │   ├── gym_details_screen.dart # Gym details with tabs
│   │   ├── membership_screen.dart # Membership plans
│   │   ├── profile_screen.dart   # User profile
│   │   └── booking_screen.dart   # Booking system
│   └── widgets/                  # Reusable widgets
├── android/                      # Android configuration
├── ios/                          # iOS configuration
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

## Dependencies

- `flutter` - Flutter SDK
- `cupertino_icons` - iOS-style icons
- `google_fonts` - Google Fonts integration
- `cached_network_image` - Image caching
- `smooth_page_indicator` - Page indicator for onboarding

## Screens Overview

1. **Splash Screen** - Initial welcome with "Get Started" CTA
2. **Onboarding Screens** - 3-slide carousel:
   - Find the Perfect Gym
   - Compare Memberships
   - Start Your Journey
3. **Login Screen** - Email/password + social auth
4. **Registration Screen** - Full sign-up form
5. **Home Dashboard** - Nearby, Popular, and Recommended gyms
6. **Gym Details** - Overview, Facilities, Plans, Reviews tabs
7. **Membership Plans** - Basic, Premium, Elite tiers
8. **User Profile** - Personal info, membership, settings
9. **Booking System** - Calendar, time slots, trainer/class selection

## Build for Production

### Android APK:
```bash
flutter build apk --release
```

### Android App Bundle:
```bash
flutter build appbundle --release
```

### iOS:
```bash
flutter build ios --release
```

### Web:
```bash
flutter build web --release
```

## Notes

- The app uses placeholder images from Unsplash
- All navigation is handled through state management
- Responsive design optimized for mobile
- Glassmorphism effects use backdrop blur and transparency
- Material Design 3 components with custom dark theme

## Troubleshooting

### Flutter command not found
Make sure Flutter is installed and added to your PATH:
```bash
flutter doctor
```

### Dependencies not installing
Run:
```bash
flutter clean
flutter pub get
```

### iOS build issues
Make sure you have Xcode installed and CocoaPods updated:
```bash
cd ios
pod install
cd ..
```

## License

This project is for demonstration purposes.
