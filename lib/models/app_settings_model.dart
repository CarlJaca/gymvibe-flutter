class AppSettingsModel {
  final String supportEmail;
  final bool maintenanceMode;
  final bool registrationEnabled;
  final double defaultSearchRadiusKm;
  final List<String> leaderboardCategories;
  final List<String> reportReasons;
  final List<String> suspensionReasons;

  const AppSettingsModel({
    this.supportEmail = 'support@gymvibe.com',
    this.maintenanceMode = false,
    this.registrationEnabled = true,
    this.defaultSearchRadiusKm = 10.0,
    this.leaderboardCategories = const [
      'Deadlift',
      'Bench Press',
      'Squat',
      'Dumbbell Curl',
      'Overhead Press',
    ],
    this.reportReasons = const [
      'Spam or misleading',
      'Inappropriate content',
      'Harassment or bullying',
      'False information',
      'Offensive language',
      'Other',
    ],
    this.suspensionReasons = const [
      'Violation of terms of service',
      'Repeated policy violations',
      'Suspicious activity',
      'Fraudulent behavior',
      'Inappropriate content',
      'Other',
    ],
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      supportEmail: json['supportEmail'] ?? 'support@gymvibe.com',
      maintenanceMode: json['maintenanceMode'] ?? false,
      registrationEnabled: json['registrationEnabled'] ?? true,
      defaultSearchRadiusKm: (json['defaultSearchRadiusKm'] ?? 10.0).toDouble(),
      leaderboardCategories: List<String>.from(json['leaderboardCategories'] ?? [
        'Deadlift', 'Bench Press', 'Squat', 'Dumbbell Curl', 'Overhead Press',
      ]),
      reportReasons: List<String>.from(json['reportReasons'] ?? [
        'Spam or misleading', 'Inappropriate content', 'Harassment or bullying',
        'False information', 'Offensive language', 'Other',
      ]),
      suspensionReasons: List<String>.from(json['suspensionReasons'] ?? [
        'Violation of terms of service', 'Repeated policy violations',
        'Suspicious activity', 'Fraudulent behavior', 'Inappropriate content', 'Other',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportEmail': supportEmail,
      'maintenanceMode': maintenanceMode,
      'registrationEnabled': registrationEnabled,
      'defaultSearchRadiusKm': defaultSearchRadiusKm,
      'leaderboardCategories': leaderboardCategories,
      'reportReasons': reportReasons,
      'suspensionReasons': suspensionReasons,
    };
  }

  AppSettingsModel copyWith({
    String? supportEmail,
    bool? maintenanceMode,
    bool? registrationEnabled,
    double? defaultSearchRadiusKm,
    List<String>? leaderboardCategories,
    List<String>? reportReasons,
    List<String>? suspensionReasons,
  }) {
    return AppSettingsModel(
      supportEmail: supportEmail ?? this.supportEmail,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      registrationEnabled: registrationEnabled ?? this.registrationEnabled,
      defaultSearchRadiusKm: defaultSearchRadiusKm ?? this.defaultSearchRadiusKm,
      leaderboardCategories: leaderboardCategories ?? this.leaderboardCategories,
      reportReasons: reportReasons ?? this.reportReasons,
      suspensionReasons: suspensionReasons ?? this.suspensionReasons,
    );
  }
}
