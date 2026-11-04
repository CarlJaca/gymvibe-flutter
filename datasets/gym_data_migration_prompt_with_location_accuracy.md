# PROMPT: Replace mock data with the real Davao gym dataset and verify precise map locations (Gym Vibe Davao)

> Attach `davao_gyms_15_branches_flutter_2026-11-03.json` and the existing Flutter project to the chat together with this prompt. The JSON is an **unverified starting dataset**, not proof that its map coordinates identify the correct gym.

## ROLE
You are a senior Flutter/Dart engineer working inside my existing project, **Gym Vibe Davao**: a location-based gym discovery app for Davao City that ranks gyms with **Jaccard similarity** and uses the **Geolocator** package for location. Be careful and minimal. Keep the current architecture, state management, and UI style.

## GOAL
Remove ALL mock/dummy gym data. The app must run on the attached 15-branch dataset (each JSON object currently has 23 data fields plus a `has_verified_map_point` flag, 24 keys in total). **Location accuracy is a release requirement:** each displayed gym pin must correspond to that specific branch’s real physical location, never a neighboring business, a different branch, or an invented street/district centroid. The Flutter map must use the gym coordinates in the dataset, while Geolocator supplies the **user’s** position for distance calculations. The app must compile, run, and retain the existing architecture and matching behavior.

---

## STEP 0: AUDIT FIRST (read-only, no edits yet)
Report briefly:
1. Where the mock data lives (files, variable names, seed/"dummy"/"sample" helpers) and every place that uses it.
2. The current gym model (class name, fields, constructor) and which screens/widgets/services read each field.
3. Fields the UI or matching currently uses that DO NOT exist in the real dataset (e.g. rating, imageUrl, reviews, distance, tags).
4. The state-management pattern in use (Provider / Riverpod / Bloc / GetX / setState) and the map package used for pins.
5. Whether the mock data comes from a backend (Firebase / Supabase / API). **If yes, STOP and ask me before changing anything.**

Then give a short plan and continue. Ask me only if something is genuinely ambiguous.

---

## STEP 0.5: MANDATORY GYM LOCATION ACCURACY AUDIT (before enabling map pins)

**This step takes priority over the existing JSON's six provisional pins.** Accurate map locations are more important than displaying a fixed number of markers. Audit **each of the 15 gym branches individually** before treating a coordinate pair as navigation-grade.

1. **Check branch identity and address.** Confirm that the gym exists at the listed address, belongs to Matina, Ecoland, Talomo, or Bangkal in Davao City, and is not closed or duplicated. Never borrow coordinates from another branch, even when the brand name is identical.
2. **Verify each latitude/longitude from branch-specific geographic evidence.** Accepted sources: (a) the exact gym's Google Maps URL containing `@lat,lng` or `!3d/!4d`, (b) an OpenStreetMap/Nominatim feature for the exact gym or confirmed full address, (c) a Plus Code published for that branch and correctly decoded, or (d) the gym's official site/Facebook page if it explicitly publishes coordinates. Keep **at least five decimal places** in the source record/display. A general address, nearby landmark, search result, or district center is **not** evidence of an exact gym pin.
3. **Classify accuracy separately from simple numeric validity:**
   - **Exact gym pin:** source identifies the specific branch's premises, and the pin matches its published address. This is eligible for default map markers and Geolocator distance/navigation features.
   - **Building-/mall-level or street-level:** source identifies only a shared building, mall, or road. This is **approximate**, not the exact gym entrance. Preserve the coordinates only with clear provenance and an “Approximate location” warning; do not silently enable them as precise navigation pins.
   - **Unverified/missing:** no traceable branch-specific coordinate source, a conflicting pin, or inaccessible map evidence. Keep the gym in directory/matching results, but do **not** pin it or use it in precise distance computations.
