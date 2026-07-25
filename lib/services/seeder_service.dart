import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/secure_logger.dart';
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
    } catch (e) {
      SecureLogger.logError('Error seeding database', e);
    }
  }
}
