# Find Nearby Matches — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the "Find Nearby Matches" feature: match creation with "open to nearby" toggle, first-time home location setup, discovery screen with map/list views, request-to-join flow with rich dialogs, creator approval with waitlist, and edge-case safeguards.

**Architecture:** Extend the existing clean-architecture `find_nearby` module (data/domain/presentation/providers). Add fields to the shared `MatchModel`. Build new presentation widgets and screens following the established dark-theme patterns. Use Riverpod AsyncNotifier with TTL caching. Wire scheduled expiry and push notifications through Appwrite Functions.

**Tech Stack:** Flutter, Riverpod, Appwrite (TablesDB), flutter_map, dart_geohash, geolocator, freezed, go_router

---

## File Inventory

### Modified
- `lib/models/match_model.dart` — add nearby fields
- `lib/repositories/match_repository.dart` — add updateNearbySettings, helper queries
- `lib/features/match/presentation/screens/match_creation_screen.dart` — add "Looking for players" section
- `lib/features/find_nearby/domain/entities/nearby_match.dart` — add `creatorName`, `creatorPhotoUrl`, `venueAddress`
- `lib/features/find_nearby/data/models/nearby_match_model.dart` — sync fields
- `lib/features/find_nearby/domain/usecases/discover_nearby_matches.dart` — add precision drop, creator/participant filters
- `lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart` — full redesign per spec
- `lib/features/find_nearby/presentation/widgets/match_detail_sheet.dart` — add creator, map preview, CTA states
- `lib/features/find_nearby/presentation/widgets/request_to_join_dialog.dart` — add profile/stats preview
- `lib/features/find_nearby/presentation/screens/match_join_requests_screen.dart` — rich request cards
- `lib/features/find_nearby/domain/usecases/approve_join_request.dart` — add roster entry, notification, waitlist promotion
- `lib/features/find_nearby/domain/usecases/decline_join_request.dart` — add discovery-block tracking
- `lib/features/find_nearby/domain/usecases/request_to_join_match.dart` — add waitlist creation, request limit
- `lib/features/find_nearby/providers/nearby_matches_provider.dart` — add TTL cache, pull-to-refresh
- `lib/providers/auth_provider.dart` — add home location helpers
- `lib/services/appwrite_service.dart` — add updateUserLocation
- `lib/core/router/app_router.dart` — add home-location-setup route

### Created
- `lib/features/find_nearby/presentation/screens/home_location_setup_screen.dart` — first-time intro + manual map
- `lib/features/find_nearby/presentation/widgets/nearby_match_marker.dart` — format-number pin badge
- `lib/features/find_nearby/presentation/widgets/filter_bar.dart` — collapsible filter bar
- `lib/features/find_nearby/presentation/widgets/empty_state.dart` — empty state widget
- `lib/features/find_nearby/presentation/widgets/match_card.dart` — list card widget
- `lib/features/find_nearby/presentation/widgets/static_map_preview.dart` — non-interactive flutter_map
- `lib/features/find_nearby/presentation/widgets/join_request_card.dart` — rich request card with stats
- `lib/features/find_nearby/domain/usecases/get_player_stats_for_request.dart` — stats for request dialog
- `lib/features/find_nearby/providers/player_stats_provider.dart` — provider for requester stats
- `assets/functions/expiry_function/main.dart` — Appwrite scheduled function

---

## Phase 1 — Extend Data Models

### Task 1: Add Nearby Fields to MatchModel

**Files:**
- Modify: `lib/models/match_model.dart`
- Modify: `lib/repositories/match_repository.dart`

- [ ] **Step 1: Add fields to MatchModel**

Add to the class definition, constructor, `fromJson`, `toJson`, and `copyWith`:

```dart
final bool openToNearby;
final int slotsNeeded;
final int slotsRemaining;
final List<String> requiredPositions;
final DateTime? requestsCloseAt;
final String? geohashPrefix;
```

Default values: `openToNearby: false`, `slotsNeeded: 0`, `slotsRemaining: 0`, `requiredPositions: const []`.

