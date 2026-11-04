import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymvibe/models/gym_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<GymModel> gyms;

  setUpAll(() async {
    // Load the bundled JSON asset
    final jsonString =
        await rootBundle.loadString('assets/data/davao_gyms.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    gyms = jsonList
        .map((e) => GymModel.fromDatasetJson(e as Map<String, dynamic>))
        .toList();
  });

  group('Dataset Loading', () {
    test('loads exactly 15 gym records', () {
      expect(gyms.length, 15);
    });

    test('all gyms have unique IDs', () {
      final ids = gyms.map((g) => g.id).toSet();
      expect(ids.length, 15);
    });

    test('all IDs are slug format (lowercase, hyphens, no special chars)', () {
      for (final gym in gyms) {
        expect(gym.id, matches(RegExp(r'^[a-z0-9-]+$')),
            reason: '${gym.name} has invalid ID: ${gym.id}');
      }
    });

    test('all gyms have non-empty name, branch, address, district', () {
      for (final gym in gyms) {
        expect(gym.name.isNotEmpty, true,
            reason: 'Gym ${gym.id} has empty name');
        expect(gym.branch.isNotEmpty, true,
            reason: 'Gym ${gym.id} has empty branch');
        expect(gym.address.isNotEmpty, true,
            reason: 'Gym ${gym.id} has empty address');
        expect(gym.district.isNotEmpty, true,
            reason: 'Gym ${gym.id} has empty district');
      }
    });

    test('districts are within Matina, Ecoland, Talomo, or Bangkal', () {
      final validDistricts = {'matina', 'ecoland', 'talomo', 'bangkal'};
      for (final gym in gyms) {
        expect(validDistricts.contains(gym.district.toLowerCase()), true,
            reason: '${gym.name} has unexpected district: ${gym.district}');
      }
    });
  });

  group('Phone Numbers', () {
    test('all phones are String type and start with 0', () {
      for (final gym in gyms) {
        if (gym.phone.isNotEmpty) {
          expect(gym.phone.startsWith('0'), true,
              reason: '${gym.name} phone does not start with 0: ${gym.phone}');
        }
      }
    });

    test('phone strings preserved with leading zero', () {
      // Verify the phone is not parsed as int (which would drop leading 0)
      final dstarsMatina = gyms.firstWhere(
          (g) => g.id.contains('dstars') && g.id.contains('matina'));
      expect(dstarsMatina.phone, '09209787878');
    });
  });

  group('Coordinate Validation', () {
    test('coordinates within Davao City range when present', () {
      for (final gym in gyms) {
        if (gym.latitude != null) {
          expect(gym.latitude!, inInclusiveRange(6.9, 7.5),
              reason: '${gym.name} latitude out of range: ${gym.latitude}');
        }
        if (gym.longitude != null) {
          expect(gym.longitude!, inInclusiveRange(125.2, 125.8),
              reason: '${gym.name} longitude out of range: ${gym.longitude}');
        }
      }
    });

    test('no duplicate coordinates for different gyms', () {
      final coordGyms = gyms.where((g) => g.hasCoordinates).toList();
      for (int i = 0; i < coordGyms.length; i++) {
        for (int j = i + 1; j < coordGyms.length; j++) {
          final a = coordGyms[i];
          final b = coordGyms[j];
          final sameCoord =
              a.latitude == b.latitude && a.longitude == b.longitude;
          expect(sameCoord, false,
              reason:
                  '${a.name} (${a.branch}) and ${b.name} (${b.branch}) share coordinates');
        }
      }
    });

    test('canShowExactMapPin count equals 10 (from verification audit)', () {
      final pinned = gyms.where((g) => g.canShowExactMapPin).toList();
      expect(pinned.length, 10,
          reason: 'Expected 10 exact-pin gyms, got ${pinned.length}: '
              '${pinned.map((g) => '${g.name} (${g.branch})').join(', ')}');
    });

    test('exact-pin gyms include all 10 verified branches', () {
      final pinnedIds =
          gyms.where((g) => g.canShowExactMapPin).map((g) => g.id).toSet();
      expect(
          pinnedIds,
          containsAll([
            'dstars-fitness-gym-matina',
            'beefit-gym-matina',
            'crossfit-madayaw-south',
            'strive-fitness-davao-main',
            'elorde-davao-main',
            'clutchlab-fitness-gym-main',
            'dstars-fitness-gym-ecoland',
            'elevation-fitness-gym-ecoland',
            'arcadia-fitness-gym-arcadia-active-lifestyle-center',
            'garage-fitness-compound-main',
          ]));
    });

    test('has_verified_map_point false for approximate/unverified pins', () {
      // Anytime Fitness (Derived, mall building), Ultradynamic (Derived, Plus Code center)
      // Continental Prime, Kilo Culture, Dstars Ma-a — no verified pin
      final unverifiedIds = [
        'anytime-fitness-sm-city-ecoland-the-annex',
        'ultradynamic-fitness-gym-prime-bangkal-talomo',
        'continental-prime-fitness-gym-juna-subdivision',
        'kilo-culture-main',
        'dstars-fitness-gym-ma-a',
      ];
      for (final id in unverifiedIds) {
        final gym = gyms.firstWhere((g) => g.id == id,
            orElse: () => throw StateError('Gym $id not found'));
        expect(gym.hasVerifiedMapPoint, false,
            reason:
                '${gym.name} (${gym.branch}) should not have verified map point');
      }
      // Anytime and Ultradynamic have coords but are approximate
      final anytime = gyms.firstWhere((g) => g.name == 'Anytime Fitness');
      expect(anytime.hasCoordinates, true);
      expect(anytime.isPinApproximate, true);
      final ultra =
          gyms.firstWhere((g) => g.name == 'Ultradynamic Fitness Gym Prime');
      expect(ultra.hasCoordinates, true);
      expect(ultra.isPinApproximate, true);
    });
  });

  group('Price Handling', () {
    test('monthly and session prices formatted with ≈ for estimated', () {
      for (final gym in gyms) {
        if (gym.isPriceEstimated && gym.monthlyPrice.isNotEmpty) {
          expect(gym.monthlyPrice.contains('≈'), true,
              reason:
                  '${gym.name} estimated price missing ≈: ${gym.monthlyPrice}');
        }
      }
    });

    test('Anytime Fitness has highest monthly price (7000)', () {
      final anytime = gyms.firstWhere((g) => g.name == 'Anytime Fitness');
      expect(anytime.monthlyPricePhp, 7000);
    });
  });

  group('Jaccard Compatibility', () {
    test('all gyms have non-empty categories (workout_types)', () {
      for (final gym in gyms) {
        expect(gym.categories.isNotEmpty, true,
            reason: '${gym.name} has no categories for Jaccard matching');
      }
    });

    test('all gyms have non-empty facilities', () {
      for (final gym in gyms) {
        expect(gym.facilities.isNotEmpty, true,
            reason: '${gym.name} has no facilities for Jaccard matching');
      }
    });
  });

  group('Spelling Correction', () {
    test('Continental Prime Fitness Gym is correctly spelled', () {
      final continental =
          gyms.firstWhere((g) => g.name.contains('Continental'));
      expect(continental.name, 'Continental Prime Fitness Gym');
    });
  });

  group('GymModel.fromDatasetJson', () {
    test('generates correct slug ID for multi-word names', () {
      final dstarsMatina = gyms.firstWhere(
          (g) => g.branch == 'Matina' && g.name == 'Dstars Fitness Gym');
      expect(dstarsMatina.id, 'dstars-fitness-gym-matina');
    });

    test('three Dstars branches have distinct IDs', () {
      final dstars = gyms.where((g) => g.name == 'Dstars Fitness Gym').toList();
      expect(dstars.length, 3);
      final ids = dstars.map((g) => g.id).toSet();
      expect(ids.length, 3);
    });
  });

  group('Coordinate Verification Sources', () {
    test('all verified gyms have Verified coordinate_basis', () {
      final verified = gyms.where((g) => g.canShowExactMapPin).toList();
      for (final gym in verified) {
        expect(gym.coordinateBasis, 'Verified',
            reason:
                '${gym.name} (${gym.branch}) has canShowExactMapPin but coordinate_basis is ${gym.coordinateBasis}');
      }
    });

    test('gyms with coordinates have 12 total (10 verified + 2 derived)', () {
      final withCoords = gyms.where((g) => g.hasCoordinates).toList();
      expect(withCoords.length, 12);
    });

    test(
        'gyms without coordinates have 3 total (Continental, Kilo Culture, Dstars Ma-a)',
        () {
      final noCoords = gyms.where((g) => !g.hasCoordinates).toList();
      expect(noCoords.length, 3);
      final names = noCoords.map((g) => '${g.name} (${g.branch})').toSet();
      expect(
          names,
          containsAll([
            'Continental Prime Fitness Gym (Juna Subdivision)',
            'Kilo Culture (Main)',
            'Dstars Fitness Gym (Ma-a)',
          ]));
    });

    test('null-coordinate gyms have maps search URL with place_id', () {
      final noCoords = gyms.where((g) => !g.hasCoordinates).toList();
      for (final gym in noCoords) {
        expect(gym.mapsUrl, isNotNull,
            reason: '${gym.name} has null coordinates and no maps search URL');
        expect(gym.mapsUrl!.contains('maps/search'), true,
            reason:
                '${gym.name} maps_url should be a search URL, got: ${gym.mapsUrl}');
      }
    });

    test('verified gyms have coordinate maps URL with lat/lng', () {
      final verified = gyms.where((g) => g.canShowExactMapPin).toList();
      for (final gym in verified) {
        expect(gym.mapsUrl, isNotNull,
            reason: '${gym.name} verified but no maps URL');
        expect(gym.mapsUrl!.contains('q='), true,
            reason:
                '${gym.name} verified maps URL should have coordinates: ${gym.mapsUrl}');
      }
    });

    test('no (0,0) coordinates exist', () {
      for (final gym in gyms) {
        if (gym.hasCoordinates) {
          final isZero = gym.latitude == 0.0 && gym.longitude == 0.0;
          expect(isZero, false,
              reason: '${gym.name} has (0,0) coordinates which is invalid');
        }
      }
    });

    test('canShowMapMarker count equals 12 (10 Exact + 2 Building)', () {
      final markers = gyms.where((g) => g.canShowMapMarker).toList();
      expect(markers.length, 12,
          reason:
              'Expected 12 map markers (10 exact + 2 building), got ${markers.length}');
    });

    test('locationAccuracy values are strictly Exact, Building, or Unverified',
        () {
      final allowed = {'Exact', 'Building', 'Unverified'};
      for (final gym in gyms) {
        expect(allowed.contains(gym.locationAccuracy), true,
            reason:
                '${gym.name} has invalid locationAccuracy: ${gym.locationAccuracy}');
      }
      expect(gyms.where((g) => g.locationAccuracy == 'Exact').length, 10);
      expect(gyms.where((g) => g.locationAccuracy == 'Building').length, 2);
      expect(gyms.where((g) => g.locationAccuracy == 'Unverified').length, 3);
    });

    test('Anytime Fitness and Ultradynamic are Building-level accuracy', () {
      final anytime = gyms.firstWhere((g) => g.name == 'Anytime Fitness');
      expect(anytime.locationAccuracy, 'Building');
      expect(anytime.isBuildingLevel, true);
      expect(anytime.canShowMapMarker, true);
      expect(anytime.canShowExactMapPin, false);

      final ultra =
          gyms.firstWhere((g) => g.name == 'Ultradynamic Fitness Gym Prime');
      expect(ultra.locationAccuracy, 'Building');
      expect(ultra.isBuildingLevel, true);
      expect(ultra.canShowMapMarker, true);
      expect(ultra.canShowExactMapPin, false);
    });
  });
}
