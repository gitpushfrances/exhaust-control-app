# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding ⭐ NEW!

**Status:** ✅ COMPLETED
**Date Completed:** February 17, 2026

### 🎯 What This Phase Achieved:
Replaced the static placeholder map with a fully functional OpenStreetMap integration using `flutter_map`. Implemented real-time GPS tracking that updates every 8 seconds, reverse geocoding for human-readable addresses, and live location syncing between the Map screen and Dashboard. Removed all hardcoded coordinates and static UI elements.

---

### ✅ Features Added

#### 1. Real OpenStreetMap Integration
- **File Modified:** `lib/screens/map_screen.dart`
- **Features:**
  - ✅ Full rewrite — placeholder grid/mock map removed entirely
  - ✅ Real OSM tiles via `TileLayer` with `flutter_map`
  - ✅ Pinch to zoom, drag to pan — native map controls
  - ✅ Zoom range: 5.0 (country) to 18.0 (street level)
  - ✅ `MapController` for programmatic map control
  - ✅ Center-on-user button snaps map back to current location
  - ✅ Restricted area circles drawn on map as red overlays
  - ✅ Motorcycle marker at user's real GPS position

**Before (Placeholder):**
```dart
CustomPaint(size: Size.infinite, painter: _GridPainter())
// Fake grid with hardcoded Antipolo coords
```

**After (Real OSM):**
```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: LatLng(_currentLat, _currentLng),
    initialZoom: 15.0,
  ),
  children: [
    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    CircleLayer(circles: areasProvider.areas.map(...).toList()),
    MarkerLayer(markers: [...]),
  ],
)
```

#### 2. Real-Time GPS Tracking (8-Second Interval)
- **File Modified:** `lib/screens/map_screen.dart`
- **Features:**
  - ✅ `Geolocator.getCurrentPosition()` with `LocationAccuracy.high`
  - ✅ `Timer.periodic` updates every 8 seconds
  - ✅ Timer properly cancelled in `dispose()` — no memory leaks
  - ✅ Map auto-centers on first GPS fix only (user can pan freely after)
  - ✅ Marker moves to real position on every update
  - ✅ Graceful error handling — keeps last known position on failure

**GPS Timer Implementation:**
```dart
_locationTimer = Timer.periodic(
  const Duration(seconds: 8),
  (_) => _fetchLocation(),
);

// Auto-center on first fix only
if (!wasReady) {
  _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
}
```

#### 3. Reverse Geocoding — Human-Readable Address
- **File Modified:** `lib/screens/map_screen.dart`
- **Package Added:** `geocoding: ^4.0.0`
- **Features:**
  - ✅ `placemarkFromCoordinates()` converts GPS coords to address
  - ✅ Address built from: street + subLocality + locality + administrativeArea
  - ✅ Falls back to raw `lat, lng` string if geocoding fails
  - ✅ Address pushed to `ExhaustProvider` via `updateLocation()`
  - ✅ Dashboard location card shows human-readable address automatically

**Geocoding Implementation:**
```dart
final placemarks = await placemarkFromCoordinates(lat, lng);
final p = placemarks.first;
final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
    .where((s) => s != null && s.isNotEmpty).toList();
address = parts.join(', ');
// e.g. "Sumulong Highway, Antipolo, Calabarzon"
```

#### 4. Live Location Sync to Dashboard
- **File Modified:** `lib/screens/map_screen.dart`
- **Features:**
  - ✅ Every GPS update calls `exhaustProvider.updateLocation()`
  - ✅ Dashboard `_LocationInfoCard` reads from `ExhaustProvider` — no extra code needed
  - ✅ Restricted area check runs on every GPS update automatically
  - ✅ `isInRestrictedArea` badge on dashboard updates in real time

