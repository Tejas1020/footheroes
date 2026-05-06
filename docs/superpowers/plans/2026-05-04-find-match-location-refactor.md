# Find Match Location Refactor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor FindNearbyMatchScreen so users explicitly set their home location before seeing nearby matches — pick on map or use GPS, persist to Appwrite, then auto-discover matches.

**Architecture:** The `LocationPickerSheet` widget already exists with searchable map + GPS + save-to-Appwrite. Modify `FindNearbyMatchScreen` to show a "Set Location" setup state when no location is saved, and a compact location bar with edit button when location exists. Open `LocationPickerSheet` on "Pick on Map" tap. After location save, auto-trigger match discovery.

**Tech Stack:** Flutter, Riverpod, flutter_map, Appwrite

---

### Task 1: Refactor location state — add explicit `needsSetup` flag

**Files:**
- Modify: `lib/features/find_nearby/providers/user_location_provider.dart:1-155`

- [ ] **Step 1: Add `needsSetup` computed getter to `UserLocationState`**

At line 41 (inside `UserLocationState`), add:

```dart
  bool get needsSetup => isLoaded && location == null;
```

This replaces the current pattern of checking `error != null` to decide if user needs to set location. The `error` field becomes purely for error display.

Full `UserLocationState` after change (lines 11-42):

```dart
class UserLocationState {
  final LatLng? location;
  final String? locationName;
  final bool isLoaded;
  final bool isSaving;
  final String? error;

  const UserLocationState({
    this.location,
    this.locationName,
    this.isLoaded = false,
    this.isSaving = false,
    this.error,
  });

  UserLocationState copyWith({
    LatLng? location,
    String? locationName,
    bool? isLoaded,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return UserLocationState(
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get needsSetup => isLoaded && location == null;
}
```

- [ ] **Step 2: Verify the change compiles**

Run: `flutter analyze lib/features/find_nearby/providers/user_location_provider.dart`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/find_nearby/providers/user_location_provider.dart
git commit -m "refactor(user_location): add needsSetup computed getter to state"
```

---

### Task 2: Refactor FindNearbyMatchScreen — setup state vs map state

**Files:**
- Modify: `lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart:1-713`

- [ ] **Step 1: Add import for LocationPickerSheet**

At the top of the file, add after the existing imports (after line 18):

```dart
import '../../../../widgets/location_picker_sheet.dart';
```

- [ ] **Step 2: Refactor the `build` method to branch on `needsSetup`**

Replace the `build` method at lines 182-204:

```dart
  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(nearbyMatchesNotifierProvider);
    final locState = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: locState.needsSetup
            ? _buildLocationSetup(locState)
            : Column(
                children: [
                  _buildAppBar(),
                  _buildLocationBar(locState),
                  _buildFilters(),
                  Expanded(
                    child: _mapExpanded
                        ? _buildMapWithOverlay(matchesAsync, locState)
                        : _buildList(matchesAsync),
                  ),
                ],
              ),
      ),
    );
  }
```

- [ ] **Step 3: Add `_onEditLocation` method and refactor init**

After `_useGpsLocation` (line 152), add:

```dart
  Future<void> _onEditLocation() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
    if (!mounted) return;
    _discover();
  }
```

Update `_initScreen` at lines 66-81 to use `_onEditLocation` approach — the location listener should trigger `_discover`:

```dart
  Future<void> _initScreen() async {
    final auth = ref.read(authProvider);
    final userId = auth.userId;
    if (userId == null) return;

    await ref.read(userLocationProvider.notifier).loadLocation(userId);

    final locState = ref.read(userLocationProvider);
    if (locState.location != null) {
      _discover();
    }

    ref.listenManual(userLocationProvider, (prev, next) {
      if (prev?.location != next.location && next.location != null) {
        _mapController.move(next.location!, 13);
        _discover();
      }
    });
  }
