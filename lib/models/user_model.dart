import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String location;
  final String membershipType;
  final List<String> savedGymIds;
  final List<String> fitnessPreferences;
  final String role; // 'gym_seeker', 'gym_owner', 'super_admin'
  final String accountStatus; // 'active', 'pending', 'suspended', 'deactivated'
  final String? gymName;
  final String? contactNumber;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool hasCompletedPreferences;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.location,
    this.membershipType = 'Free',
    this.savedGymIds = const [],
    this.fitnessPreferences = const [],
    this.role = 'gym_seeker',
    this.accountStatus = 'active',
    this.gymName,
    this.contactNumber,
    this.createdAt,
    this.lastLogin,
    this.hasCompletedPreferences = false,
  });

  // ─── Computed role getters (backward compatible) ─────────────────────
  bool get isOwner => role == 'gym_owner' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isGymSeeker => role == 'gym_seeker';
  bool get isGymOwner => role == 'gym_owner';

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    // Backward compat: if 'role' is missing, derive from legacy 'isOwner' bool
    String role = json['role'] ?? (json['isOwner'] == true ? 'gym_owner' : 'gym_seeker');

    DateTime? createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.tryParse(json['createdAt']);
    }

    DateTime? lastLogin;
    if (json['lastLogin'] is Timestamp) {
      lastLogin = (json['lastLogin'] as Timestamp).toDate();
    } else if (json['lastLogin'] is String) {
      lastLogin = DateTime.tryParse(json['lastLogin']);
    }

    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=15',
      location: json['location'] ?? 'Davao City',
      membershipType: json['membershipType'] ?? 'Free',
      savedGymIds: List<String>.from(json['savedGymIds'] ?? []),
      fitnessPreferences: List<String>.from(json['fitnessPreferences'] ?? []),
      role: role,
      accountStatus: json['accountStatus'] ?? 'active',
      gymName: json['gymName'],
      contactNumber: json['contactNumber'],
      createdAt: createdAt,
      lastLogin: lastLogin,
      hasCompletedPreferences: json['hasCompletedPreferences'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'location': location,
      'membershipType': membershipType,
      'savedGymIds': savedGymIds,
      'fitnessPreferences': fitnessPreferences,
      'isOwner': isOwner, // backward compat
      'role': role,
      'accountStatus': accountStatus,
      'gymName': gymName,
      'contactNumber': contactNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'hasCompletedPreferences': hasCompletedPreferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? location,
    String? membershipType,
    List<String>? savedGymIds,
    List<String>? fitnessPreferences,
    String? role,
    String? accountStatus,
    String? gymName,
    String? contactNumber,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? hasCompletedPreferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      membershipType: membershipType ?? this.membershipType,
      savedGymIds: savedGymIds ?? this.savedGymIds,
      fitnessPreferences: fitnessPreferences ?? this.fitnessPreferences,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      gymName: gymName ?? this.gymName,
      contactNumber: contactNumber ?? this.contactNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      hasCompletedPreferences: hasCompletedPreferences ?? this.hasCompletedPreferences,
    );
  }
}
