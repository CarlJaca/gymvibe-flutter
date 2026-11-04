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
  final double? latitude;
  final double? longitude;
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

  // ── Real Dataset Fields ──
  final String branch;
  final String district;
  final String? mapsUrl;
  final String phone;
  final String operatingHours;
  final String websiteOrFacebook;
  final List<String> workoutTypes;
  final List<String> scheduleType;
  final List<String> trainerAvailability;
  final List<String> membershipTypes;
  final int monthlyPricePhp;
  final int sessionPricePhp;
  final String sourceUrl;
  final String coordinateBasis;
  final String contactBasis;
  final String attributesBasis;
  final String priceBasis;
  final String notes;
  final bool hasVerifiedMapPoint;
  final String locationAccuracy; // 'Exact', 'Building', or 'Unverified'

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
    this.latitude,
    this.longitude,
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
    // Real dataset fields
    this.branch = '',
    this.district = '',
    this.mapsUrl,
    this.phone = '',
    this.operatingHours = '',
    this.websiteOrFacebook = '',
    this.workoutTypes = const [],
    this.scheduleType = const [],
    this.trainerAvailability = const [],
    this.membershipTypes = const [],
    this.monthlyPricePhp = 0,
    this.sessionPricePhp = 0,
    this.sourceUrl = '',
    this.coordinateBasis = '',
    this.contactBasis = '',
    this.attributesBasis = '',
    this.priceBasis = '',
    this.notes = '',
    this.hasVerifiedMapPoint = false,
    this.locationAccuracy = 'Unverified',
  });

  // ── Computed Properties ──

  /// Whether this gym has non-null coordinates.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Whether this gym has an independently verified exact map pin.
  /// Only these gyms should show a map marker and calculate distances.
  bool get canShowExactMapPin => hasCoordinates && hasVerifiedMapPoint;

  /// Whether this gym can show a map marker (exact or building-level).
  bool get canShowMapMarker =>
      hasCoordinates &&
      (locationAccuracy == 'Exact' || locationAccuracy == 'Building');

  /// Whether the location is a building-level approximation.
  bool get isBuildingLevel => hasCoordinates && locationAccuracy == 'Building';

  /// Whether the pin is approximate (has coordinates but not verified).
  bool get isPinApproximate => hasCoordinates && !hasVerifiedMapPoint;

  /// Whether the displayed price is an estimate.
  bool get isPriceEstimated =>
      priceBasis != 'Verified' && priceBasis.isNotEmpty;

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
    String? branch,
    String? district,
    String? mapsUrl,
    String? phone,
    String? operatingHours,
    String? websiteOrFacebook,
    List<String>? workoutTypes,
    List<String>? scheduleType,
    List<String>? trainerAvailability,
    List<String>? membershipTypes,
    int? monthlyPricePhp,
    int? sessionPricePhp,
    String? sourceUrl,
    String? coordinateBasis,
    String? contactBasis,
    String? attributesBasis,
    String? priceBasis,
    String? notes,
    bool? hasVerifiedMapPoint,
    String? locationAccuracy,
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
      branch: branch ?? this.branch,
      district: district ?? this.district,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      phone: phone ?? this.phone,
      operatingHours: operatingHours ?? this.operatingHours,
      websiteOrFacebook: websiteOrFacebook ?? this.websiteOrFacebook,
      workoutTypes: workoutTypes ?? this.workoutTypes,
      scheduleType: scheduleType ?? this.scheduleType,
      trainerAvailability: trainerAvailability ?? this.trainerAvailability,
      membershipTypes: membershipTypes ?? this.membershipTypes,
      monthlyPricePhp: monthlyPricePhp ?? this.monthlyPricePhp,
      sessionPricePhp: sessionPricePhp ?? this.sessionPricePhp,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      coordinateBasis: coordinateBasis ?? this.coordinateBasis,
      contactBasis: contactBasis ?? this.contactBasis,
      attributesBasis: attributesBasis ?? this.attributesBasis,
      priceBasis: priceBasis ?? this.priceBasis,
      notes: notes ?? this.notes,
      hasVerifiedMapPoint: hasVerifiedMapPoint ?? this.hasVerifiedMapPoint,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
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
      'statusUpdatedAt':
          statusUpdatedAt != null ? Timestamp.fromDate(statusUpdatedAt!) : null,
      'availableTimeSlots': availableTimeSlots,
      'blockedDates': blockedDates,
      'branch': branch,
      'district': district,
      'mapsUrl': mapsUrl,
      'phone': phone,
      'operatingHours': operatingHours,
      'websiteOrFacebook': websiteOrFacebook,
      'workoutTypes': workoutTypes,
      'scheduleType': scheduleType,
      'trainerAvailability': trainerAvailability,
      'membershipTypes': membershipTypes,
      'monthlyPricePhp': monthlyPricePhp,
      'sessionPricePhp': sessionPricePhp,
      'sourceUrl': sourceUrl,
      'coordinateBasis': coordinateBasis,
      'contactBasis': contactBasis,
      'attributesBasis': attributesBasis,
      'priceBasis': priceBasis,
      'notes': notes,
      'hasVerifiedMapPoint': hasVerifiedMapPoint,
      'locationAccuracy': locationAccuracy,
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
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      monthlyPrice: json['monthlyPrice'] ?? (json['priceRange'] ?? ''),
      sessionPrice: json['sessionPrice']?.toString() ?? '',
      membershipPlans: (json['membershipPlans'] as List<dynamic>?)
              ?.map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mapImageUrl: json['mapImageUrl'] ?? '',
      dailySchedule: Map<String, String>.from(json['dailySchedule'] ?? {}),
      socials: Map<String, String>.from(json['socials'] ?? {}),
      ratingBreakdown: Map<String, double>.from(
          (json['ratingBreakdown'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {}),
      capacity: json['capacity'] ?? 40,
      currentLiveStatus: json['currentLiveStatus'],
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? (json['statusUpdatedAt'] is Timestamp
              ? (json['statusUpdatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['statusUpdatedAt'].toString()))
          : null,
      availableTimeSlots: (json['availableTimeSlots'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      blockedDates: List<String>.from(json['blockedDates'] ?? []),
      branch: json['branch'] ?? '',
      district: json['district'] ?? '',
      mapsUrl: json['mapsUrl'],
      phone: json['phone'] ?? '',
      operatingHours: json['operatingHours'] ?? '',
      websiteOrFacebook: json['websiteOrFacebook'] ?? '',
      workoutTypes: List<String>.from(json['workoutTypes'] ?? []),
      scheduleType: List<String>.from(json['scheduleType'] ?? []),
      trainerAvailability: List<String>.from(json['trainerAvailability'] ?? []),
      membershipTypes: List<String>.from(json['membershipTypes'] ?? []),
      monthlyPricePhp: json['monthlyPricePhp'] ?? 0,
      sessionPricePhp: json['sessionPricePhp'] ?? 0,
      sourceUrl: json['sourceUrl'] ?? '',
      coordinateBasis: json['coordinateBasis'] ?? '',
      contactBasis: json['contactBasis'] ?? '',
      attributesBasis: json['attributesBasis'] ?? '',
      priceBasis: json['priceBasis'] ?? '',
      notes: json['notes'] ?? '',
      hasVerifiedMapPoint: json['hasVerifiedMapPoint'] ??
          json['has_verified_map_point'] ??
          false,
      locationAccuracy:
          json['locationAccuracy'] ?? json['location_accuracy'] ?? 'Unverified',
    );
  }

  /// Creates a GymModel from the bundled real dataset JSON.
  /// Generates a stable slug ID from name + branch.
  factory GymModel.fromDatasetJson(Map<String, dynamic> j) {
    final name = j['name'] as String? ?? '';
    final branch = j['branch'] as String? ?? '';
    final slug = _slugify('$name $branch');

    final monthlyPhp = j['monthly_price_php'] as int? ?? 0;
    final sessionPhp = j['session_price_php'] as int? ?? 0;
    final pBasis = j['price_basis'] as String? ?? '';
    final pricePrefix = pBasis != 'Verified' ? '≈ ' : '';

    // Build description from notes (use first sentence if available)
    final notes = j['notes'] as String? ?? '';
    final desc = notes.isNotEmpty
        ? (notes.contains('.')
            ? notes.substring(0, notes.indexOf('.') + 1)
            : notes)
        : '';

    return GymModel(
      id: slug,
      name: name,
      branch: branch,
      district: j['district'] as String? ?? '',
      imageUrl: '', // No image in real dataset — handled by UI placeholders
      address: j['address'] as String? ?? '',
      city: j['district'] as String? ?? '', // district maps to city for filter
      hours: j['operating_hours'] as String? ?? '',
      rating: 0.0, // No ratings in real dataset
      reviewCount: 0,
      isOpen: true, // Default open; real status unknown
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      mapsUrl: j['maps_url'] as String?,
      phone: j['phone'] as String? ?? '',
      operatingHours: j['operating_hours'] as String? ?? '',
      websiteOrFacebook: j['website_or_facebook'] as String? ?? '',
      workoutTypes: List<String>.from(j['workout_types'] ?? []),
      facilities: List<String>.from(j['facilities'] ?? []),
      scheduleType: List<String>.from(j['schedule_type'] ?? []),
      trainerAvailability: List<String>.from(j['trainer_availability'] ?? []),
      membershipTypes: List<String>.from(j['membership_types'] ?? []),
      monthlyPricePhp: monthlyPhp,
      sessionPricePhp: sessionPhp,
      monthlyPrice: monthlyPhp > 0
          ? '$pricePrefix₱${_formatNumber(monthlyPhp)}/Monthly'
          : '',
      sessionPrice: sessionPhp > 0
          ? '$pricePrefix₱${_formatNumber(sessionPhp)}/Session'
          : '',
      sourceUrl: j['source_url'] as String? ?? '',
      coordinateBasis: j['coordinate_basis'] as String? ?? '',
      contactBasis: j['contact_basis'] as String? ?? '',
      attributesBasis: j['attributes_basis'] as String? ?? '',
      priceBasis: pBasis,
      notes: notes,
      hasVerifiedMapPoint: j['has_verified_map_point'] as bool? ?? false,
      locationAccuracy: j['location_accuracy'] as String? ?? 'Unverified',
      categories: List<String>.from(j['workout_types'] ??
          []), // Map workout_types → categories for Jaccard
      description: desc,
    );
  }

  /// Generates a URL-safe slug from a string.
  static String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-');
  }

  /// Formats a number with comma separators (e.g., 7000 → "7,000").
  static String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
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