#### 5. Map Overlay UI Improvements
- **File Modified:** `lib/screens/map_screen.dart`
- **Features:**
  - ✅ Location overlay shows `"Fetching location..."` with amber indicator until first fix
  - ✅ After fix: shows raw coords + green `"8s"` refresh badge
  - ✅ Removed bottom info panel (Tracking/Speed/Trip Time) — not needed
  - ✅ Removed `_MapPlaceholder`, `_GridPainter`, `_MapSetupDialog` dead classes

---

### 📦 Packages Added

```yaml
flutter_map: ^8.2.2       # OpenStreetMap tile rendering + markers + circles
latlong2: ^0.9.1          # LatLng coordinate type for flutter_map
geocoding: ^4.0.0         # Reverse geocoding (coords → human address)
```

**Install commands used:**
```bash
flutter pub add flutter_map latlong2
flutter pub add geocoding
flutter pub get
```

---

### 📦 Files Modified Summary

```
lib/
└── screens/
    └── map_screen.dart    🔄 Full rewrite — real OSM, GPS, geocoding, live sync
```

---

### 🐛 Issues Resolved

1. ✅ **Hardcoded Antipolo coords** — replaced with real `Geolocator.getCurrentPosition()`
2. ✅ **Static marker** — now moves with user every 8 seconds
3. ✅ **Map auto-centering on every update** — fixed to only center on first fix
4. ✅ **Dashboard showing `"Location unavailable"`** — now shows real geocoded address
5. ✅ **Dead placeholder classes** — `_MapPlaceholder`, `_GridPainter`, `_MapSetupDialog` removed

---

### 📊 Testing Results

#### ✅ Verified Working on Infinix X6833B (Android 13):
- Map tab opens → Real OSM tiles load ✅
- Motorcycle marker appears at actual GPS position ✅
- Map auto-centers on first fix ✅
- User can pan/zoom freely after first fix ✅
- Marker updates every 8 seconds ✅
- Center button snaps back to user location ✅
- Red circles show restricted areas from Firestore ✅
- Dashboard location card shows human-readable address ✅
- Address updates every 8 seconds ✅
- Restricted area badge on dashboard updates in real time ✅

---

### 🎯 Impact on Project Progress

**Progress Update:**
- **Phase 5 (GPS):** 0% → **100%** ✅
- **Phase 6 (Map):** 0% → **100%** ✅
- **Overall Project:** 70% → **85%** (+15%)
- **Presentation Score:** 70 → **85/100**

**What's Now Production-Ready:**
- ✅ Real OpenStreetMap with live tiles
- ✅ GPS tracking every 8 seconds
- ✅ Human-readable address via reverse geocoding
- ✅ Dashboard + Map fully in sync via ExhaustProvider
- ✅ Restricted area detection on every GPS update

**What's Next (Phase 7):**
- Automatic exhaust valve control on geofence entry/exit
- ESP32 BLE command protocol definition
- Send open/close commands over BLE to hardware

---

### 📋 Developer Notes

#### Package Decisions:
- `flutter_map 8.2.2` — upgraded from 7.0.2 during install, API compatible
- `geocoding 4.0.0` — free, no API key needed, uses device's built-in geocoder
- Geocoding requires internet on Android for first resolution; falls back to raw coords offline

#### Remaining Tech Debt:
- Debug `print('>>> ...')` still in `splash_screen.dart` and `permission_handler.dart`
- BLE scan not filtered to ESP32 only
- ESP32 BLE UUIDs not yet defined (needed for Phase 7)
- Background location not implemented (app must be open for tracking)

---

## [0.4.0] - Phase 4: Bluetooth Hardware Integration

**Status:** ✅ COMPLETED
**Date Completed:** February 17, 2026

### 🎯 What This Phase Achieved:
Replaced the entire mock Bluetooth implementation with real BLE scanning and connection using flutter_blue_plus. Fixed 6 critical bugs discovered during physical device testing including the splash screen never being shown, the connect button being non-functional, incorrect Android version detection, and scan triggering multiple times. App now scans for and connects to real physical BLE devices on Infinix X6833B (Android 13).

