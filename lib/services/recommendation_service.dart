import '../models/gym_model.dart';

/// Result of a Jaccard similarity comparison between user preferences and a gym.
class GymMatchResult {
  final GymModel gym;
  final double jaccardScore;
  final int matchPercentage;
  final List<String> matchedAttributes;
  final List<String> unmatchedAttributes;

  const GymMatchResult({
    required this.gym,
    required this.jaccardScore,
    required this.matchPercentage,
    required this.matchedAttributes,
    required this.unmatchedAttributes,
  });
}

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

  /// Builds the full attribute set for a gym by combining its categories,
  /// facilities, budget range, trainer availability, and distance bracket
  /// into a single normalized (lowercased) set.
  static Set<String> buildGymAttributeSet(GymModel gym) {
    final attrs = <String>{};

    // Categories (e.g., "Strength Training", "General Fitness")
    for (final c in gym.categories) {
      attrs.add('goal:${c.toLowerCase().trim()}');
    }

    // Facilities (e.g., "Free Weights", "Cardio Equipment")
    for (final f in gym.facilities) {
      attrs.add('facility:${f.toLowerCase().trim()}');
    }

    // Budget range — derive from monthlyPrice
    final budgetTag = _deriveBudgetTag(gym.monthlyPrice);
    if (budgetTag != null) {
      attrs.add(budgetTag);
    }

    // Trainer availability — check facilities and description
    final hasTrainer = gym.facilities.any((f) {
      final fl = f.toLowerCase();
      return fl.contains('trainer') || fl.contains('coach') || fl.contains('personal training');
    }) || gym.description.toLowerCase().contains('trainer') ||
       gym.description.toLowerCase().contains('coach');
    if (hasTrainer) {
      attrs.add('trainer:available');
    }

    // Distance bracket
    if (gym.distanceKm > 0) {
      if (gym.distanceKm <= 5) {
        attrs.add('distance:within 5 km');
      } else if (gym.distanceKm <= 10) {
        attrs.add('distance:within 10 km');
      }
      // "Any Distance" always matches, handled in comparison
    }

    // Gym type from categories
    final descLower = gym.description.toLowerCase();
    final nameLower = gym.name.toLowerCase();
    if (descLower.contains('boutique') || descLower.contains('specialty') || nameLower.contains('boutique')) {
      attrs.add('gymtype:boutique / specialty');
    } else if (descLower.contains('private') || descLower.contains('studio') || nameLower.contains('studio')) {
      attrs.add('gymtype:private / studio');
    } else {
      attrs.add('gymtype:commercial gym');
    }

    return attrs;
  }

  /// Derives a budget tag from a gym's monthly price string.
  static String? _deriveBudgetTag(String monthlyPrice) {
    // Extract numeric value from strings like "₱800/month", "₱1,500", etc.
    final cleaned = monthlyPrice.replaceAll(RegExp(r'[₱,\s]'), '');
    final match = RegExp(r'(\d+)').firstMatch(cleaned);
    if (match == null) return null;

    final price = int.tryParse(match.group(1)!);
    if (price == null) return null;

    if (price <= 500) return 'budget:₱0 – ₱500';
    if (price <= 1000) return 'budget:₱501 – ₱1,000';
    if (price <= 1500) return 'budget:₱1,001 – ₱1,500';
    if (price <= 2000) return 'budget:₱1,501 – ₱2,000';
    if (price <= 3000) return 'budget:₱2,001 – ₱3,000';
    return 'budget:₱3,000+';
  }

  /// Normalizes user preferences to lowercase for consistent matching.
  static Set<String> normalizePreferences(List<String> preferences) {
    return preferences.map((p) => p.toLowerCase().trim()).toSet();
  }

  /// Returns a list of gyms with full Jaccard match details, sorted by score.
  ///
  /// Each result includes the gym, its Jaccard score, match percentage,
  /// and lists of matched/unmatched preference attributes.
  static List<GymMatchResult> getRecommendedGymsWithScores({
    required List<String> userPreferences,
    required List<GymModel> allGyms,
    int limit = 10,
  }) {
    if (userPreferences.isEmpty || allGyms.isEmpty) {
      return [];
    }

    final normalizedPrefs = normalizePreferences(userPreferences);

    final results = allGyms.map((gym) {
      final gymAttributes = buildGymAttributeSet(gym);

      // Handle "Any Distance" — if user selected any distance, add whatever distance the gym has
      if (normalizedPrefs.contains('distance:any distance')) {
        // Remove any distance preference from comparison, treat as always matched
      }

      // Handle "Any" gym type — same logic
      if (normalizedPrefs.contains('gymtype:any')) {
        // Treat as always matched
      }

      // Calculate Jaccard similarity
      // For "Any Distance" and "Any" gym type, we adjust the sets
      final adjustedPrefs = Set<String>.from(normalizedPrefs);
      final adjustedGymAttrs = Set<String>.from(gymAttributes);

      // If user selected "Any Distance", remove distance from both sets (always matches)
      if (adjustedPrefs.contains('distance:any distance')) {
        adjustedPrefs.removeWhere((p) => p.startsWith('distance:'));
        adjustedGymAttrs.removeWhere((p) => p.startsWith('distance:'));
      }

      // If user selected "Any" gym type, remove gymtype from both sets
      if (adjustedPrefs.contains('gymtype:any')) {
        adjustedPrefs.removeWhere((p) => p.startsWith('gymtype:'));
        adjustedGymAttrs.removeWhere((p) => p.startsWith('gymtype:'));
      }

      // "No Preference" for trainer — remove trainer from comparison
      if (adjustedPrefs.contains('trainer:no preference')) {
        adjustedPrefs.removeWhere((p) => p.startsWith('trainer:'));
        adjustedGymAttrs.removeWhere((p) => p.startsWith('trainer:'));
      }

      final score = jaccardSimilarity(adjustedPrefs, adjustedGymAttrs);

      // Determine matched and unmatched attributes (using user's original prefs)
      final matched = <String>[];
      final unmatched = <String>[];

      for (final pref in normalizedPrefs) {
        // Check for direct match
        if (gymAttributes.contains(pref)) {
          matched.add(pref);
        } else if (pref == 'distance:any distance' || pref == 'gymtype:any' || pref == 'trainer:no preference') {
          matched.add(pref); // "Any" options always match
        } else if (pref.startsWith('distance:within')) {
          // Check if gym distance falls within the user's preference
          final kmMatch = RegExp(r'(\d+)').firstMatch(pref);
          if (kmMatch != null) {
            final maxKm = double.parse(kmMatch.group(1)!);
            if (gym.distanceKm > 0 && gym.distanceKm <= maxKm) {
              matched.add(pref);
            } else {
              unmatched.add(pref);
            }
          }
        } else {
          unmatched.add(pref);
        }
      }

      return GymMatchResult(
        gym: gym,
        jaccardScore: score,
        matchPercentage: (score * 100).round(),
        matchedAttributes: matched,
        unmatchedAttributes: unmatched,
      );
    }).toList();

    // Filter out gyms with 0 score (no match at all)
    final filteredResults = results.where((r) => r.jaccardScore > 0.0).toList();

    // Sort by score descending, then by rating for ties
    filteredResults.sort((a, b) {
      final scoreCompare = b.jaccardScore.compareTo(a.jaccardScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.gym.rating.compareTo(a.gym.rating);
    });

    return filteredResults.take(limit).toList();
  }

  /// Legacy method — returns gyms without scores for backward compatibility.
  static List<GymModel> getRecommendedGyms({
    required List<String> userPreferences,
    required List<GymModel> allGyms,
    int limit = 5,
  }) {
    final results = getRecommendedGymsWithScores(
      userPreferences: userPreferences,
      allGyms: allGyms,
      limit: limit,
    );
    return results.map((r) => r.gym).toList();
  }
}
