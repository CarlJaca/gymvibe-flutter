import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/gym_model.dart';

/// Repository that loads the 15 real Davao City gym records from
/// the bundled JSON asset. Singleton — call [GymRepository.instance].
class GymRepository {
  GymRepository._();
  static final GymRepository instance = GymRepository._();

  List<GymModel>? _cachedGyms;

  /// Loads and caches all 15 gyms from assets/data/davao_gyms.json.
  Future<List<GymModel>> loadAll() async {
    if (_cachedGyms != null) return _cachedGyms!;

    final jsonString =
        await rootBundle.loadString('assets/data/davao_gyms.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedGyms = jsonList
        .map((e) => GymModel.fromDatasetJson(e as Map<String, dynamic>))
        .toList();

    // Assert unique IDs
    final ids = _cachedGyms!.map((g) => g.id).toSet();
    assert(ids.length == _cachedGyms!.length,
        'Duplicate gym IDs detected in dataset');

    return _cachedGyms!;
  }

  /// Returns only gyms that are eligible for exact map pins.
  Future<List<GymModel>> loadPinned() async {
    final all = await loadAll();
    return all.where((g) => g.canShowExactMapPin).toList();
  }

  /// Returns all gyms that have a valid map marker (exact or building-level).
  Future<List<GymModel>> loadMappable() async {
    final all = await loadAll();
    return all.where((g) => g.canShowMapMarker).toList();
  }

  /// Clears the cache (useful for testing).
  void clearCache() {
    _cachedGyms = null;
  }
}