---

### ✅ Features Added

#### 1. Real BLE Device Scanning
- **File Modified:** `lib/providers/bluetooth_provider.dart`
- **Features:**
  - ✅ Full rewrite — all mock/simulated code removed
  - ✅ Real BLE scanning via `FlutterBluePlus.startScan()` with 5s timeout
  - ✅ System bonded devices via `FlutterBluePlus.connectedDevices`
  - ✅ RSSI signal strength converted to 0-100% scale
  - ✅ Real device name from `platformName` and `advertisementData.advName`
  - ✅ Auto-disconnect detection via `connectionState` stream
  - ✅ `stopScan()` called before every `startScan()` to prevent duplicates

**Before (Mock):**
```dart
await Future.delayed(const Duration(seconds: 2));
_availableDevices.addAll([
  {'id': 'device_002', 'name': 'Exhaust Ctrl #2', 'signalStrength': 72},
]);
```

**After (Real):**
```dart
await FlutterBluePlus.stopScan();
await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
FlutterBluePlus.scanResults.listen((results) {
  for (final r in results) {
    final signal = (r.rssi + 100).clamp(0, 100);
    _availableDevices.add({
      'id': r.device.remoteId.str,
      'name': r.device.platformName,
      'signalStrength': signal,
      'device': r.device,
    });
  }
  notifyListeners();
});
```

#### 2. Real BLE Connection
- **File Modified:** `lib/providers/bluetooth_provider.dart`
- **Features:**
  - ✅ Real `device.connect()` with 10s timeout
  - ✅ Stores `BluetoothDevice` object reference for later commands
  - ✅ Real `device.disconnect()` on logout/manual disconnect
  - ✅ Connection state listener for auto-disconnect handling

**Before (Mock):**
```dart
await Future.delayed(const Duration(seconds: 2));
_isConnected = true;
```

**After (Real):**
```dart
await device.connect(timeout: const Duration(seconds: 10));
_connectedDevice = device;
_isConnected = true;
device.connectionState.listen((state) {
  if (state == BluetoothConnectionState.disconnected) {
    _isConnected = false;
    notifyListeners();
  }
});
```

#### 3. Connect Button Fix
- **File Modified:** `lib/widgets/bluetooth_connection_modal.dart`
- **Issue:** Connect button had empty `onPressed: () {}` — tapping did nothing
- **Fix:** Button now calls real `connectToDevice()` and shows result snackbar

**Before:**
```dart
onPressed: isConnecting ? null : () {},
```

**After:**
```dart
onPressed: isConnecting ? null : () async {
  final success = await bluetoothProvider.connectToDevice(
    device['id'], device['name'],
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? '✓ Connected' : '✕ Failed'),
    ));
    if (success) Navigator.pop(context);
  }
},
```

---

### 🐛 Bugs Fixed (6 total)

#### Bug 1: Splash Screen Never Shown (Critical)
- **Issue:** `home: const AuthWrapper()` in `main.dart` — `SplashScreen` existed but was never used
- **Root Cause:** Wrong widget set as `home` in `MaterialApp`
- **Fix:** Changed `home:` to `const SplashScreen()`

```dart
// BEFORE: home: const AuthWrapper(),
// AFTER:  home: const SplashScreen(),
```

#### Bug 2: Route Conflict Error
- **Fix:** Renamed `'/'` route to `'/auth'` and updated splash navigation target

#### Bug 3: Wrong Android Version Detection (Critical)
- **Fix:** Used `device_info_plus` to check actual `sdkInt`

```dart
final androidInfo = await DeviceInfoPlugin().androidInfo;
return androidInfo.version.sdkInt >= 31;
```

#### Bug 4: flutter_blue_plus v2 Paid License
- **Fix:** Downgraded to `flutter_blue_plus: 1.31.15`

