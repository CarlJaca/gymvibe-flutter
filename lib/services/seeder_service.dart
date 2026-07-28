import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/secure_logger.dart';
import '../models/job_posting_model.dart';
import '../models/leaderboard_model.dart';
import '../providers/calendar_provider.dart';
import 'gym_service.dart';

class FirebaseSeeder {
  static Future<void> seedDatabase() async {
    SecureLogger.log('--- SEEDING DATABASE ---');
    try {
      final firestore = FirebaseFirestore.instance;
      final gyms = GymService.instance.fetchGyms();
      
      final batch = firestore.batch();
      
      for (final gym in gyms) {
        final docRef = firestore.collection('gyms').doc(gym.id);
        batch.set(docRef, gym.toJson());
      }
      
      await batch.commit();
      SecureLogger.log('Successfully seeded ${gyms.length} gyms to Firestore.');

      // Seed additional collections
      await _seedJobPostings(firestore);
      await _seedCalendarData(firestore);
      await _seedLeaderboardData(firestore);
      await _seedCommunityData(firestore);
      await _seedEventsData(firestore);
      await _seedPromotionsData(firestore);
    } catch (e) {
      SecureLogger.logError('Error seeding database', e);
    }
  }

  // ─── Job Postings ─────────────────────────────────────────────────────────────
  static Future<void> _seedJobPostings(FirebaseFirestore firestore) async {
    try {
      // Check if job postings already exist
      final existing = await firestore.collection('jobPostings').limit(1).get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Job postings already seeded — skipping.');
        return;
      }

      final now = DateTime.now();
      final jobPostings = <JobPostingModel>[
        JobPostingModel(
          jobId: 'job_seed_1',
          gymId: '1',
          ownerId: 'owner_seed_1',
          gymName: 'Dstar Gym Matina',
          gymLogoUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&q=80',
          jobTitle: 'Certified Personal Trainer',
          jobCategory: 'Personal Trainer',
          employmentType: EmploymentType.fullTime,
          workSetup: WorkSetup.onsite,
          location: 'Matina, Davao City',
          description:
              'We are looking for a passionate and certified personal trainer to join our growing team at Dstar Gym Matina. You will work one-on-one with clients to develop and implement personalized fitness plans.',
          responsibilities: [
            'Create customized workout programs for clients',
            'Conduct fitness assessments and track client progress',
            'Ensure proper form and technique during exercises',
            'Motivate and encourage clients to reach their fitness goals',
            'Maintain a clean and safe workout environment',
          ],
          qualifications: [
            'NCCA-accredited personal training certification',
            'At least 1 year of personal training experience',
            'Strong communication and interpersonal skills',
            'CPR/AED certified',
          ],
          requiredSkills: ['Strength Training', 'Nutrition', 'Client Assessment', 'Program Design'],
          salaryType: SalaryType.range,
          minimumSalary: 15000,
          maximumSalary: 25000,
          salaryPeriod: SalaryPeriod.monthly,
          benefits: ['Free Gym Access', 'Commission on PT Sessions', 'Health Insurance', 'Uniform Provided'],
          numberOfOpenings: 2,
          applicationDeadline: now.add(const Duration(days: 30)),
          status: JobStatus.active,
          applicationCount: 0,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        JobPostingModel(
          jobId: 'job_seed_2',
          gymId: '4',
          ownerId: 'owner_seed_2',
          gymName: 'Elevation Gym Buhangin',
          gymLogoUrl: 'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?w=200&q=80',
          jobTitle: 'Group Fitness Instructor',
          jobCategory: 'Group Class Instructor',
          employmentType: EmploymentType.partTime,
          workSetup: WorkSetup.onsite,
          location: 'Buhangin, Davao City',
          description:
              'Elevation Gym is seeking an energetic Group Fitness Instructor to lead high-energy classes including HIIT, Zumba, and Circuit Training. Ideal for someone who thrives in a group setting.',
          responsibilities: [
            'Lead group fitness classes (HIIT, Zumba, Circuit Training)',
            'Design creative and challenging class routines',
            'Ensure participant safety and proper form',
            'Manage class schedules and attendance',
            'Provide modifications for different fitness levels',
          ],
          qualifications: [
            'Group fitness certification preferred',
            'Experience leading group classes',
            'High energy and motivational personality',
          ],
          requiredSkills: ['Group Fitness', 'HIIT', 'Zumba', 'Circuit Training'],
          salaryType: SalaryType.fixed,
          minimumSalary: 500,
          salaryPeriod: SalaryPeriod.daily,
          benefits: ['Free Gym Access', 'Flexible Schedule', 'Performance Bonuses'],
          numberOfOpenings: 1,
          applicationDeadline: now.add(const Duration(days: 21)),
          status: JobStatus.active,
          applicationCount: 0,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        JobPostingModel(
          jobId: 'job_seed_3',
          gymId: '2',
          ownerId: 'owner_seed_3',
          gymName: 'Ultradynamic Gym Buhangin',
          gymLogoUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200&q=80',
          jobTitle: 'Front Desk Receptionist',
          jobCategory: 'Receptionist',
          employmentType: EmploymentType.fullTime,
          workSetup: WorkSetup.onsite,
          location: 'Buhangin, Davao City',
          description:
              'Join Ultradynamic Gym as our friendly front desk receptionist. You will be the first point of contact for all members and guests, handling inquiries, memberships, and scheduling.',
          responsibilities: [
            'Greet members and guests with a warm, professional attitude',
            'Handle membership sign-ups, renewals, and cancellations',
            'Answer phone calls and respond to email inquiries',
            'Manage the booking and scheduling system',
            'Keep the front desk area clean and organized',
          ],
          qualifications: [
            'High school diploma or equivalent',
            'Previous customer service experience preferred',
            'Proficient in basic computer applications',
            'Friendly, approachable demeanor',
          ],
          requiredSkills: ['Customer Service', 'Communication', 'Computer Skills', 'Organization'],
          salaryType: SalaryType.fixed,
          minimumSalary: 12000,
          salaryPeriod: SalaryPeriod.monthly,
          benefits: ['Free Gym Access', 'Paid Holidays', 'Uniform Provided'],
          numberOfOpenings: 1,
          applicationDeadline: now.add(const Duration(days: 14)),
          status: JobStatus.active,
          applicationCount: 0,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        JobPostingModel(
          jobId: 'job_seed_4',
          gymId: '5',
          ownerId: 'owner_seed_4',
          gymName: 'The Metro Fitness & Family Gym',
          gymLogoUrl: 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=200&q=80',
          jobTitle: 'Gym Maintenance Staff',
          jobCategory: 'Maintenance Staff',
          employmentType: EmploymentType.fullTime,
          workSetup: WorkSetup.onsite,
          location: 'Ecoland, Davao City',
          description:
              'Metro Fitness is hiring a dedicated Maintenance Staff member to ensure our facility is always in top condition. Responsibilities include equipment maintenance, cleaning, and minor repairs.',
          responsibilities: [
            'Perform daily equipment inspections and basic maintenance',
            'Keep all gym areas clean and sanitized',
            'Report and coordinate major equipment repairs',
            'Assist with facility setup for events and classes',
            'Manage inventory of cleaning supplies',
          ],
          qualifications: [
            'Experience in facility maintenance preferred',
            'Basic knowledge of gym equipment',
            'Physical fitness to handle manual tasks',
            'Reliable and punctual',
          ],
          requiredSkills: ['Equipment Maintenance', 'Cleaning', 'Organization', 'Reliability'],
          salaryType: SalaryType.fixed,
          minimumSalary: 10000,
          salaryPeriod: SalaryPeriod.monthly,
          benefits: ['Free Gym Access', 'Meal Allowance', 'Overtime Pay'],
          numberOfOpenings: 1,
          applicationDeadline: now.add(const Duration(days: 45)),
          status: JobStatus.active,
          applicationCount: 0,
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        JobPostingModel(
          jobId: 'job_seed_5',
          gymId: '6',
          ownerId: 'owner_seed_5',
          gymName: 'Dallas Gym Matina',
          gymLogoUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=200&q=80',
          jobTitle: 'Social Media Manager (Part-Time)',
          jobCategory: 'Social Media Assistant',
          employmentType: EmploymentType.partTime,
          workSetup: WorkSetup.hybrid,
          location: 'Matina, Davao City',
          description:
              'Dallas Gym is looking for a creative Social Media Manager to grow our online presence. You will create engaging content, manage our social accounts, and help attract new members through digital marketing.',
          responsibilities: [
            'Create and schedule social media content (photos, reels, stories)',
            'Manage Facebook, Instagram, and TikTok accounts',
            'Respond to comments and messages promptly',
            'Track social media analytics and report growth metrics',
            'Collaborate with trainers for content creation',
          ],
          qualifications: [
            'Experience managing social media accounts',
            'Knowledge of fitness/gym industry is a plus',
            'Creative with strong visual design sense',
            'Basic photo and video editing skills',
          ],
          requiredSkills: ['Social Media', 'Content Creation', 'Photography', 'Video Editing', 'Marketing'],
          salaryType: SalaryType.negotiable,
          benefits: ['Free Gym Access', 'Flexible Working Hours', 'Work From Home Options'],
          numberOfOpenings: 1,
          applicationDeadline: now.add(const Duration(days: 60)),
          status: JobStatus.active,
          applicationCount: 0,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final batch = firestore.batch();
      for (final job in jobPostings) {
        final docRef = firestore.collection('jobPostings').doc(job.jobId);
        batch.set(docRef, job.toJson());
      }
      await batch.commit();
      SecureLogger.log('Successfully seeded ${jobPostings.length} job postings.');
    } catch (e) {
      SecureLogger.logError('Error seeding job postings', e);
    }
  }

  // ─── Workout Calendar ─────────────────────────────────────────────────────────
  static Future<void> _seedCalendarData(FirebaseFirestore firestore) async {
    try {
      // We'll seed sample calendar data for a demo user
      // The calendar is per-user so we use a well-known demo user ID
      const demoUserId = 'demo_user_calendar';

      // Check if already seeded
      final existing = await firestore
          .collection('users')
          .doc(demoUserId)
          .collection('workoutCalendar')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Calendar data already seeded — skipping.');
        return;
      }

      final now = DateTime.now();
      final batch = firestore.batch();
      int count = 0;

      // Seed the current month with a realistic workout schedule
      final workoutPlan = <int, List<Map<String, dynamic>>>{
        // Week 1
        1: [
          {'id': 'cal_1_1', 'type': WorkoutType.chestDay.name, 'notes': 'Bench press 4x8, incline dumbbell press 3x10, cable flyes 3x12'},
        ],
        2: [
          {'id': 'cal_2_1', 'type': WorkoutType.cardioDay.name, 'notes': '30 min treadmill, 15 min stair climber'},
        ],
        3: [
          {'id': 'cal_3_1', 'type': WorkoutType.backDay.name, 'notes': 'Deadlift 5x5, barbell rows 4x8, lat pulldowns 3x12'},
        ],
        4: [
          {'id': 'cal_4_1', 'type': WorkoutType.restDay.name, 'notes': 'Active recovery — light stretching'},
        ],
        5: [
          {'id': 'cal_5_1', 'type': WorkoutType.legDay.name, 'notes': 'Squat 5x5, leg press 4x10, leg curls 3x12, calf raises 4x15'},
        ],
        // Week 2
        7: [
          {'id': 'cal_7_1', 'type': WorkoutType.strengthTraining.name, 'notes': 'Full body compound lifts — squat, bench, deadlift'},
        ],
        8: [
          {'id': 'cal_8_1', 'type': WorkoutType.cardioDay.name, 'notes': '20 min HIIT session + abs'},
        ],
        9: [
          {'id': 'cal_9_1', 'type': WorkoutType.chestDay.name, 'notes': 'Dumbbell press 4x10, push-ups 3xFailure, pec deck 3x12'},
        ],
        10: [
          {'id': 'cal_10_1', 'type': WorkoutType.gymSession.name, 'notes': 'Open gym — worked on weak points'},
        ],
        11: [
          {'id': 'cal_11_1', 'type': WorkoutType.restDay.name, 'notes': ''},
        ],
        12: [
          {'id': 'cal_12_1', 'type': WorkoutType.backDay.name, 'notes': 'Pull-ups 4xMax, seated rows 4x10, face pulls 3x15'},
        ],
        // Week 3
        14: [
          {'id': 'cal_14_1', 'type': WorkoutType.legDay.name, 'notes': 'Front squat 4x8, Romanian deadlift 4x10, lunges 3x12 each leg'},
        ],
        15: [
          {'id': 'cal_15_1', 'type': WorkoutType.cardioDay.name, 'notes': '40 min cycling + stretching'},
        ],
        16: [
          {'id': 'cal_16_1', 'type': WorkoutType.chestDay.name, 'notes': 'Chest day — progressive overload on bench press'},
        ],
        17: [
          {'id': 'cal_17_1', 'type': WorkoutType.strengthTraining.name, 'notes': 'Olympic lifts — clean and jerk practice'},
        ],
        18: [
          {'id': 'cal_18_1', 'type': WorkoutType.restDay.name, 'notes': 'Rest day — massage and foam rolling'},
        ],
        // Week 4
        21: [
          {'id': 'cal_21_1', 'type': WorkoutType.backDay.name, 'notes': 'Heavy deadlift day — working up to 1RM attempt'},
        ],
        22: [
          {'id': 'cal_22_1', 'type': WorkoutType.cardioDay.name, 'notes': 'Swimming 45 min'},
        ],
        23: [
          {'id': 'cal_23_1', 'type': WorkoutType.legDay.name, 'notes': 'Squat PR attempt + accessory work'},
        ],
        24: [
          {'id': 'cal_24_1', 'type': WorkoutType.gymSession.name, 'notes': 'Arms and shoulders — dumbbell circuit'},
        ],
        25: [
          {'id': 'cal_25_1', 'type': WorkoutType.restDay.name, 'notes': ''},
        ],
      };

      for (final entry in workoutPlan.entries) {
        final day = entry.key;
        final activities = entry.value;

        // Only seed days that exist in the current month
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        if (day > daysInMonth) continue;

        final dateKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        final docRef = firestore
            .collection('users')
            .doc(demoUserId)
            .collection('workoutCalendar')
            .doc(dateKey);

        batch.set(docRef, {'activities': activities});
        count++;
      }

      await batch.commit();
      SecureLogger.log('Successfully seeded $count calendar entries.');
    } catch (e) {
      SecureLogger.logError('Error seeding calendar data', e);
    }
  }

  // ─── Leaderboard (Personal Records) ────────────────────────────────────────────
  static Future<void> _seedLeaderboardData(FirebaseFirestore firestore) async {
    try {
      // Seed personal records under gym '4' (Elevation Gym Buhangin — the powerlifting gym)
      const targetGymId = '4';

      // Check if already seeded
      final existing = await firestore
          .collection('gyms')
          .doc(targetGymId)
          .collection('personalRecords')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Leaderboard data already seeded — skipping.');
        return;
      }

      final records = <PersonalRecord>[
        // ── Deadlift ──
        const PersonalRecord(
          id: 'pr_dl_1',
          userId: 'user_seed_1',
          userName: 'Jeffrey Caman',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
          gymId: targetGymId,
          category: LeaderboardCategory.deadlift,
          weight: 220.0,
          date: '2026-07-15',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dl_2',
          userId: 'user_seed_2',
          userName: 'Renz Gultiano',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=16',
          gymId: targetGymId,
          category: LeaderboardCategory.deadlift,
          weight: 200.0,
          date: '2026-07-18',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dl_3',
          userId: 'user_seed_3',
          userName: 'Carlos Mendoza',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
          gymId: targetGymId,
          category: LeaderboardCategory.deadlift,
          weight: 185.0,
          date: '2026-07-20',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dl_4',
          userId: 'user_seed_4',
          userName: 'Miguel Torres',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=11',
          gymId: targetGymId,
          category: LeaderboardCategory.deadlift,
          weight: 175.0,
          date: '2026-07-22',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dl_5',
          userId: 'user_seed_5',
          userName: 'Leo Ramos',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=30',
          gymId: targetGymId,
          category: LeaderboardCategory.deadlift,
          weight: 160.0,
          date: '2026-07-25',
          status: RecordStatus.pending,
        ),

        // ── Bench Press ──
        const PersonalRecord(
          id: 'pr_bp_1',
          userId: 'user_seed_2',
          userName: 'Renz Gultiano',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=16',
          gymId: targetGymId,
          category: LeaderboardCategory.benchPress,
          weight: 140.0,
          date: '2026-07-16',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_bp_2',
          userId: 'user_seed_1',
          userName: 'Jeffrey Caman',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
          gymId: targetGymId,
          category: LeaderboardCategory.benchPress,
          weight: 130.0,
          date: '2026-07-17',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_bp_3',
          userId: 'user_seed_6',
          userName: 'Cha Bautista',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=20',
          gymId: targetGymId,
          category: LeaderboardCategory.benchPress,
          weight: 80.0,
          date: '2026-07-19',
          status: RecordStatus.verified,
        ),

        // ── Squat ──
        const PersonalRecord(
          id: 'pr_sq_1',
          userId: 'user_seed_1',
          userName: 'Jeffrey Caman',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
          gymId: targetGymId,
          category: LeaderboardCategory.squat,
          weight: 200.0,
          date: '2026-07-14',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_sq_2',
          userId: 'user_seed_3',
          userName: 'Carlos Mendoza',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
          gymId: targetGymId,
          category: LeaderboardCategory.squat,
          weight: 180.0,
          date: '2026-07-21',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_sq_3',
          userId: 'user_seed_4',
          userName: 'Miguel Torres',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=11',
          gymId: targetGymId,
          category: LeaderboardCategory.squat,
          weight: 170.0,
          date: '2026-07-23',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_sq_4',
          userId: 'user_seed_2',
          userName: 'Renz Gultiano',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=16',
          gymId: targetGymId,
          category: LeaderboardCategory.squat,
          weight: 165.0,
          date: '2026-07-24',
          status: RecordStatus.pending,
        ),

        // ── Overhead Press ──
        const PersonalRecord(
          id: 'pr_op_1',
          userId: 'user_seed_2',
          userName: 'Renz Gultiano',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=16',
          gymId: targetGymId,
          category: LeaderboardCategory.overheadPress,
          weight: 90.0,
          date: '2026-07-18',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_op_2',
          userId: 'user_seed_1',
          userName: 'Jeffrey Caman',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
          gymId: targetGymId,
          category: LeaderboardCategory.overheadPress,
          weight: 85.0,
          date: '2026-07-20',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_op_3',
          userId: 'user_seed_3',
          userName: 'Carlos Mendoza',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
          gymId: targetGymId,
          category: LeaderboardCategory.overheadPress,
          weight: 75.0,
          date: '2026-07-22',
          status: RecordStatus.verified,
        ),

        // ── Dumbbell Curl ──
        const PersonalRecord(
          id: 'pr_dc_1',
          userId: 'user_seed_3',
          userName: 'Carlos Mendoza',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
          gymId: targetGymId,
          category: LeaderboardCategory.dumbbellCurl,
          weight: 30.0,
          date: '2026-07-17',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dc_2',
          userId: 'user_seed_1',
          userName: 'Jeffrey Caman',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=15',
          gymId: targetGymId,
          category: LeaderboardCategory.dumbbellCurl,
          weight: 27.5,
          date: '2026-07-19',
          status: RecordStatus.verified,
        ),
        const PersonalRecord(
          id: 'pr_dc_3',
          userId: 'user_seed_6',
          userName: 'Cha Bautista',
          userAvatarUrl: 'https://i.pravatar.cc/150?img=20',
          gymId: targetGymId,
          category: LeaderboardCategory.dumbbellCurl,
          weight: 20.0,
          date: '2026-07-21',
          status: RecordStatus.verified,
        ),
      ];

      final batch = firestore.batch();
      for (final record in records) {
        final docRef = firestore
            .collection('gyms')
            .doc(targetGymId)
            .collection('personalRecords')
            .doc(record.id);
        batch.set(docRef, record.toJson());
      }
      await batch.commit();
      SecureLogger.log('Successfully seeded ${records.length} leaderboard records.');
    } catch (e) {
      SecureLogger.logError('Error seeding leaderboard data', e);
    }
  }

  // ─── Community Data ─────────────────────────────────────────────────────────
  static Future<void> _seedCommunityData(FirebaseFirestore firestore) async {
    try {
      final existing = await firestore.collection('communities').limit(1).get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Community data already seeded — skipping.');
        return;
      }

      final now = DateTime.now();
      final batch = firestore.batch();

      // Seed Communities
      final communities = [
        {
          'id': 'comm_1',
          'name': 'Davao Powerlifters',
          'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&q=80',
          'memberCount': 342,
          'isComingSoon': false,
          'description': 'A community for powerlifting enthusiasts in Davao City.',
        },
        {
          'id': 'comm_2',
          'name': 'HIIT & Cardio Davao',
          'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=200&q=80',
          'memberCount': 891,
          'isComingSoon': false,
          'description': 'Cardio, HIIT, and endurance training group.',
        },
        {
          'id': 'comm_3',
          'name': 'Yoga & Wellness',
          'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200&q=80',
          'memberCount': 0,
          'isComingSoon': true,
          'description': 'Find your zen with our yoga and wellness community.',
        },
      ];

      for (var comm in communities) {
        final docRef = firestore.collection('communities').doc(comm['id'] as String);
        batch.set(docRef, comm);
      }

      // Seed Posts
      final posts = [
        {
          'id': 'post_1',
          'userId': 'user_seed_1',
          'userName': 'Jeffrey Caman',
          'userAvatarUrl': 'https://i.pravatar.cc/150?img=15',
          'userLocation': 'Davao City',
          'communityId': 'comm_1',
          'communityName': 'Davao Powerlifters',
          'caption': 'Hit a new PR on deadlifts today! 220kg felt smooth! 💪🔥',
          'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&q=80',
          'likeCount': 45,
          'commentCount': 12,
          'likedBy': [],
          'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'post_2',
          'userId': 'user_seed_2',
          'userName': 'Sarah Mendoza',
          'userAvatarUrl': 'https://i.pravatar.cc/150?img=9',
          'userLocation': 'Davao City',
          'communityId': 'comm_2',
          'communityName': 'HIIT & Cardio Davao',
          'caption': 'Morning run done! 5km before breakfast. Who else is up early?',
          'imageUrl': null,
          'likeCount': 120,
          'commentCount': 34,
          'likedBy': [],
          'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ];

      for (var post in posts) {
        final docRef = firestore.collection('posts').doc(post['id'] as String);
        batch.set(docRef, post);
      }

      await batch.commit();
      SecureLogger.log('Successfully seeded community data.');
    } catch (e) {
      SecureLogger.logError('Error seeding community data', e);
    }
  }

  // ─── Events Data ────────────────────────────────────────────────────────────
  static Future<void> _seedEventsData(FirebaseFirestore firestore) async {
    try {
      final existing = await firestore.collection('events').limit(1).get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Events data already seeded — skipping.');
        return;
      }

      final batch = firestore.batch();

      final events = [
        {
          'id': 'evt_1',
          'title': 'Summer Slimdown Challenge',
          'gymName': 'Dstar Gym Matina',
          'date': 'May 25, 2025',
          'time': '8:00 AM - 10:00 AM',
          'location': 'Matina, Davao City',
          'type': 'Competition',
          'status': 'Upcoming', // Active, Upcoming, Inactive, Past
          'isFeatured': true,
          'isSaved': false,
          'hasReminder': true,
          'imageUrl': 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=400&q=80',
          'description': 'Join us for a 4-week summer fitness challenge. Top 3 transformations win free supplements!',
          'price': '₱500',
          'attendees': 24,
          'maxAttendees': 50,
        },
        {
          'id': 'evt_2',
          'title': 'Davao Powerlifting Meet',
          'gymName': 'Elevation Gym Buhangin',
          'date': 'Jul 15, 2025',
          'time': '9:00 AM - 4:00 PM',
          'location': 'Buhangin, Davao City',
          'type': 'Meet',
          'status': 'Upcoming',
          'isFeatured': false,
          'isSaved': true,
          'hasReminder': false,
          'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80',
          'description': 'Annual powerlifting meet for all weight classes. Register early to secure your spot!',
          'price': '₱1500',
          'attendees': 45,
          'maxAttendees': 100,
        },
      ];

      for (var evt in events) {
        final docRef = firestore.collection('events').doc(evt['id'] as String);
        batch.set(docRef, evt);
      }

      await batch.commit();
      SecureLogger.log('Successfully seeded events data.');
    } catch (e) {
      SecureLogger.logError('Error seeding events data', e);
    }
  }

  // ─── Promotions Data ────────────────────────────────────────────────────────
  static Future<void> _seedPromotionsData(FirebaseFirestore firestore) async {
    try {
      final existing = await firestore.collection('promotions').limit(1).get();
      if (existing.docs.isNotEmpty) {
        SecureLogger.log('Promotions data already seeded — skipping.');
        return;
      }

      final batch = firestore.batch();

      final promotions = [
        {
          'id': 'promo_1',
          'title': '20% Off Annual Membership',
          'dates': 'Valid until Aug 30, 2025',
          'type': 'Discount',
          'status': 'Active', // Active, Scheduled, Paused, Expired
          'color': 0xFFE91E63, // Pink
          'isClaimed': false,
          'claimedCount': 120,
          'code': 'SUMMER20',
          'description': 'Get 20% off when you sign up for our annual membership plan. Valid for new members only.',
        },
        {
          'id': 'promo_2',
          'title': 'Free 1-on-1 PT Session',
          'dates': 'Valid until Sep 15, 2025',
          'type': 'Freebie',
          'status': 'Active',
          'color': 0xFF4CAF50, // Green
          'isClaimed': true,
          'claimedCount': 45,
          'code': 'FREETRAIN',
          'description': 'Claim one free personal training session to jumpstart your fitness journey.',
        },
        {
          'id': 'promo_3',
          'title': 'Buy 1 Take 1 Protein Shake',
          'dates': 'Every Friday in July',
          'type': 'Special',
          'status': 'Active',
          'color': 0xFFFF9800, // Orange
          'isClaimed': false,
          'claimedCount': 89,
          'code': 'SHAKEFRIDAY',
          'description': 'Cool down with our buy 1 take 1 promo on all protein shakes at the gym bar.',
        },
      ];

      for (var promo in promotions) {
        final docRef = firestore.collection('promotions').doc(promo['id'] as String);
        batch.set(docRef, promo);
      }

      await batch.commit();
      SecureLogger.log('Successfully seeded promotions data.');
    } catch (e) {
      SecureLogger.logError('Error seeding promotions data', e);
    }
  }
}