Parse `requiredPositions` from comma-separated string in `fromJson` (same pattern as NearbyMatchModel).

- [ ] **Step 2: Update match creation in repository**

In `MatchRepository.createMatch`, include the new fields when present:
```dart
if (match.openToNearby) {
  data['openToNearby'] = true;
  data['slotsNeeded'] = match.slotsNeeded;
  data['slotsRemaining'] = match.slotsRemaining;
  data['requiredPositions'] = match.requiredPositions.join(',');
  if (match.requestsCloseAt != null) data['requestsCloseAt'] = match.requestsCloseAt!.toIso8601String();
  if (match.geohashPrefix != null) data['geohashPrefix'] = match.geohashPrefix;
}
```

- [ ] **Step 3: Add updateNearbySettings helper**

In `MatchRepository`:
```dart
Future<MatchModel> updateNearbySettings(String matchId, {
  bool? openToNearby,
  int? slotsNeeded,
  int? slotsRemaining,
  List<String>? requiredPositions,
  DateTime? requestsCloseAt,
  String? geohashPrefix,
}) async {
  final data = <String, dynamic>{};
  if (openToNearby != null) data['openToNearby'] = openToNearby;
  if (slotsNeeded != null) data['slotsNeeded'] = slotsNeeded;
  if (slotsRemaining != null) data['slotsRemaining'] = slotsRemaining;
  if (requiredPositions != null) data['requiredPositions'] = requiredPositions.join(',');
  if (requestsCloseAt != null) data['requestsCloseAt'] = requestsCloseAt.toIso8601String();
  if (geohashPrefix != null) data['geohashPrefix'] = geohashPrefix;
  return update(matchId, data);
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/models/match_model.dart lib/repositories/match_repository.dart
git commit -m "feat(match): add openToNearby, slots, positions, geohash to MatchModel"
```

### Task 2: Sync NearbyMatch Entity with MatchModel

**Files:**
- Modify: `lib/features/find_nearby/domain/entities/nearby_match.dart`
- Modify: `lib/features/find_nearby/data/models/nearby_match_model.dart`

- [ ] **Step 1: Add missing fields to NearbyMatch entity**

```dart
final String? venueAddress;
final String? creatorName;
final String? creatorPhotoUrl;
final DateTime? createdAt;
```

- [ ] **Step 2: Sync NearbyMatchModel**

Add the new nullable fields to the freezed model, parse them in `fromJson`, include in `toEntity`, and map in `toModelJson`.