#### Bug 5: Multiple Scan Triggers
- **Fix:** Added `await FlutterBluePlus.stopScan()` before every `startScan()`

#### Bug 6: Permission Dialogs Not Appearing
- **Root Cause:** Same as Bug 1 — resolved as part of Bug 1

---

### 📦 Files Modified Summary

```
lib/
├── main.dart                              🔄 home → SplashScreen, '/' → '/auth'
├── providers/
│   └── bluetooth_provider.dart           🔄 Full rewrite — real BLE
├── screens/
│   └── splash_screen.dart                🔄 Navigate to '/auth' instead of '/'
└── widgets/
    └── bluetooth_connection_modal.dart    🔄 Fixed connect button onPressed

pubspec.yaml                              🔄 flutter_blue_plus 2.1.0 → 1.31.15
```

---

### 📊 Testing Results

#### ✅ Verified Working on Infinix X6833B (Android 13):
- App launch → Splash screen shows ✅
- Splash → Permission dialogs appear ✅
- Permissions granted → Navigate to login ✅
- Login → Dashboard loads ✅
- Tap "Not Connected" card → BT modal opens ✅
- Tap Scan → Real nearby BLE devices appear ✅
- Signal strength shown per device ✅
- Tap Connect → Real connection attempt made ✅
- Success/failure snackbar shows ✅
- Dashboard updates to "Connected" state ✅
- Auto-disconnect detected and dashboard updates ✅

---

### 🎯 Impact on Project Progress

- **Phase 4 (Bluetooth):** 0% → **100%** ✅
- **Overall Project:** 55% → **70%** (+15%)
- **Presentation Score:** 55 → **70/100**

---

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI

**Status:** ✅ COMPLETED
**Date Completed:** February 11, 2026, 9:30 PM

### 🎯 What This Phase Achieved:
Implemented comprehensive permission system for Bluetooth and GPS, added professional UI components (FontAwesome icons, Awesome Dialog alerts), configured app icon generation, and integrated permission requests into splash screen flow.

---

### ✅ Features Added

#### 1. Permission System
- **File Created:** `lib/utils/permission_handler.dart`
- **Features:**
  - ✅ Smart Bluetooth permission handling (Android 12+ support)
  - ✅ GPS/Location permission management
  - ✅ Beautiful permission request dialogs (Awesome Dialog)
  - ✅ Handle denied/permanently denied scenarios
  - ✅ Automatic retry logic
  - ✅ Open settings helper for manually enabling permissions

#### 2. Enhanced Splash Screen
- **File Updated:** `lib/screens/splash_screen.dart`
- **Flow:**
```
Splash Screen Launch → Logo Animation (1.5s) → Request BT Permission → Request Location Permission → Navigate to AuthWrapper
```

#### 3. Professional UI Packages
```yaml
font_awesome_flutter: ^10.7.0
awesome_dialog: ^3.2.1
flutter_svg: ^2.0.10
lottie: ^3.1.2
flutter_launcher_icons: ^0.14.1
device_info_plus: ^10.1.0
```

#### 4. Android Permissions Declaration
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

### 🐛 Issues Resolved

1. ✅ `use_build_context_synchronously` — added `if (!context.mounted) return false;`
2. ✅ `openAppSettings()` expects 0 arguments — removed context parameter

---

### 🎯 Impact on Project Progress

- **Phase 3 (Permissions):** 0% → **100%** ✅
- **Overall Project:** 42% → **55%** (+13%)

---

## [0.2.0] - Phase 2: Dashboard & Navigation

**Status:** ✅ COMPLETED
**Date Completed:** February 11, 2026, 8:56 PM

### 🎯 What This Phase Achieved:
Fixed critical navigation bug that prevented users from accessing the full app after login. Integrated existing 4-tab navigation system and resolved all compilation errors.

---

### ✅ Bug Fixes