4. **Validate all coordinates:** latitude must be within `6.9`–`7.5`, longitude within `125.2`–`125.8`; check for identical coordinates assigned to different gyms; and flag coordinates farther than 3 km from the median of the **other** gyms in the same district when there are sufficient geocoded gyms for that comparison. Also compare the coordinate pin to the gym's actual written address. Passing range/distance checks **does not prove** the pin is correct.
5. **Maintain branch-specific provenance:** report each gym's name, branch, address, latitude, longitude, source URL, evidence type, accuracy classification, and any conflict. Do not label a building centroid as an exact gym pin. If web/maps access or a source fails, say so and keep that pin unverified rather than guessing.
6. **Correct the asset only with traceable evidence.** Updating incorrect coordinates, `maps_url`, or `has_verified_map_point` is permitted only when the corresponding source is explicitly identified in the audit; log the old and new values. For an unverifiable coordinate, retain the gym record but set its latitude and longitude to `null` **when it would otherwise be mistaken for a verified point**, and set `has_verified_map_point` to `false`. The flag must mean **exact branch pin independently checked**; do not assume the supplied flag is accurate. Keep all other original fields unchanged except the permitted spelling correction below.
7. **Do not promise all 15 exact pins.** The target is 15 real gym records with as many **source-verified exact pins** as the evidence supports, not 15 invented markers. For gyms without exact pins, offer a **search-by-gym-name-and-address Google Maps link**, not a misleading coordinate-navigation link.

**Audit deliverable:** Provide a short coordinate audit table and a list of any corrections made before wiring up the map. If the required map sources cannot be accessed, keep precise pinning disabled for locations that cannot be checked; do not report the coordinate audit as completed.

---

