class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String userLocation;
  final String communityId;
  final String communityName;
  final String caption;
  final String? imageUrl;
  int likeCount;
  final int commentCount;
  List<String> likedBy;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.userLocation,
    required this.communityId,
    required this.communityName,
    required this.caption,
    this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    this.likedBy = const [],
    required this.createdAt,
  });

  PostModel copyWith({List<String>? likedBy, int? likeCount, int? commentCount}) {
    return PostModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userLocation: userLocation,
      communityId: communityId,
      communityName: communityName,
      caption: caption,
      imageUrl: imageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'userLocation': userLocation,
      'communityId': communityId,
      'communityName': communityName,
      'caption': caption,
      'imageUrl': imageUrl,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json, String documentId) {
    return PostModel(
      id: documentId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      userLocation: json['userLocation'] ?? '',
      communityId: json['communityId'] ?? '',
      communityName: json['communityName'] ?? '',
      caption: json['caption'] ?? '',
      imageUrl: json['imageUrl'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class CommunityModel {
  final String id;
  final String name;
  final String imageUrl;
  final int memberCount;
  final bool isComingSoon;
  final String description;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.memberCount,
    this.isComingSoon = false,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'isComingSoon': isComingSoon,
      'description': description,
    };
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CommunityModel(
      id: documentId,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      isComingSoon: json['isComingSoon'] ?? false,
      description: json['description'] ?? '',
    );
  }
}