#### Critical Navigation Bug Fixed
```dart
// BEFORE: return const HomeScreen();
// AFTER:  return const MainNavigationScreen();
```

---

### ✅ Features Added

#### Bottom Navigation (4 Tabs)
- 🏠 **Home** → `DashboardScreen`
- 🗺️ **Map** → `MapScreen`
- 📊 **Stats** → `StatsScreen`
- 👤 **Profile** → `ProfileScreen`
- Uses `IndexedStack` for state preservation

#### Stats Screen
- User info card, statistics grid, recent activity timeline, weekly chart

#### RestrictedArea Model
```dart
Map<String, dynamic> toMap()
factory fromMap(Map, String id)
bool containsPoint(double lat, double lng)  // Haversine formula
double _calculateDistance(lat1, lng1, lat2, lng2)
```

---

### 🎯 Impact on Project Progress

- **Phase 2 (Navigation):** 0% → **100%** ✅
- **Overall Project:** 30% → **42%** (+12%)

---

## [0.1.0] - Phase 1: UI/UX Foundation & Branding

**Status:** 🔄 IN PROGRESS (80% Complete)
**Date Started:** February 11, 2026

### ✅ Completed:
- ✅ Professional color system (`lib/utils/app_colors.dart`)
- ✅ Typography system (`lib/utils/app_text_styles.dart`)
- ✅ CustomButton widget
- ✅ CustomTextField widget
- ✅ Branded splash screen
- ✅ Optimized login/signup screens
- ✅ Updated theme in main.dart

### 🔄 Pending:
- ⏳ ReWatch logo integration (waiting for asset file)
- ⏸️ Final animation polish
- ⏸️ Dark mode preparation

---

## [0.0.1] - Core Foundation

**Status:** ✅ COMPLETED
**Date Completed:** Before February 11, 2026

### ✅ Initial Setup:
- Flutter project initialization
- Firebase authentication setup
- Basic login/signup screens
- Auth provider with state management
- Auth service with Firebase integration
- Firestore service setup
- Bluetooth provider (placeholder)
- Restricted areas provider
- Dashboard, profile, map screens (basic)
- Navigation screen structure

### 📦 Initial Dependencies:
```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
provider: ^6.1.5+1
shared_preferences: ^2.5.4
flutter_blue_plus: 1.31.15
geolocator: ^14.0.2
permission_handler: ^12.0.1
font_awesome_flutter: ^10.7.0
awesome_dialog: ^3.2.1
flutter_svg: ^2.0.10
lottie: ^3.1.2
device_info_plus: ^10.1.0
```

---

## 📈 Version History Summary

| Version | Phase | Status | Completion | Date |
|---------|-------|--------|------------|------|
| 0.0.1 | Foundation | ✅ Complete | 100% | Before Feb 11 |
| 0.1.0 | UI/UX | 🔄 In Progress | 80% | Feb 11, 2026 |
| 0.2.0 | Navigation | ✅ Complete | 100% | Feb 11, 2026 |
| 0.3.0 | Permissions | ✅ Complete | 100% | Feb 11, 2026 |
| 0.4.0 | Bluetooth | ✅ Complete | 100% | Feb 17, 2026 |
| 0.5.0 | GPS | ✅ Complete | 100% | Feb 17, 2026 |
| 0.6.0 | Map | ✅ Complete | 100% | Feb 17, 2026 |
| 0.7.0 | Automation | ⏸️ Planned | 0% | Feb 18, 2026 |

---

## 🎯 Next Release: [0.7.0] - Core Automation

**Target Date:** February 18-20, 2026

### Planned Features:
- Define ESP32 BLE service/characteristic UUIDs with hardware team
- Send valve open/close commands over BLE
- Automatic exhaust control triggered by geofence entry/exit
- Notification when exhaust state changes automatically
- History/log of automatic closures

---

**Maintained by:** Development Team
**Last Updated:** February 17, 2026
**Format:** [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)