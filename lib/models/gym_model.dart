import 'package:cloud_firestore/cloud_firestore.dart';

class GymModel {
  final String id;
  final String? ownerId;
  final String name;
  final String imageUrl;
  final String address;
  final String city;
  final String hours;
  final double rating;
  final int reviewCount;
  final int memberCount;
  final int bookingsCount;
  final bool isOpen;
  final String status;
  bool isFavorite;
  bool isSaved;
  final List<String> categories;
  final List<String> facilities;
  final String description;
  final List<ReviewModel> reviews;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String monthlyPrice;
  final String sessionPrice;
  final List<MembershipPlan> membershipPlans;
  final String mapImageUrl;
  final Map<String, String> dailySchedule;
  final Map<String, String> socials;
  final Map<String, double> ratingBreakdown;
  // ── Crowd Status Fields ──
  final int capacity;
  final String? currentLiveStatus;
  final DateTime? statusUpdatedAt;
  final List<Map<String, String>> availableTimeSlots;
  final List<String> blockedDates;

  GymModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.city,
    required this.hours,
    required this.rating,
    required this.reviewCount,
    this.memberCount = 0,
    this.bookingsCount = 0,
    required this.isOpen,
    this.status = 'active',
    this.isFavorite = false,
    this.isSaved = false,
    this.categories = const [],
    this.facilities = const [],
    this.description = '',
    this.reviews = const [],
    this.distanceKm = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.monthlyPrice = '',
    this.sessionPrice = '',
    this.membershipPlans = const [],
    this.mapImageUrl = '',
    this.dailySchedule = const {},
    this.socials = const {},
    this.ratingBreakdown = const {},
    this.capacity = 40,
    this.currentLiveStatus,
    this.statusUpdatedAt,
    this.availableTimeSlots = const [],
    this.blockedDates = const [],
  });

  GymModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? imageUrl,
    String? address,
    String? city,
    String? hours,
    double? rating,
    int? reviewCount,
    int? memberCount,
    int? bookingsCount,
    bool? isOpen,
    String? status,
    bool? isFavorite,
    bool? isSaved,
    List<String>? categories,
    List<String>? facilities,
    String? description,
    List<ReviewModel>? reviews,
    double? distanceKm,
    double? latitude,
    double? longitude,
    String? monthlyPrice,
    String? sessionPrice,
    List<MembershipPlan>? membershipPlans,
    String? mapImageUrl,
    Map<String, String>? dailySchedule,
    Map<String, String>? socials,
    Map<String, double>? ratingBreakdown,
    int? capacity,
    String? currentLiveStatus,
    DateTime? statusUpdatedAt,
    List<Map<String, String>>? availableTimeSlots,
    List<String>? blockedDates,
  }) {
    return GymModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      hours: hours ?? this.hours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      memberCount: memberCount ?? this.memberCount,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      isOpen: isOpen ?? this.isOpen,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      isSaved: isSaved ?? this.isSaved,
      categories: categories ?? this.categories,
      facilities: facilities ?? this.facilities,
      description: description ?? this.description,
      reviews: reviews ?? this.reviews,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      sessionPrice: sessionPrice ?? this.sessionPrice,
      membershipPlans: membershipPlans ?? this.membershipPlans,
      mapImageUrl: mapImageUrl ?? this.mapImageUrl,
      dailySchedule: dailySchedule ?? this.dailySchedule,
      socials: socials ?? this.socials,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      capacity: capacity ?? this.capacity,
      currentLiveStatus: currentLiveStatus ?? this.currentLiveStatus,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      blockedDates: blockedDates ?? this.blockedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'imageUrl': imageUrl,
      'address': address,
      'city': city,
      'hours': hours,
      'rating': rating,
      'reviewCount': reviewCount,
      'memberCount': memberCount,
      'bookingsCount': bookingsCount,
      'isOpen': isOpen,
      'status': status,
      'isFavorite': isFavorite,
      'isSaved': isSaved,
      'categories': categories,
      'facilities': facilities,
      'description': description,
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'monthlyPrice': monthlyPrice,
      'sessionPrice': sessionPrice,
      'membershipPlans': membershipPlans.map((e) => e.toJson()).toList(),
      'mapImageUrl': mapImageUrl,
      'dailySchedule': dailySchedule,
      'socials': socials,
      'ratingBreakdown': ratingBreakdown,
      'capacity': capacity,
      'currentLiveStatus': currentLiveStatus,
      'statusUpdatedAt': statusUpdatedAt != null ? Timestamp.fromDate(statusUpdatedAt!) : null,
      'availableTimeSlots': availableTimeSlots,
      'blockedDates': blockedDates,
    };
  }

  factory GymModel.fromJson(Map<String, dynamic> json, String documentId) {
    return GymModel(
      id: documentId,
      ownerId: json['ownerId'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      hours: json['hours'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      bookingsCount: json['bookingsCount'] ?? 0,
      isOpen: json['isOpen'] ?? false,
      status: json['status'] ?? 'active',
      isFavorite: json['isFavorite'] ?? false,
      isSaved: json['isSaved'] ?? false,
      categories: List<String>.from(json['categories'] ?? []),
      facilities: List<String>.from(json['facilities'] ?? []),
      description: json['description'] ?? '',
      reviews: (json['reviews'] as List<dynamic>?)?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      monthlyPrice: json['monthlyPrice'] ?? (json['priceRange'] ?? ''),
      sessionPrice: json['sessionPrice']?.toString() ?? '',
      membershipPlans: (json['membershipPlans'] as List<dynamic>?)?.map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      mapImageUrl: json['mapImageUrl'] ?? '',
      dailySchedule: Map<String, String>.from(json['dailySchedule'] ?? {}),
      socials: Map<String, String>.from(json['socials'] ?? {}),
      ratingBreakdown: Map<String, double>.from((json['ratingBreakdown'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
      capacity: json['capacity'] ?? 40,
      currentLiveStatus: json['currentLiveStatus'],
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? (json['statusUpdatedAt'] is Timestamp
              ? (json['statusUpdatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['statusUpdatedAt'].toString()))
          : null,
      availableTimeSlots: (json['availableTimeSlots'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      blockedDates: List<String>.from(json['blockedDates'] ?? []),
    );
  }
}

class ReviewModel {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final String date;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class MembershipPlan {
  final String id;
  final String name;
  final double monthlyPrice;
  final String features;
  final bool isRecommended;
  final List<String> perks;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.features,
    this.isRecommended = false,
    this.perks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyPrice': monthlyPrice,
      'features': features,
      'isRecommended': isRecommended,
      'perks': perks,
    };
  }

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      features: json['features'] ?? '',
      isRecommended: json['isRecommended'] ?? false,
      perks: List<String>.from(json['perks'] ?? []),
    );
  }
}