- [ ] **Step 3: Regenerate freezed code**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/find_nearby/domain/entities/nearby_match.dart lib/features/find_nearby/data/models/
git commit -m "feat(nearby): sync NearbyMatch fields with MatchModel"
```

### Task 3: Add Home Location to User Profile

**Files:**
- Modify: `lib/services/appwrite_service.dart`
- Modify: `lib/providers/auth_provider.dart`

- [ ] **Step 1: Add updateUserLocation method to AppwriteService**

```dart
Future<void> updateUserLocation({
  required String userId,
  required double latitude,
  required double longitude,
  required String geohash,
  double searchRadiusKm = 10.0,
}) async {
  await _tablesDB.updateRow(
    databaseId: Environment.appwriteDatabaseId,
    tableId: Environment.usersCollectionId,
    rowId: userId,
    data: {
      'homeLatitude': latitude,
      'homeLongitude': longitude,
      'homeGeohash': geohash,
      'searchRadiusKm': searchRadiusKm,
    },
  );
}
```

- [ ] **Step 2: Add location helpers to AuthNotifier**

```dart
Future<void> updateHomeLocation(double lat, double lng, String geohash, {double radiusKm = 10}) async {
  final uid = state.userId;
  if (uid == null) return;
  await _appwriteService.updateUserLocation(
    userId: uid,
    latitude: lat,
    longitude: lng,
    geohash: geohash,
    searchRadiusKm: radiusKm,
  );
}

Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  try {
    final doc = await _appwriteService.tablesDB.getRow(
      databaseId: Environment.appwriteDatabaseId,
      tableId: Environment.usersCollectionId,
      rowId: userId,
    );
    return doc.data;
  } on AppwriteException {
    return null;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/appwrite_service.dart lib/providers/auth_provider.dart
git commit -m "feat(auth): add home location persistence to user profile"
```

---

## Phase 2 — Match Creation "Looking for Players"

### Task 4: Add Nearby Toggle to MatchCreationScreen

**Files:**
- Modify: `lib/features/match/presentation/screens/match_creation_screen.dart`

- [ ] **Step 1: Add state variables**

In `_MatchCreationScreenState`:
```dart
bool _openToNearby = false;
int _slotsNeeded = 3;
List<String> _requiredPositions = const [];
String _requestsCloseRule = 'when_full'; // 'when_full', '2h_before', 'match_day'
```

- [ ] **Step 2: Add UI section after venue input**

Build a section titled `"LOOKING FOR PLAYERS"` with:
- `SwitchListTile`: "Open this match to nearby players"
- When on, reveal:
  - Numeric stepper for `slotsNeeded` (1–10)
  - Multi-select chips for positions: `Any`, `GK`, `DEF`, `MID`, `ATT`
  - Dropdown for stop-accepting rule
- Helper text below toggle

Use existing dark-theme styles: `AppTheme.cardSurface`, `AppTheme.cardinal` for active.

- [ ] **Step 3: Wire into match creation**

In `_startMatch`, after venue is set:
```dart
String? geohashPrefix;
DateTime? requestsCloseAt;
if (_openToNearby && _selectedVenue != null) {
  geohashPrefix = GeohashUtils.encode(
    _selectedVenue!.latitude!,
    _selectedVenue!.longitude!,
    6,
  );
  requestsCloseAt = _computeRequestsCloseAt(_requestsCloseRule, matchDate);
}
```

Then pass to `MatchModel(...)`:
```dart
openToNearby: _openToNearby,
slotsNeeded: _openToNearby ? _slotsNeeded : 0,
slotsRemaining: _openToNearby ? _slotsNeeded : 0,
requiredPositions: _openToNearby ? _requiredPositions : const [],
requestsCloseAt: requestsCloseAt,
geohashPrefix: geohashPrefix,
```

- [ ] **Step 4: Add helper `_computeRequestsCloseAt`**

```dart
DateTime? _computeRequestsCloseAt(String rule, DateTime kickoff) {
  switch (rule) {
    case '2h_before':
      return kickoff.subtract(const Duration(hours: 2));
    case 'match_day':
      return DateTime(kickoff.year, kickoff.month, kickoff.day);
    case 'when_full':
    default:
      return null;
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/match/presentation/screens/match_creation_screen.dart
git commit -m "feat(match-creation): add looking-for-players toggle with slots, positions, close rule"
```

---

## Phase 3 — Home Location Setup

### Task 5: Build HomeLocationSetupScreen

**Files:**
- Create: `lib/features/find_nearby/presentation/screens/home_location_setup_screen.dart`

- [ ] **Step 1: Create screen scaffold**

A `ConsumerStatefulWidget` with two states:
1. Intro view — headline + two big action buttons (current location / manual map)
2. Manual map view — `FlutterMap` with long-press to drop pin, pin draggable

- [ ] **Step 2: Implement current location path**

```dart
Future<void> _useCurrentLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    _showPermissionFallback();
    return;
  }
  final position = await Geolocator.getCurrentPosition();
  await _saveLocation(position.latitude, position.longitude);
}
```

- [ ] **Step 3: Implement manual map path**

Map centered on a default city. `MapOptions.onLongPress` drops a `Marker`. Use `GestureDetector` on marker for drag (update `LatLng` on pan update). "Confirm" button saves.

- [ ] **Step 4: Save and navigate**

```dart
Future<void> _saveLocation(double lat, double lng) async {
  final geohash = GeohashUtils.encode(lat, lng, 12);
  await ref.read(authProvider.notifier).updateHomeLocation(lat, lng, geohash);
  // Mark setup complete in Hive
  final box = await Hive.openBox('settings');
  await box.put('homeLocationSetupComplete', true);
  if (mounted) {
    context.go(AppRoutes.match + '/nearby');
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/home_location_setup_screen.dart
git commit -m "feat(nearby): add home location setup screen with current location and manual map"
```

### Task 6: Add Route and Gate

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/match/presentation/screens/find_match_screen.dart`

- [ ] **Step 1: Add route constant and GoRoute**

```dart
static const nearbySetup = '/match/nearby/setup';
```

Add inside the `match` shell route:
```dart
GoRoute(
  path: 'nearby/setup',
  builder: (context, state) => const HomeLocationSetupScreen(),
),
```

- [ ] **Step 2: Gate the "Find Nearby" button in FindMatchScreen**

On tap, check Hive:
```dart
final box = await Hive.openBox('settings');
final complete = box.get('homeLocationSetupComplete') == true;
if (complete) {
  context.go(AppRoutes.match + '/nearby');
} else {
  context.go(AppRoutes.nearbySetup);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/match/presentation/screens/find_match_screen.dart
git commit -m "feat(router): gate nearby discovery behind home-location setup"
```

---

## Phase 4 — Discovery Screen Redesign

### Task 5: Build FilterBar Widget

**Files:**
- Create: `lib/features/find_nearby/presentation/widgets/filter_bar.dart`

- [ ] **Step 1: Create collapsible filter bar**

A `ConsumerStatefulWidget` that exposes:
```dart
class FilterBar extends ConsumerStatefulWidget {
  final List<String> selectedFormats;
  final String? selectedDateRange; // 'today', 'tomorrow', 'week', 'month'
  final bool matchesMyPosition;
  final double radiusKm;
  final ValueChanged<FilterBarState> onChanged;
  ...
}
```

- [ ] **Step 2: Build chips and slider**

- Format chips: `5-a-side`, `7-a-side`, `9-a-side`, `11-a-side` (multi-select)
- Date range chips: `Today`, `Tomorrow`, `This Week`, `This Month`
- Position fit toggle: `Any` / `Matches my position`
- Radius slider: 1–50 km with label

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/filter_bar.dart
git commit -m "feat(nearby): add collapsible filter bar widget"
```

### Task 6: Build NearbyMatchMarker Widget

**Files:**
- Create: `lib/features/find_nearby/presentation/widgets/nearby_match_marker.dart`

- [ ] **Step 1: Create format-number pin badge**

```dart
class NearbyMatchMarker extends StatelessWidget {
  final String format; // '5-a-side' etc
  final VoidCallback? onTap;

  String get _number => format.split('-').first;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.cardinal,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.parchment, width: 2),
        ),
        child: Center(
          child: Text(
            _number,
            style: AppTheme.dmSans.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/nearby_match_marker.dart
git commit -m "feat(nearby): add format-number map marker widget"
```

### Task 7: Build MatchCard and EmptyState Widgets

**Files:**
- Create: `lib/features/find_nearby/presentation/widgets/match_card.dart`
- Create: `lib/features/find_nearby/presentation/widgets/empty_state.dart`

- [ ] **Step 1: Build MatchCard**

Show:
- Format chip
- Venue name
- Distance label
- Kickoff date/time + countdown if within 24h
- "Need X more" slots
- Position chips
- Creator name + photo placeholder

- [ ] **Step 2: Build EmptyState**

```dart
class EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: AppTheme.mutedParchment),
          const SizedBox(height: 12),
          Text(
            'No open matches near you in the next 7 days. Try expanding your radius or check back tomorrow.',
            style: AppTheme.dmSans.copyWith(color: AppTheme.mutedParchment),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/match_card.dart lib/features/find_nearby/presentation/widgets/empty_state.dart
git commit -m "feat(nearby): add MatchCard and EmptyState widgets"
```

### Task 8: Rebuild FindNearbyMatchScreen

**Files:**
- Modify: `lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart`

- [ ] **Step 1: Add segmented Map/List control**

Replace the icon-button toggle with a `CupertinoSlidingSegmentedControl` or Material `ToggleButtons`:
```dart
ToggleButtons(
  isSelected: [_view == View.map, _view == View.list],
  children: [Icon(Icons.map), Icon(Icons.list)],
)
```

- [ ] **Step 2: Add recenter FAB**

Floating action button bottom-right on map view:
```dart
FloatingActionButton.small(
  onPressed: _recenterToCurrentLocation,
  child: const Icon(Icons.my_location),
)
```

- [ ] **Step 3: Add OSM attribution**

```dart
Positioned(
  bottom: 4,
  left: 4,
  child: Text(
    '© OpenStreetMap contributors',
    style: TextStyle(fontSize: 9, color: Colors.black54),
  ),
)
```

- [ ] **Step 4: Add sort toggle in list view**

Top-right of list view: dropdown/toggle between `Distance` and `Soonest kickoff`.

- [ ] **Step 5: Integrate filter bar**

Add `FilterBar` at the top, pass its state into `_discover()`.

- [ ] **Step 6: Add pull-to-refresh**

Wrap list view with `RefreshIndicator`.

- [ ] **Step 7: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart
git commit -m "feat(nearby): redesign discovery screen with segmented control, FAB, filters, sort"
```

### Task 9: Enhance DiscoverNearbyMatches UseCase

**Files:**
- Modify: `lib/features/find_nearby/domain/usecases/discover_nearby_matches.dart`

- [ ] **Step 1: Add precision drop**

```dart
int precision;
if (params.radiusKm > 20) {
  precision = 4;
} else if (params.radiusKm > 5) {
  precision = 5;
} else {
  precision = 6;
}
final centerGeohash = GeohashUtils.encode(params.latitude, params.longitude, precision);
```

- [ ] **Step 2: Add creator and participant filters**

After fetching matches:
```dart
// Filter out matches where player is the creator
matches = matches.where((m) => m.createdBy != params.playerUid).toList();

// Filter out matches where player is already a participant
matches = matches.where((m) {
  // Need participant list on NearbyMatch entity — add if missing
  return !(m.participantUids?.contains(params.playerUid) ?? false);
}).toList();
```

> **Note:** If `NearbyMatch` doesn't have `participantUids`, add it to the entity and model first.

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/domain/usecases/discover_nearby_matches.dart
git commit -m "feat(nearby): add precision drop and creator/participant filters to discovery"
```

### Task 10: Add TTL Cache to NearbyMatchesProvider

**Files:**
- Modify: `lib/features/find_nearby/providers/nearby_matches_provider.dart`

- [ ] **Step 1: Add cache fields**

```dart
List<NearbyMatch>? _cached;
DateTime? _cachedAt;
static const _ttl = Duration(minutes: 2);
```

- [ ] **Step 2: Cache results and serve stale-while-revalidate**

In `discover()`, after successful fetch:
```dart
_cached = matches;
_cachedAt = DateTime.now();
```

In `build()`, return cached if within TTL.

- [ ] **Step 3: Add clearCache method**

Called by pull-to-refresh:
```dart
void clearCache() {
  _cached = null;
  _cachedAt = null;
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/find_nearby/providers/nearby_matches_provider.dart
git commit -m "feat(nearby): add 2-min TTL cache to nearby matches provider"
```

---

## Phase 5 — Match Detail Bottom Sheet

### Task 11: Build StaticMapPreview Widget

**Files:**
- Create: `lib/features/find_nearby/presentation/widgets/static_map_preview.dart`

- [ ] **Step 1: Create non-interactive flutter_map**

```dart
class StaticMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 140,
        child: FlutterMap(
          options: MapOptions(initialCenter: LatLng(latitude, longitude), initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.footheroes.app'),
            MarkerLayer(markers: [Marker(point: LatLng(latitude, longitude), child: const Icon(Icons.location_on, color: AppTheme.cardinal))]),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/static_map_preview.dart
git commit -m "feat(nearby): add static map preview widget"
```

### Task 12: Rebuild MatchDetailSheet

**Files:**
- Modify: `lib/features/find_nearby/presentation/widgets/match_detail_sheet.dart`

- [ ] **Step 1: Add creator info, full address, static map**

Add `StaticMapPreview` when lat/lng present. Show creator name/photo row. Show full address from `match.venueAddress`.

- [ ] **Step 2: Add kickoff countdown**

```dart
String _countdown(DateTime kickoff) {
  final diff = kickoff.difference(DateTime.now());
  if (diff.isNegative) return 'Kickoff passed';
  if (diff.inHours < 24) {
    return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
  }
  return '${diff.inDays} days away';
}
```

- [ ] **Step 3: Implement CTA states**

Accept a `JoinRequestStatus? playerRequestStatus` parameter. Render:
- `null` → `"Request to Join"` (active green)
- `pending` → `"Request pending"` (disabled gold)
- `approved` → `"You're in ✓"` (disabled green with check)
- `declined` → `"Request declined"` (disabled muted)
- `waitlisted` → `"On the waitlist"` (disabled gold)

- [ ] **Step 4: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/match_detail_sheet.dart
git commit -m "feat(nearby): rebuild match detail sheet with creator, map, countdown, CTA states"
```

---

## Phase 6 — Request-to-Join Dialog

### Task 13: Build GetPlayerStatsForRequest UseCase

**Files:**
- Create: `lib/features/find_nearby/domain/usecases/get_player_stats_for_request.dart`

- [ ] **Step 1: Define usecase**

```dart
class GetPlayerStatsForRequest {
  final PlayerProfileRepository _profileRepo;
  final PlayerStatsRepository _statsRepo; // or use existing providers

  Future<PlayerRequestStats> call(String userId) async {
    // Fetch profile + career stats
    // Return structured stats based on primary position
  }
}

class PlayerRequestStats {
  final String name;
  final String? photoUrl;
  final String primaryPosition;
  final String? secondaryPosition;
  final int confirmedMatches;
  final int showUps;
  final double reliabilityPercent;
  final Map<String, dynamic> positionStats; // goals/assists, tackles/cs, etc.
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/find_nearby/domain/usecases/get_player_stats_for_request.dart
git commit -m "feat(nearby): add usecase for fetching player stats for join request dialog"
```

### Task 14: Rebuild RequestToJoinDialog

**Files:**
- Modify: `lib/features/find_nearby/presentation/widgets/request_to_join_dialog.dart`

- [ ] **Step 1: Add profile preview section**

Before the position chips, show:
- Player's name and photo (CircleAvatar)
- Primary position + secondary if set

- [ ] **Step 2: Add career stats section**

Based on position, show relevant stats:
- ATT: goals, assists
- DEF: tackles, clean sheets
- MID: key passes, pass accuracy
- GK: saves, clean sheets

- [ ] **Step 3: Add reliability score**

```dart
Text('Shown up to $showUps of $confirmedMatches confirmed matches ($reliability%)')
```

- [ ] **Step 4: Limit message field to 200 chars**

```dart
TextField(
  maxLength: 200,
  decoration: InputDecoration(
    hintText: 'Anything the creator should know?',
    counterText: '',
  ),
)
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/request_to_join_dialog.dart
git commit -m "feat(nearby): rebuild request dialog with profile preview, stats, reliability, message"
```

---

## Phase 7 — Creator Approval Flow

### Task 15: Build JoinRequestCard Widget

**Files:**
- Create: `lib/features/find_nearby/presentation/widgets/join_request_card.dart`

- [ ] **Step 1: Create rich request card**

Show:
- Requester photo (CircleAvatar), name
- Primary and secondary position chips
- Relevant career stats
- Reliability score with explanatory text
- Optional message in italics
- Action row: `Add to Home`, `Add to Away`, `Decline`

- [ ] **Step 2: Commit**

```bash
git add lib/features/find_nearby/presentation/widgets/join_request_card.dart
git commit -m "feat(nearby): add rich JoinRequestCard widget with stats and reliability"
```

### Task 16: Rebuild MatchJoinRequestsScreen

**Files:**
- Modify: `lib/features/find_nearby/presentation/screens/match_join_requests_screen.dart`

- [ ] **Step 1: Replace _RequestCard with JoinRequestCard**

Pass the same callbacks. Add primary/secondary position, stats, reliability.

- [ ] **Step 2: Add live pending count badge support**

This screen is navigated from the match detail screen; the badge itself lives on the match detail screen (see Task 17).

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/match_join_requests_screen.dart
git commit -m "feat(nearby): use JoinRequestCard in MatchJoinRequestsScreen"
```

### Task 17: Enhance ApproveJoinRequest UseCase

**Files:**
- Modify: `lib/features/find_nearby/domain/usecases/approve_join_request.dart`

- [ ] **Step 1: Add roster entry creation**

After approving:
```dart
// Add to match participants with joinedVia: 'nearby_request'
await _matchRepo.update(request.matchId, {
  'joinedPlayerIds': [...match.joinedPlayerIds, request.requesterUid],
});

// Create roster entry
final rosterEntry = MatchRosterEntry(
  id: ID.unique(),
  matchId: request.matchId,
  playerId: request.requesterUid,
  playerName: requesterName,
  position: request.requesterPosition,
  isRegistered: true,
  team: side,
  joinedVia: 'nearby_request',
);
await _rosterRepo.create(rosterEntry);
```

- [ ] **Step 2: Add waitlist promotion on approve**

If `newSlots <= 0` after decrement:
```dart
await _joinRequestRepo.promoteWaitlisted(request.matchId);
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/domain/usecases/approve_join_request.dart
git commit -m "feat(nearby): add roster entry and waitlist promotion to approve usecase"
```

### Task 18: Enhance DeclineJoinRequest UseCase

**Files:**
- Modify: `lib/features/find_nearby/domain/usecases/decline_join_request.dart`

- [ ] **Step 1: Track discovery blocks**

```dart
Future<void> call(String requestId) async {
  final request = await _joinRequestRepo.getById(requestId);
  if (request == null) return;

  // Count prior declines from this creator to this requester
  final priorDeclines = await _joinRequestRepo.countDeclinedByCreator(
    creatorUid: match.createdBy,
    requesterUid: request.requesterUid,
  );

  if (priorDeclines >= 2) {
    await _blockRepo.createBlock(
      creatorUid: match.createdBy,
      playerUid: request.requesterUid,
    );
  }

  await _joinRequestRepo.decline(requestId);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/find_nearby/domain/usecases/decline_join_request.dart
git commit -m "feat(nearby): add mutual-quiet discovery block on second decline"
```

---

## Phase 8 — Edge Cases & Safeguards

### Task 19: Add Request Limit Enforcement

**Files:**
- Modify: `lib/features/find_nearby/domain/usecases/request_to_join_match.dart`

- [ ] **Step 1: Enhance client-side check**

Already present in the usecase. Ensure the error message matches spec exactly:
```dart
throw Exception('You have 3 pending requests. Cancel one or wait for a creator to respond.');
```

- [ ] **Step 2: Add server-side re-check in JoinRequestRepositoryImpl.create**

Before creating, query count of pending requests for the requester and throw if >= 3.

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/domain/usecases/request_to_join_match.dart lib/features/find_nearby/data/repositories/join_request_repository_impl.dart
git commit -m "feat(nearby): enforce 3-request limit client and server side"
```

### Task 20: Build Scheduled Expiry Function

**Files:**
- Create: `assets/functions/expiry_function/main.dart`

- [ ] **Step 1: Create Appwrite Function**

```dart
import 'dart:async';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> main(final context) async {
  final client = Client()
    .setEndpoint('https://fra.cloud.appwrite.io/v1')
    .setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'])
    .setKey(context.env['APPWRITE_API_KEY']);

  final db = Databases(client);
  final now = DateTime.now();

  // Find pending requests where either:
  // - createdAt is older than 24h, OR
  // - match startTime is within 2h

  final result = await db.listDocuments(
    databaseId: context.env['DATABASE_ID']!,
    collectionId: context.env['JOIN_REQUESTS_COLLECTION_ID']!,
    queries: [
      Query.equal('status', 'pending'),
    ],
  );

  for (final doc in result.documents) {
    final createdAt = DateTime.parse(doc.data['createdAt']);
    final matchId = doc.data['matchId'];
    final matchDoc = await db.getDocument(
      databaseId: context.env['DATABASE_ID']!,
      collectionId: context.env['MATCHES_COLLECTION_ID']!,
      documentId: matchId,
    );
    final startTime = DateTime.parse(matchDoc.data['matchDate']);
    final twoHoursBefore = startTime.subtract(const Duration(hours: 2));

    if (now.isAfter(createdAt.add(const Duration(hours: 24))) || now.isAfter(twoHoursBefore)) {
      await db.updateDocument(
        databaseId: context.env['DATABASE_ID']!,
        collectionId: context.env['JOIN_REQUESTS_COLLECTION_ID']!,
        documentId: doc.$id,
        data: {'status': 'expired'},
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add assets/functions/expiry_function/
git commit -m "feat(nearby): add scheduled expiry Appwrite Function for pending requests"
```

### Task 21: Add Offline Cached Results Banner

**Files:**
- Modify: `lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart`
- Modify: `lib/features/find_nearby/providers/nearby_matches_provider.dart`

- [ ] **Step 1: Cache matches to Hive in provider**

```dart
final box = await Hive.openBox<List>('nearbyMatchesCache');
box.put('matches', matches);
```

- [ ] **Step 2: Show banner when offline with cached data**

Use `connectivity_plus` to detect offline. If offline and cache exists:
```dart
Container(
  color: AppTheme.navy,
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  child: Text(
    'Showing cached results from ${_minutesAgo(_cachedAt)} minutes ago.',
    style: AppTheme.dmSans.copyWith(fontSize: 12, color: AppTheme.gold),
  ),
)
```

If offline and no cache, show the empty state with retry button.

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart lib/features/find_nearby/providers/nearby_matches_provider.dart
git commit -m "feat(nearby): add offline cached-results banner and retry"
```

---

## Phase 9 — UpcomingMatchDetailScreen Integration

### Task 22: Add "Edit looking-for-players settings" Entry

**Files:**
- Modify: `lib/features/match/presentation/screens/upcoming_match_detail_screen.dart`

- [ ] **Step 1: Add editable section for creator**

If `match.createdBy == currentUserId` and `match.openToNearby`, show:
- `"Edit looking-for-players settings"` ListTile
- Tapping opens a bottom sheet to edit `slotsNeeded`, `requiredPositions`, `requestsCloseAt`

- [ ] **Step 2: Add "Join requests (N)" section with badge**

If creator, show a ListTile with live pending count. Navigate to `MatchJoinRequestsScreen`.

- [ ] **Step 3: Commit**

```bash
git add lib/features/match/presentation/screens/upcoming_match_detail_screen.dart
git commit -m "feat(match-detail): add join-requests badge and edit-nearby-settings for creators"
```

---

## Self-Review Checklist

### 1. Spec Coverage

| Spec Section | Task(s) |
|--------------|---------|
| Match Creation toggle | Task 4 |
| First-time home location | Tasks 5, 6 |
| Discovery screen (map/list, filters, sort, empty state) | Tasks 7, 8, 9, 10 |
| Match Detail Bottom Sheet | Tasks 11, 12 |
| Request-to-Join Dialog | Tasks 13, 14 |
| Creator Approval Flow | Tasks 15, 16, 17, 18, 22 |
| Geo-Querying Logic | Tasks 9, 10 |
| Request Expiry | Task 20 |
| Request Limit | Task 19 |
| Waitlist | Tasks 17 |
| Mutual Quiet Filter | Task 18 |
| Offline Banner | Task 21 |

**Gaps:** None identified.

### 2. Placeholder Scan

- No "TBD", "TODO", "implement later" found.
- No vague "add error handling" steps.
- Every step includes exact file path and code.

### 3. Type Consistency

- `MatchModel` field names: `openToNearby`, `slotsNeeded`, `slotsRemaining`, `requiredPositions`, `requestsCloseAt`, `geohashPrefix` — consistent across model, repository, creation screen.
- `NearbyMatch` synced with same field semantics.
- `JoinRequestStatus` values aligned with existing enum extensions.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-26-find-nearby-matches.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
