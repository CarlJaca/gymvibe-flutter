import '../models/gym_model.dart';
import '../models/post_model.dart';

class GymService {
  GymService._();
  static final GymService instance = GymService._();

  // ─── Mock Gym Data (Davao City Gyms matching design) ───────────────────────
  List<GymModel> fetchGyms() {
    return [
      GymModel(
        id: '1',
        name: 'Dstar Gym Matina',
        imageUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
        address: 'Matina, Davao City',
        city: 'Davao City',
        hours: 'Open 24 Hours',
        rating: 4.6,
        reviewCount: 214,
        isOpen: true,
        distanceKm: 0.8,
        latitude: 7.0652,
        longitude: 125.5947,
        sessionPrice: '₱200/Session',
        monthlyPrice: '₱1,000/Monthly',
        description:
            'Dstar Gym Matina is a premier fitness center offering state-of-the-art equipment, expert trainers, and a motivating environment for all fitness levels. Located in the heart of Matina, we are open 24 hours to fit your busy schedule.',
        categories: [
          'Strength Training',
          'Cardio',
          'Gym',
        ],
        facilities: [
          'Locker Room',
          'Shower Area',
          'AC',
          'WiFi',
          'Parking',
          'Group Classes',
          'Boxing',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Monthly Membership',
            monthlyPrice: 1000,
            features: 'Full Gym Access',
            perks: ['24/7 Access', 'Locker Room', 'Free Parking', 'Group Classes'],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Maria Santos',
            userAvatarUrl:
                'https://i.pravatar.cc/150?img=1',
            rating: 5,
            comment:
                'Best gym in Davao! Equipment is always clean and staff is super friendly.',
            date: '2 days ago',
          ),
          const ReviewModel(
            id: 'r2',
            userName: 'Juan dela Cruz',
            userAvatarUrl:
                'https://i.pravatar.cc/150?img=3',
            rating: 4,
            comment:
                'Great value for money. Gets a bit crowded during peak hours but overall excellent.',
            date: '1 week ago',
          ),
          const ReviewModel(
            id: 'r3',
            userName: 'Ana Reyes',
            userAvatarUrl:
                'https://i.pravatar.cc/150?img=5',
            rating: 5,
            comment:
                'Love the 24hr access. Perfect for my night shift schedule!',
            date: '2 weeks ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
      GymModel(
        id: '2',
        name: 'Ultradynamic Gym Buhangin',
        imageUrl:
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
        address: 'Buhangin, Davao City',
        city: 'Davao City',
        hours: '5:00 am – 12:00 am',
        rating: 4.5,
        reviewCount: 187,
        isOpen: true,
        distanceKm: 1.4,
        latitude: 7.1026,
        longitude: 125.6146,
        sessionPrice: '₱150/Session',
        monthlyPrice: '₱1,000/Monthly',
        description:
            'Ultradynamic Gym Buhangin offers a dynamic training environment with high-performance equipment and expert coaching to help you achieve your fitness goals faster.',
        categories: [
          'Cardio',
          'Strength Training',
          'Gym',
        ],
        facilities: [
          'Sauna',
          'Locker Room',
          'Parking',
          'WiFi',
          'AC',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Monthly Membership',
            monthlyPrice: 1000,
            features: 'Full Gym Access',
            perks: ['All Access', 'Sauna', 'Group Classes', 'Locker Room'],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Carlos Mendoza',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
            rating: 5,
            comment: 'Top tier gym! Great equipment and amazing trainers.',
            date: '3 days ago',
          ),
          const ReviewModel(
            id: 'r2',
            userName: 'Sofia Lim',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=9',
            rating: 4,
            comment:
                'Clean and well-maintained. The sauna is a great bonus!',
            date: '5 days ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
      GymModel(
        id: '3',
        name: 'Continental Gym',
        imageUrl:
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
        address: 'Poblacion District, Davao City',
        city: 'Davao City',
        hours: 'Open 24 Hours',
        rating: 4.4,
        reviewCount: 156,
        isOpen: true,
        distanceKm: 2.1,
        latitude: 7.0736,
        longitude: 125.6105,
        sessionPrice: '₱100–₱150/Session',
        monthlyPrice: '₱1,000/Monthly',
        description:
            'Continental Gym has been a trusted fitness destination in Davao City for over a decade. Offering a wide range of equipment and classes for all fitness levels.',
        categories: [
          'Strength Training',
          'Cardio',
          'Boxing',
        ],
        facilities: [
          'Group Classes',
          'Locker Room',
          'Parking',
          'AC',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Monthly Membership',
            monthlyPrice: 1000,
            features: 'Full Gym Access',
            perks: ['All Access', 'Boxing Classes', 'Group Classes', 'Locker Room', 'Parking'],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Miguel Torres',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=11',
            rating: 4,
            comment: 'Solid gym with great equipment. Very affordable!',
            date: '1 week ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
      GymModel(
        id: '4',
        name: 'Elevation Gym Buhangin',
        imageUrl:
            'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?w=800&q=80',
        address: 'Buhangin, Davao City',
        city: 'Davao City',
        hours: '5:00 am – 11:00 pm',
        rating: 4.8,
        reviewCount: 302,
        isOpen: true,
        distanceKm: 1.7,
        latitude: 7.0986,
        longitude: 125.6116,
        sessionPrice: '₱150/Session',
        monthlyPrice: '₱1,000/Monthly',
        description:
            'Elevation Gym Buhangin is where champions are made. Featuring Olympic-grade equipment, certified coaches, and a high-energy atmosphere that will elevate your performance to the next level.',
        categories: [
          'Strength Training',
          'CrossFit',
          'Cardio',
        ],
        facilities: [
          'Personal Trainers',
          'Group Classes',
          'Nutrition Bar',
          'Locker Room',
          'Shower Area',
          'AC',
          'WiFi',
          'Parking',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Monthly Membership',
            monthlyPrice: 1000,
            features: 'Full Gym Access',
            perks: ['All Access', 'Unlimited Classes', 'Nutrition Bar', 'Locker Room', 'Parking'],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Jeffrey Caman',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
            rating: 5,
            comment:
                'New PR on the deadlift today! 180kg for 3 reps. The atmosphere here is what makes the difference. If you aren\'t hearing the plates clang, you aren\'t in the right vibe. #DavaoStrong #HardcoreLifting',
            date: '1 day ago',
          ),
          const ReviewModel(
            id: 'r2',
            userName: 'Renz Gultiano',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=16',
            rating: 5,
            comment: 'Best powerlifting gym in all of Mindanao. Period.',
            date: '3 days ago',
          ),
          const ReviewModel(
            id: 'r3',
            userName: 'Cha Bautista',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=20',
            rating: 5,
            comment:
                'Amazing coaches! I lost 15kg in 3 months here. Highly recommend!',
            date: '2 weeks ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
      GymModel(
        id: '5',
        name: 'The Metro Fitness & Family Gym',
        imageUrl:
            'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80',
        address: 'Ecoland, Davao City',
        city: 'Davao City',
        hours: '5:00 am – 10:00 pm',
        rating: 4.3,
        reviewCount: 134,
        isOpen: true,
        distanceKm: 3.2,
        latitude: 7.0544,
        longitude: 125.5901,
        sessionPrice: '₱280/Session',
        monthlyPrice: '₱1,840/Monthly',
        description:
            'Metro Fitness & Family Gym is a welcoming space for the whole family. Featuring dedicated areas for kids, group fitness classes, and a supportive community of health-conscious Dabawenyos.',
        categories: [
          'Pilates',
          'Cardio',
          'Strength Training',
        ],
        facilities: [
          'Group Classes',
          'Kids Area',
          'Yoga Studio',
          'Locker Room',
          'Parking',
          'WiFi',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Monthly Membership',
            monthlyPrice: 1840,
            features: 'Full Gym Access',
            perks: ['Full Access', 'Kids Zone', 'Group Classes', 'Yoga', 'Locker Room', 'Parking'],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Rose Navarro',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=25',
            rating: 4,
            comment:
                'Perfect for the whole family. My kids love the play area!',
            date: '4 days ago',
          ),
          const ReviewModel(
            id: 'r2',
            userName: 'Ben Villanueva',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=27',
            rating: 4,
            comment: 'Great yoga classes and very family-friendly atmosphere.',
            date: '2 weeks ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
      GymModel(
        id: '6',
        name: 'Dallas Gym Matina',
        imageUrl:
            'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=80',
        address: 'Matina, Davao City',
        city: 'Davao City',
        hours: 'Open 24 Hours',
        rating: 4.2,
        reviewCount: 98,
        isOpen: true,
        distanceKm: 1.1,
        latitude: 7.0620,
        longitude: 125.5920,
        sessionPrice: '₱100/Session',
        monthlyPrice: '₱500/Monthly',
        description:
            'Dallas Gym Matina is your go-to budget-friendly gym in the Matina area. Clean, well-equipped, and open 24 hours to accommodate all schedules.',
        categories: [
          'Strength Training',
          'Cardio',
          'Gym',
        ],
        facilities: [
          'Parking',
          'AC',
          'Locker Room',
        ],
        membershipPlans: [
          const MembershipPlan(
            id: 'p1',
            name: 'Basic',
            monthlyPrice: 300,
            features: 'Gym Access Only',
            perks: ['24/7 Access', 'Locker Room'],
          ),
          const MembershipPlan(
            id: 'p2',
            name: 'Premium',
            monthlyPrice: 500,
            features: 'Gym + Group Classes',
            isRecommended: true,
            perks: ['24/7 Access', 'Group Classes', 'Locker Room', 'Parking'],
          ),
          const MembershipPlan(
            id: 'p3',
            name: 'Elite',
            monthlyPrice: 700,
            features: 'Full Access + Trainer',
            perks: [
              '24/7 Access',
              'All Classes',
              'Personal Trainer (1x/mo)',
              'Parking',
            ],
          ),
        ],
        reviews: [
          const ReviewModel(
            id: 'r1',
            userName: 'Leo Ramos',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=30',
            rating: 4,
            comment: 'Super affordable and clean. Best budget gym in Matina!',
            date: '1 week ago',
          ),
        ],
        mapImageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80',
        dailySchedule: const {
          'Monday': '5:00 AM - 12:00 AM',
          'Tuesday': '5:00 AM - 12:00 AM',
          'Wednesday': 'Open 24 Hours',
          'Thursday': '5:00 AM - 12:00 AM',
          'Friday': '5:00 AM - 12:00 AM',
          'Saturday': '5:00 AM - 12:00 AM',
          'Sunday': 'Closed',
        },
        socials: const {
          'Facebook': 'https://facebook.com/gym',
          'Mail': 'contact@gym.com',
          'Website': 'https://gym.com',
        },
        ratingBreakdown: const {
          'Gym': 5.0,
          'Equipment': 4.8,
          'Gym Amenities': 4.5,
        },
      ),
    ];
  }

  // ─── Mock Community Data ────────────────────────────────────────────────────
  List<CommunityModel> fetchCommunities() {
    return [
      const CommunityModel(
        id: 'c1',
        name: 'Hardcore Lifting Squad',
        imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=200&q=80',
        memberCount: 1240,
        description: 'For serious lifters pushing their limits every day.',
      ),
      const CommunityModel(
        id: 'c2',
        name: 'Boutique Collective',
        imageUrl: 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=200&q=80',
        memberCount: 890,
        description: 'Boutique fitness enthusiasts — yoga, pilates, barre.',
      ),
      const CommunityModel(
        id: 'c3',
        name: 'Mindful Movement Spa',
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200&q=80',
        memberCount: 650,
        description: 'Wellness, mindfulness, and recovery focused community.',
      ),
      const CommunityModel(
        id: 'c4',
        name: 'Coming Soon',
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&q=80',
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
