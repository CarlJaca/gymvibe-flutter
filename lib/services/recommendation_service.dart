import '../models/gym_model.dart';

/// A recommendation engine using the Jaccard Similarity Index to rank gyms
/// based on how well they match a user's fitness preferences.
///
/// Jaccard Index = |A ∩ B| / |A ∪ B|
/// where A = user's preference set, B = gym's attribute set.
/// Score ranges from 0.0 (no overlap) to 1.0 (perfect match).
class RecommendationService {
  RecommendationService._();

  /// Computes the Jaccard Similarity Index between two sets.
  ///
  /// Returns a value between 0.0 and 1.0.
  /// Returns 0.0 if both sets are empty.
  static double jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0.0;

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;

    return intersection / union;
  }

  /// Builds the full attribute set for a gym by combining its categories
  /// and facilities into a single normalized (lowercased) set.
  static Set<String> _buildGymAttributeSet(GymModel gym) {
    return {
      ...gym.categories.map((c) => c.toLowerCase().trim()),
      ...gym.facilities.map((f) => f.toLowerCase().trim()),
    };
  }

  /// Normalizes user preferences to lowercase for consistent matching.
  static Set<String> _normalizePreferences(List<String> preferences) {
    return preferences.map((p) => p.toLowerCase().trim()).toSet();
  }

  /// Returns a list of gyms ranked by their Jaccard similarity to the
  /// user's preferences.
  ///
  /// - [userPreferences]: The user's selected fitness preferences
  ///   (e.g., ['Free Weights', 'Parking', 'Boxing']).
  /// - [allGyms]: The full list of available gyms.
  /// - [limit]: Maximum number of gyms to return (default: 5).
  ///
  /// Gyms are sorted by Jaccard score descending. Ties are broken by
  /// gym rating (higher first). Gyms with a score of 0.0 are still
  /// included but ranked last.
  static List<GymModel> getRecommendedGyms({
    required List<String> userPreferences,
    required List<GymModel> allGyms,
    int limit = 5,
  }) {
    if (userPreferences.isEmpty || allGyms.isEmpty) {
      return allGyms.take(limit).toList();
    }

    final normalizedPrefs = _normalizePreferences(userPreferences);

    // Calculate Jaccard score for each gym
    final scoredGyms = allGyms.map((gym) {
      final gymAttributes = _buildGymAttributeSet(gym);
      final score = jaccardSimilarity(normalizedPrefs, gymAttributes);
      return _ScoredGym(gym: gym, score: score);
    }).toList();

    // Sort by score descending, then by rating descending for ties
    scoredGyms.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.gym.rating.compareTo(a.gym.rating);
    });

    return scoredGyms.take(limit).map((sg) => sg.gym).toList();
  }
}

/// Internal helper to pair a gym with its computed Jaccard score.
class _ScoredGym {
  final GymModel gym;
  final double score;

  const _ScoredGym({required this.gym, required this.score});
}