```

- [ ] **Step 4: Add `_buildLocationSetup` widget**

Add after `_buildAppBar` (after line 245):

```dart
  Widget _buildLocationSetup(UserLocationState locState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.heroCtaGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardinal.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Set Your Location',
            style: AppTheme.bebasDisplay.copyWith(
              fontSize: 32,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need your location to find\nnearby matches and players.',
            textAlign: TextAlign.center,
            style: AppTheme.dmSans.copyWith(
              fontSize: 14,
              color: AppTheme.mutedParchment,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _SetupOptionCard(
            icon: Icons.map_rounded,
            title: 'Pick on Map',
            subtitle: 'Search or tap to select your location',
            color: AppTheme.cardinal,
            onTap: _onEditLocation,
          ),
          const SizedBox(height: 14),
          _SetupOptionCard(
            icon: Icons.my_location_rounded,
            title: 'Use Current Location',
            subtitle: 'Detect your location via GPS',
            color: AppTheme.sparkBlue,
            onTap: _useGpsLocation,
          ),
          if (locState.isSaving)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.cardinal,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saving location...',
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.gold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
```

- [ ] **Step 5: Replace `_buildLocationSearch` with `_buildLocationBar`**

Replace the method at lines 247-312 (`_buildLocationSearch`) with:

```dart
  Widget _buildLocationBar(UserLocationState locState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: _onEditLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: AppTheme.cardBorder,
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppTheme.cardinal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locState.locationName ?? 'Your location',
                      style: AppTheme.dmSans.copyWith(
                        color: AppTheme.parchment,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to change',
                      style: AppTheme.dmSans.copyWith(
                        color: AppTheme.gold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (locState.isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.cardinal,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.edit_rounded, color: AppTheme.gold, size: 16),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 6: Add `_SetupOptionCard` private widget class**

Add at the bottom of the file (after `_MatchListTile`, before the final `}`):

```dart
class _SetupOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SetupOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.parchment,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.dmSans.copyWith(
                      color: AppTheme.mutedParchment,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Remove unused `_searchController`, `_searchFocus`, `_searchDebounce`, `_searchResults`, `_showResults`**

Remove these field declarations at lines 38-42:

```dart
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Venue> _searchResults = [];
  bool _showResults = false;
  Timer? _searchDebounce;
```

Replace with:

```dart
```

Remove the dispose calls for them at lines 59-63 in `dispose()`:

```dart
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
```

Remove the `_onSearchChanged` method at lines 99-118.

Update `_useGpsLocation` at lines 133-152 — remove references to `_searchController`, `_searchFocus`:

```dart
  Future<void> _useGpsLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final permission2 = await Geolocator.checkPermission();
      if (permission2 == LocationPermission.whileInUse ||
          permission2 == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        ref
            .read(userLocationProvider.notifier)
            .setGpsLocation(LatLng(position.latitude, position.longitude));
        _discover();
      }
    } catch (_) {}
  }
```

- [ ] **Step 8: Remove unused imports**

Remove these import lines from the top of the file:
- Line 3: `import 'dart:ui';` (if BackdropFilter removed from app bar later, keep for now — skip this one)
- Line 12: `import '../../../../services/nominatim_service.dart';`  (no longer needed)

Actually check: `BackdropFilter` still uses `dart:ui` in `_buildAppBar`, so keep that import. Only remove `nominatim_service.dart`.

- [ ] **Step 9: Verify it compiles**

Run: `flutter analyze lib/features/find_nearby/`
Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart
git commit -m "refactor(find_nearby): add location setup state with map picker and GPS options"
```

---

### Task 3: Wire `_useGpsLocation` to also save to Appwrite

**Files:**
- Modify: `lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart`

Currently `setGpsLocation` only updates local state without saving to Appwrite. When user uses GPS from the setup screen, we should persist it.

- [ ] **Step 1: Update `_useGpsLocation` to save via Appwrite**

Replace the `_useGpsLocation` method with this version that also persists:

```dart
  Future<void> _useGpsLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final permission2 = await Geolocator.checkPermission();
      if (permission2 == LocationPermission.whileInUse ||
          permission2 == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        final auth = ref.read(authProvider);
        final loc = LatLng(position.latitude, position.longitude);
        await ref.read(userLocationProvider.notifier).saveGpsLocation(
              loc,
              auth.userId ?? '',
            );
        _discover();
      }
    } catch (_) {}
  }
```

- [ ] **Step 2: Add `saveGpsLocation` to `UserLocationNotifier`**

In `lib/features/find_nearby/providers/user_location_provider.dart`, after `setGpsLocation` (line 139), add:

```dart
  /// Set location from GPS and persist to Appwrite.
  Future<void> saveGpsLocation(LatLng loc, String userId) async {
    state = state.copyWith(
      location: loc,
      locationName: 'Current Location',
      isLoaded: true,
      isSaving: true,
      clearError: true,
    );
    try {
      await _appwriteService.updateUserLocation(
        userId: userId,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationName: 'Current Location',
      );
    } catch (_) {}
    state = state.copyWith(isSaving: false);
  }
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/find_nearby/`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/find_nearby/presentation/screens/find_nearby_match_screen.dart lib/features/find_nearby/providers/user_location_provider.dart
git commit -m "feat(find_nearby): persist GPS location to Appwrite on setup"
```