## STEP 1: DATASET AS A BUNDLED ASSET
- Copy the JSON to `assets/data/davao_gyms.json` (stable name, so future dataset updates need no code change).
- Register it in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/data/davao_gyms.json
```

- Bundle ONE data file only. Do NOT add a second pins-only JSON or any CSV to the app. Eligible map pins are derived from the audited data using **both** non-null coordinates **and** a verified exact-branch-pin flag.
- Correct the typo `"Contnental Prime Fitness Gym"` to `"Continental Prime Fitness Gym"` (the dataset's own URLs spell it Continental). Other than evidence-backed location corrections documented in Step 0.5, do not change existing values.
- NEVER invent, guess, or silently geocode coordinates; do not "fix" prices, hours, or phone numbers without separately verified evidence and explicit scope approval.

---

## STEP 2: DATA CONTRACT (read carefully)

Each JSON object has these snake_case keys:

| Key | Type | Notes |
|---|---|---|
| name, branch, district, address | String | |
| latitude, longitude | number or **null** | Starting dataset has 9 null pairs; counts may change following the accuracy audit |
| maps_url | String | exact-coordinate link **only** for an exact verified gym pin; otherwise an exact gym name/address search or official listing link |
| phone | String | has a leading 0 (e.g. `09209787878`) |
| operating_hours | String | free text, display only |
| website_or_facebook, source_url, notes | String | |
| workout_types, facilities, schedule_type, trainer_availability, membership_types | List<String> | the Jaccard feature sets |
| monthly_price_php, session_price_php | int | |
| coordinate_basis, contact_basis, attributes_basis, price_basis | String | `Verified` / `Derived` / `Estimated` |
| has_verified_map_point | bool | must be audited: `true` only for a confirmed exact, branch-specific map pin |

### Gotchas that MUST be handled
1. **Names are not unique.** "Dstars Fitness Gym" appears 3 times (Matina, Ecoland, Ma-a). Never use `name` as a key. Generate `id = slug(name + branch)`.
2. **Null coordinates.** Model them as `double?`. NEVER default to `0.0`, since (0,0) breaks pins and distance math.
3. **Phone is a String.** Never parse it as an int (the leading zero would be lost). This is also why the JSON is the source of truth, not the CSV.
4. **`has_verified_map_point` is misleading in the source file.** It currently marks all 6 non-null pairs true, but some are building/mall centroids rather than verified exact gym pins. **Audit and correct this flag** before map use. A `Derived` coordinate may identify an exact OSM gym feature or merely a building centroid; do not infer precision from the basis tag alone. Require both a non-null pair and `has_verified_map_point == true` for precise map/distance eligibility. Display "Approximate location" when presenting any retained lower-precision point; it must not masquerade as an exact destination.
5. **Prices are mostly estimates** (13 of 15 are `Estimated`). Show "≈" or "est." next to the price when `price_basis != "Verified"`.
6. **List fields feed Jaccard.** Trim whitespace and compare case-insensitively. Keep the original text for display. DO NOT change the Jaccard algorithm.
7. **`schedule_type` can be `Flexible`** (24/7 gyms). Do not special-case it. Instead, tell me in the final report whether a user picking Morning/Evening scores 0 against Flexible gyms, so I can decide.

### Reference implementation (adapt names/paths to the existing model; extend the existing model instead of creating a duplicate)

```dart
// lib/models/gym.dart
class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.branch,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.mapsUrl,
    required this.phone,
    required this.operatingHours,
    required this.websiteOrFacebook,
    required this.workoutTypes,
    required this.facilities,
    required this.scheduleType,
    required this.trainerAvailability,
    required this.membershipTypes,
    required this.monthlyPricePhp,
    required this.sessionPricePhp,
    required this.sourceUrl,
    required this.coordinateBasis,
    required this.contactBasis,
    required this.attributesBasis,
    required this.priceBasis,
    required this.notes,
    required this.hasVerifiedMapPoint,
  });

  final String id;
  final String name;
  final String branch;
  final String district;
  final String address;
  final double? latitude;
  final double? longitude;
  final String mapsUrl;
  final String phone;
  final String operatingHours;
  final String websiteOrFacebook;
  final List<String> workoutTypes;
  final List<String> facilities;
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

  bool get hasCoordinates => latitude != null && longitude != null;
  // Audited exact-branch map points only; a numeric pair alone is insufficient.
  bool get canShowExactMapPin => hasCoordinates && hasVerifiedMapPoint;
  bool get isPinApproximate => hasCoordinates && !hasVerifiedMapPoint;
  bool get isPriceEstimated => priceBasis != 'Verified';

  factory Gym.fromJson(Map<String, dynamic> j) {
    List<String> list(String key) => ((j[key] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .toList(growable: false);

    final name = (j['name'] as String).trim();
    final branch = ((j['branch'] as String?) ?? '').trim();

    return Gym(
      id: _slug('$name $branch'),
      name: name,
      branch: branch,
      district: j['district'] as String,
      address: j['address'] as String,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      mapsUrl: j['maps_url'] as String,
      phone: j['phone'].toString(),
      operatingHours: j['operating_hours'] as String,
      websiteOrFacebook: j['website_or_facebook'] as String,
      workoutTypes: list('workout_types'),
      facilities: list('facilities'),
      scheduleType: list('schedule_type'),
      trainerAvailability: list('trainer_availability'),
      membershipTypes: list('membership_types'),
      monthlyPricePhp: (j['monthly_price_php'] as num).toInt(),
      sessionPricePhp: (j['session_price_php'] as num).toInt(),
      sourceUrl: j['source_url'] as String,
      coordinateBasis: j['coordinate_basis'] as String,
      contactBasis: j['contact_basis'] as String,
      attributesBasis: j['attributes_basis'] as String,
      priceBasis: j['price_basis'] as String,
      notes: j['notes'] as String,
      hasVerifiedMapPoint: j['has_verified_map_point'] as bool,
    );
  }

  static String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
```

```dart
// lib/data/gym_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/gym.dart';

class GymRepository {
  GymRepository._();
  static final GymRepository instance = GymRepository._();

  static const _asset = 'assets/data/davao_gyms.json';
  List<Gym>? _cache;

  Future<List<Gym>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_asset);
    final gyms = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Gym.fromJson)
        .toList(growable: false);

    assert(
      gyms.map((g) => g.id).toSet().length == gyms.length,
      'Duplicate gym ids in $_asset',
    );
    return _cache = gyms;
  }

  /// Only gyms with a source-verified exact branch pin are drawn on the map.
  Future<List<Gym>> loadPinned() async =>
      (await loadAll()).where((g) => g.canShowExactMapPin).toList(growable: false);
}
```

Expose the repository through the app's EXISTING state-management pattern. Do not introduce a new one.

---

## STEP 3: WIRE IT IN
- Replace every mock-data usage with the repository.
- **Fields that don't exist in the dataset:** do NOT fabricate them. Hide that UI element or use a neutral placeholder, and list each one in the final report.
- **Matching:** keep the existing Jaccard code untouched. Only feed it the real, normalized lists.
- **User location vs. gym location:** obtain the user’s GPS position through `Geolocator` with permission/error handling. Gym marker positions come **only** from the audited JSON; do not substitute the user’s GPS position, district midpoint, or a map camera center as a gym location.
- **Distance (Geolocator):** use `Geolocator.distanceBetween(userLat, userLng, gymLat, gymLng)` only where `gym.canShowExactMapPin` is true. Other gyms must still appear in search and matching. Show "Distance unavailable — gym pin not verified" and place those entries after valid distances when sorting by distance. Do not exclude them from Jaccard results. Handle denied GPS permission without crashing.
- **Map:** draw markers **only** for gyms with `gym.canShowExactMapPin` true, and always tie each marker to the correct gym `id`, branch, and address. Marker counts must come from audited data, **not** from a hard-coded `6`. For all other gyms, show "Pin not verified" (or "Approximate location" if a lower-precision point is intentionally displayed only as informational text) plus an **Open in Google Maps** button. Launch an exact validated coordinate URL only for audited exact pins; otherwise launch a branch-specific name/address search URL using `url_launcher` (`LaunchMode.externalApplication`). Add `url_launcher` only if needed.
- **Marker and navigation check:** tapping each map marker must open the matching gym details (correct branch, address, and source), and navigation must open that same branch-specific destination. Avoid matching on `name` alone. Check that switching gyms does not reuse a previous marker position.
- Android 11+ needs this in `android/app/src/main/AndroidManifest.xml` (above `<application>`), or the link won't open:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

- Approximate location disclosures and estimated prices: show the small labels described in Gotchas 4 and 5. Never display an approximate coordinate as an exact gym pin.
- Add a one-line data note on the list or About screen: "Data as of 2026-11-03. Prices are estimates unless marked verified."

---

## STEP 4: REMOVE MOCK DATA COMPLETELY
- Delete the mock files, classes, seed functions, and their imports. No commented-out leftovers and no flag that toggles mock data back on.
- Run `grep -rniE "mock|dummy|sample|fake|seed" lib/ test/` and resolve every hit (rename it if it's unrelated).
- Remove model or UI fields that are now unused only if nothing else references them.

---

## STEP 5: TESTS

```dart
// test/gym_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:YOUR_APP_NAME/data/gym_repository.dart'; // fix the package name

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the 15 real Davao gyms', () async {
    final gyms = await GymRepository.instance.loadAll();

    expect(gyms.length, 15);
    expect(gyms.map((g) => g.id).toSet().length, 15); // ids are unique
    // Exact-pin counts depend on the source-backed coordinate audit; do not hard-code 6/9.
    expect(gyms.where((g) => g.canShowExactMapPin).every(
      (g) => g.hasCoordinates && g.hasVerifiedMapPoint), isTrue);
    expect(gyms.every((g) => g.phone.startsWith('0')), isTrue);

    for (final g in gyms.where((g) => g.hasCoordinates)) {
      expect(g.latitude!, inInclusiveRange(6.9, 7.5));
      expect(g.longitude!, inInclusiveRange(125.2, 125.8));
    }
  });

  test('loadPinned returns only gyms with coordinates', () async {
    final pinned = await GymRepository.instance.loadPinned();
    expect(pinned.every((g) => g.hasCoordinates && g.hasVerifiedMapPoint), isTrue);
    expect(pinned.map((g) => g.id).toSet().length, pinned.length);
  });
}
```

Add data-integrity tests that reject duplicate coordinates assigned to different gym branches, invalid coordinate ranges, and mismatches between a verified pin's source coordinates and the data when the source can be machine-read. Add a fixture/manual audit checklist for verifying each pin against its actual gym address; tests of geographic bounds alone cannot confirm the venue.

Also keep any existing Jaccard tests passing. If there are none, add one that ranks the real dataset for a sample preference set and asserts that the results are sorted by score, descending.

---

## STEP 6: VERIFY (run these, don't just claim)
1. `flutter pub get`
2. `dart format lib test`
3. `flutter analyze`, which must report **0 issues**
4. `flutter test`, which must pass
5. Run the app and confirm: the list shows 15 gyms; the map shows **only audited exact-branch pins** (count depends on results); every other gym shows "Pin not verified" and opens a branch-specific Google Maps search; each marker matches its gym detail and navigation destination; distance sorting uses only eligible pins; and Jaccard results still sort correctly.
6. Inspect the marker of **each eligible gym** against its source map and address. If this cannot be checked, disclose which pins remain unaudited and do not claim the locations are accurate.

---

## CONSTRAINTS
- No new state-management libraries and no refactors outside this scope.
- Null-safe code, `const` constructors where possible, no hard-coded gym data anywhere in Dart.
- Don't touch unrelated screens, themes, or navigation.

## FINAL REPORT FORMAT
1. Files added / changed / deleted.
2. UI fields that no longer have data, and what you did instead.
3. Whether the `Flexible` schedule case causes 0-scores in Jaccard (Gotcha 7).
4. If prices are normalized for matching: note that Anytime Fitness (₱7,000/month) is a large outlier against the rest (₱1,000-3,200).
5. Coordinate audit per branch: evidence URLs, exact/approximate/unverified classification, location corrections and flags, and a count of eligible map pins. Distinguish unverified pins from gyms still present in the directory.
6. Any pin that could not be checked and why; do not claim full geolocation accuracy without source verification.
7. Anything that needs my decision.
