import '../models/gym_model.dart';
import '../models/post_model.dart';

class GymService {
  GymService._();
  static final GymService instance = GymService._();

  // ─── Mock Gym Data removed — real data comes from GymRepository ───────────
  List<GymModel> fetchGyms() {
    return []; // No longer used; gym data loaded from assets/data/davao_gyms.json
  }

  // ─── Mock Community Data ────────────────────────────────────────────────────
  List<CommunityModel> fetchCommunities() {
    return [
      const CommunityModel(
        id: 'c1',
        name: 'Hardcore Lifting Squad',
        imageUrl:
            'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=200&q=80',
        memberCount: 1240,
        description: 'For serious lifters pushing their limits every day.',
      ),
      const CommunityModel(
        id: 'c2',
        name: 'Boutique Collective',
        imageUrl:
            'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=200&q=80',
        memberCount: 890,
        description: 'Boutique fitness enthusiasts — yoga, pilates, barre.',
      ),
      const CommunityModel(
        id: 'c3',
        name: 'Mindful Movement Spa',
        imageUrl:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200&q=80',
        memberCount: 650,
        description: 'Wellness, mindfulness, and recovery focused community.',
      ),
      const CommunityModel(
        id: 'c4',
        name: 'Coming Soon',
        imageUrl:
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&q=80',
        memberCount: 0,
        isComingSoon: true,
        description: 'New community launching soon. Stay tuned!',
      ),
    ];
  }

  // ─── Mock Post Data ─────────────────────────────────────────────────────────
  List<PostModel> fetchPosts() {
    return [
      PostModel(
        id: 'post1',
        userId: 'u1',
        userName: 'Jeffrey Caman',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
        userLocation: 'Bangkal, Davao city',
        communityId: 'c1',
        communityName: 'HARDCORE LIFTING SQUAD',
        caption:
            'Check out our new crossfit rig! Ready for the weekend warriors. Come through and get that sweat equity. 🔥',
        likeCount: 102,
        commentCount: 15,
        likedBy: ['u1', 'u2'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PostModel(
        id: 'post2',
        userId: 'u2',
        userName: 'Maria Santos',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        userLocation: 'Matina, Davao City',
        communityId: 'c2',
        communityName: 'BOUTIQUE COLLECTIVE',
        caption:
            'Just finished an amazing yoga flow session at Metro Fitness! The instructor was phenomenal. Feeling so recharged and ready for the week. 🧘‍♀️ #YogaLife #BoutiqueCollective',
        likeCount: 34,
        commentCount: 5,
        likedBy: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: 'post3',
        userId: 'u3',
        userName: 'Carlos Mendoza',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
        userLocation: 'Buhangin, Davao City',
        communityId: 'c1',
        communityName: 'HARDCORE LIFTING SQUAD',
        caption:
            '6 months of consistent training and I finally hit my goal weight! 85kg → 72kg. Never skip leg day, never skip meal prep. The grind is worth it! 💪 #TransformationTuesday',
        likeCount: 87,
        commentCount: 42,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: 'post4',
        userId: 'u4',
        userName: 'Ana Reyes',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        userLocation: 'Ecoland, Davao City',
        communityId: 'c3',
        communityName: 'MINDFUL MOVEMENT SPA',
        caption:
            'Recovery day is just as important as training day. Ice bath + stretching + meditation. Your body will thank you. 🧊❄️ #RecoveryDay #MindfulMovement',
        likeCount: 29,
        commentCount: 6,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
