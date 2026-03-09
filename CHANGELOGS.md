# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

### 🎯 What This Phase Will Achieve:
Expand the app from a single-role rider app into a full 3-role system — Super Admin, Barangay Official, and Rider. Adds role-based routing, Admin screens (dashboard, request inbox, manage officials, global map), Barangay Official screens (dashboard, submit request, request history, notifications), barangay boundary enforcement, and an in-app notification system.

---

### 📋 Implementation Steps (in order)

| Step | Task | Risk | Status |
|------|------|------|--------|
| 7.1 | Update `RestrictedArea` model — add `status`, `barangay_id`, `submitted_by_uid`, `remarks`, `rejection_reason`, `approved_at`, `approved_by_uid` fields with defaults | None | ⏳ Pending |
| 7.2 | Update Sign Up screen — write `role: "rider"` on register | None | ⏳ Pending |
| 7.3 | Update `AuthWrapper` — role-based routing to 3 navigation screens | Low | ⏳ Pending |
| 7.4 | Seed Super Admin in Firestore console manually | None | ⏳ Pending |
| 7.5 | Update `streamRestrictedAreas()` — add `.where("status", isEqualTo: "approved")` filter | Low | ⏳ Pending |
| 7.6 | Remove Add Restricted Area button from rider UI (Dashboard home + disconnected state) | None | ⏳ Pending |
| 7.7 | Create `AdminNavigationScreen` + 4 skeleton screens | None | ⏳ Pending |
| 7.8 | Build Admin Home Dashboard (stat cards, recent activity feed) | None | ⏳ Pending |
| 7.9 | Build Request Inbox + Detail screen + Approve/Reject flow | None | ⏳ Pending |
| 7.10 | Build Manage Officials + Create Official form | None | ⏳ Pending |
| 7.11 | Build Admin Global Map with filter chips + Add Zone directly | None | ⏳ Pending |
| 7.12 | Create `BarangayNavigationScreen` + 4 skeleton screens | None | ⏳ Pending |
| 7.13 | Build Barangay Home Dashboard (zone stats, request summary, bell icon) | None | ⏳ Pending |
| 7.14 | Build Submit Request screen (extend existing add area logic, new file) | None | ⏳ Pending |
| 7.15 | Implement barangay boundary check — Option A circle (Haversine reuse) | None | ⏳ Pending |
| 7.16 | Build My Requests screen — 3 inner tabs (Pending / Approved / Rejected) | None | ⏳ Pending |
| 7.17 | Build Notifications screen + bell icon on Barangay Home | None | ⏳ Pending |
| 7.18 | Write Firestore notification documents on approve / reject / submit events | Low | ⏳ Pending |
| 7.19 | Tighten Firestore security rules (all roles) | **HIGH** | ⏳ Pending |
| 7.20 | Add FCM push notifications (optional, add last) | Low | ⏳ Pending |

---

### 🗂️ New Files (planned)
```
lib/
├── screens/
│   ├── admin/
│   │   ├── admin_navigation_screen.dart
│   │   ├── admin_home_screen.dart
│   │   ├── admin_request_inbox_screen.dart
│   │   ├── admin_request_detail_screen.dart
│   │   ├── admin_manage_officials_screen.dart
│   │   ├── admin_create_official_screen.dart
│   │   └── admin_global_map_screen.dart
│   └── barangay/
│       ├── barangay_navigation_screen.dart
│       ├── barangay_home_screen.dart
│       ├── barangay_submit_request_screen.dart
│       ├── barangay_my_requests_screen.dart
│       └── barangay_notifications_screen.dart
```

### 🗂️ Files Modified (planned)
```
lib/
├── models/restricted_area.dart          — model update
├── screens/auth/sign_up_screen.dart     — write role: "rider"
├── screens/auth/auth_wrapper.dart       — role routing
├── screens/home_screen.dart             — remove add area button
├── services/firestore_service.dart      — status filter on streamRestrictedAreas
└── utils/auth_provider.dart             — read role + is_active on login
```

---

### 🔒 Firestore Security Rules (Step 7.19 — do last)
```
/users/{uid}         — read/write own doc only OR superadmin
/barangays/{id}      — read: all authenticated | write: superadmin only
/restricted_areas/{id} — complex per-role rules (see flow doc)
/notifications/{id}  — read: recipient only | write: any authenticated
```

---

## [0.6.1] - Phase 6 Patches & Background GPS

**Status:** ✅ COMPLETED
**Date Completed:** March 5, 2026

### 🎯 What This Patch Achieved:
Removed Stats tab, rewrote restricted area creation with map-tap UI, fixed GPS to survive app backgrounding, fixed Firestore permission denial, fixed provider initialization bug that prevented areas from loading, and cleaned up animation render storm.

---

### ✅ Changes & Fixes

#### 1. Stats Tab Removed
- **File Modified:** `lib/screens/main_navigation_screen.dart`
- 4 tabs → 3 tabs: Home, Map, Profile
- `StatsScreen` import removed, indexes shifted (Profile: 3 → 2)

#### 2. Background GPS — Timer → Stream
- **File Modified:** `lib/screens/map_screen.dart`
- **Replaced:** `Timer.periodic` (dies when app backgrounds) with `Geolocator.getPositionStream()`
- Added `ForegroundNotificationConfig` — shows persistent "Location Active" notification required by Android to keep process alive
- Added `AndroidManifest.xml` permissions: `ACCESS_BACKGROUND_LOCATION`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`
- Registered `GeolocatorService` with `foregroundServiceType="location"`
- **File Modified:** `lib/utils/permission_handler.dart` — added background location request as step 3, strictly after foreground location granted

#### 3. Add Restricted Area — Full Rewrite (Map-Tap)
- **File Modified:** `lib/screens/add_restricted_area_screen.dart`
- **Removed:** Manual lat/lng/radius text fields
- **Added:** Tap map → red pin drops instantly → red circle preview renders → address auto-resolves in background
- Geocoding runs async with 8s timeout, falls back to raw coords on failure
- Name field auto-fills from barangay + municipality
- Radius picker: 50/100/200/300/500m buttons instead of text input
- On open, fetches real GPS and centers map there instead of hardcoded Manila coords
- `RestrictedArea` constructor corrected: `createdBy` + `createdAt` fields, removed wrong `userEmail` field
- Save button disabled until map point is tapped

#### 4. Address Format Upgrade
- **Files Modified:** `map_screen.dart`, `add_restricted_area_screen.dart`
- **Before:** Raw lat/lng coordinates displayed
- **After:** Street → Barangay → Municipality → Province → Region
- Example: `"Maharlika Highway, Brgy. Maybocog, Guiuan, Eastern Samar, Eastern Visayas"`

#### 5. Animation Render Storm — Fixed
- **Root cause:** `AnimationController` + `_mapController.move()` called on every animation tick → GPU frame overflow → device killed
- **Fix:** Removed `AnimationController`, `_latAnim`, `_lngAnim`, `SingleTickerProviderStateMixin` entirely from both `map_screen.dart` and `add_restricted_area_screen.dart`
- Replaced with direct `_mapController.move()` call — stable, no render storm

#### 6. Firestore — Database Created + Rules Fixed
- Created Firestore database (Standard edition, `asia-southeast1`, production mode)
- **Initial rules too strict** — only allowed `users/{userId}` path, blocked `restricted_areas` writes
- **Fixed rules:**
```
allow read, write: if request.auth != null;
```
- All authenticated users can read/write — appropriate for capstone scope

#### 7. Firestore — `isActive` Filter Bug Fixed
- **File Modified:** `lib/services/firestore_service.dart`
- **Bug:** `getRestrictedAreas()` and `streamRestrictedAreas()` filtered `.where('isActive', isEqualTo: true)` but saved documents never include `isActive` field → query returned empty list
- **Fix:** Removed `isActive` filter from both methods

#### 8. Provider Initialization Bug Fixed
- **File Modified:** `lib/screens/main_navigation_screen.dart`
- **Bug:** `RestrictedAreasProvider.initialize()` was never called — `_userEmail` stayed `null` so `loadRestrictedAreas()` returned immediately on every call
- **Fix:** Added `initState` with `addPostFrameCallback` to call `initialize()` with logged-in user's email after first frame
- Added imports: `provider`, `AuthProvider`, `RestrictedAreasProvider`

---

### 📦 AndroidManifest.xml Additions
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```
Plus `GeolocatorService` service declaration with `foregroundServiceType="location"`.

---

### 🐛 Bugs Fixed (7 total)

1. ✅ **Background GPS dies** — Timer → getPositionStream + foreground service
2. ✅ **Animation render storm** — AnimationController removed entirely
3. ✅ **Firestore PERMISSION_DENIED** — Security rules too restrictive
4. ✅ **Areas never load** — `isActive` filter removed from Firestore query
5. ✅ **Provider never initialized** — `initialize()` added to `MainNavigationScreen.initState`
6. ✅ **Add area opens at wrong location** — fetches real GPS on init
7. ✅ **Add area hangs on tap** — geocoding moved to background async, pin drops instantly

---

### 📊 Testing Results
- Map-tap area creation → pin drops instantly ✅
- Address resolves in background ✅
- Area saves to Firestore ✅
- Red circle appears on map after save ✅
- Background GPS notification shows ✅
- 3-tab navigation working ✅
- Verified on Infinix X6833B (Android 13) ✅

---

### 🎯 Impact on Project Progress
- **Overall Project (original scope):** 85% → **90%** (+5%)
- **Remaining:** Phase 7 (BLE automation) — blocked on ESP32 UUIDs from hardware team

---

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding

**Status:** ✅ COMPLETED
**Date Completed:** February 17, 2026

### 🎯 What This Phase Achieved:
Replaced the static placeholder map with a fully functional OpenStreetMap integration using `flutter_map`. Implemented real-time GPS tracking that updates every 8 seconds, reverse geocoding for human-readable addresses, and live location syncing between the Map screen and Dashboard. Removed all hardcoded coordinates and static UI elements.

---

### ✅ Features Added

#### 1. Real OpenStreetMap Integration
- **File Modified:** `lib/screens/map_screen.dart`
- Full rewrite — placeholder grid/mock map removed entirely
- Real OSM tiles via `TileLayer` with `flutter_map`
- Pinch to zoom, drag to pan — native map controls
- Zoom range: 5.0 (country) to 18.0 (street level)
- `MapController` for programmatic map control
- Center-on-user button snaps map back to current location
- Restricted area circles drawn on map as red overlays
- Motorcycle marker at user's real GPS position

#### 2. Real-Time GPS Tracking (8-Second Interval)
- `Geolocator.getCurrentPosition()` with `LocationAccuracy.high`
- `Timer.periodic` updates every 8 seconds (later upgraded to stream in 6.1)
- Map auto-centers on first GPS fix only
- Marker moves to real position on every update
- Graceful error handling — keeps last known position on failure

#### 3. Reverse Geocoding — Human-Readable Address
- **Package Added:** `geocoding: ^4.0.0`
- `placemarkFromCoordinates()` converts GPS coords to address
- Falls back to raw `lat, lng` string if geocoding fails
- Address pushed to `ExhaustProvider` via `updateLocation()`

#### 4. Live Location Sync to Dashboard
- Every GPS update calls `exhaustProvider.updateLocation()`
- `isInRestrictedArea` badge on dashboard updates in real time

---

### 📦 Packages Added
```yaml
flutter_map: ^8.2.2
latlong2: ^0.9.1
geocoding: ^4.0.0
```

---

### 🎯 Impact on Project Progress
- **Phase 5 (GPS):** 0% → **100%** ✅
- **Phase 6 (Map):** 0% → **100%** ✅
- **Overall Project:** 70% → **85%** (+15%)

---

## [0.4.0] - Phase 4: Bluetooth Hardware Integration

**Status:** ✅ COMPLETED
**Date Completed:** February 17, 2026

### 🎯 What This Phase Achieved:
Replaced the entire mock Bluetooth implementation with real BLE scanning and connection using flutter_blue_plus. Fixed 6 critical bugs discovered during physical device testing including the splash screen never being shown, the connect button being non-functional, incorrect Android version detection, and scan triggering multiple times.

---

### ✅ Features Added

#### 1. Real BLE Device Scanning
- **File Modified:** `lib/providers/bluetooth_provider.dart`
- Full rewrite — all mock/simulated code removed
- Real BLE scanning via `FlutterBluePlus.startScan()` with 5s timeout
- RSSI signal strength converted to 0-100% scale
- Auto-disconnect detection via `connectionState` stream
- `stopScan()` called before every `startScan()` to prevent duplicates

#### 2. Real BLE Connection
- Real `device.connect()` with 10s timeout
- Stores `BluetoothDevice` object reference for later commands (Phase 8)
- Real `device.disconnect()` on logout/manual disconnect

#### 3. Connect Button Fix
- **File Modified:** `lib/widgets/bluetooth_connection_modal.dart`
- Connect button had empty `onPressed: () {}` — tapping did nothing
- Fixed to call real `connectToDevice()` and show result snackbar

---

### 🐛 Bugs Fixed (6 total)
1. ✅ Splash screen never shown
2. ✅ Route conflict (`'/'` → `'/auth'`)
3. ✅ Wrong Android version detection
4. ✅ Connect button broken (empty `onPressed`)
5. ✅ Multiple scan triggers
6. ✅ flutter_blue_plus v2 paid license — downgraded to `1.31.15`

---

### 🎯 Impact on Project Progress
- **Phase 4 (Bluetooth):** 0% → **100%** ✅
- **Overall Project:** 55% → **70%** (+15%)

---

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI

**Status:** ✅ COMPLETED
**Date Completed:** February 11, 2026, 9:30 PM

### 🎯 What This Phase Achieved:
Implemented comprehensive permission system for Bluetooth and GPS, added professional UI components, configured app icon generation, and integrated permission requests into splash screen flow.

---

### ✅ Features Added

#### 1. Permission System
- **File Created:** `lib/utils/permission_handler.dart`
- Smart Bluetooth permission handling (Android 12+ support)
- GPS/Location permission management
- Beautiful permission request dialogs (Awesome Dialog)
- Handle denied/permanently denied scenarios
- Open settings helper for manually enabling permissions

#### 2. Enhanced Splash Screen
```
Splash Screen Launch → Logo Animation (1.5s) → Request BT Permission → Request Location Permission → Navigate to AuthWrapper
```

#### 3. Android Permissions Declaration
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

### 🎯 Impact on Project Progress
- **Phase 3 (Permissions):** 0% → **100%** ✅
- **Overall Project:** 42% → **55%** (+13%)

---

## [0.2.0] - Phase 2: Dashboard & Navigation

**Status:** ✅ COMPLETED
**Date Completed:** February 11, 2026, 8:56 PM

### ✅ Bug Fixes
- Fixed critical navigation bug: `AuthWrapper` was returning `HomeScreen` instead of `MainNavigationScreen`

### ✅ Features Added
- Bottom Navigation (4 Tabs): Home, Map, Stats, Profile
- `IndexedStack` for state preservation
- `RestrictedArea` model with Haversine formula for distance checking

---

### 🎯 Impact on Project Progress
- **Phase 2 (Navigation):** 0% → **100%** ✅
- **Overall Project:** 30% → **42%** (+12%)

---

## [0.1.0] - Phase 1: UI/UX Foundation & Branding

**Status:** 🔄 IN PROGRESS (80% Complete)
**Date Started:** February 11, 2026

### ✅ Completed:
- Professional color system (`lib/utils/app_colors.dart`)
- Typography system (`lib/utils/app_text_styles.dart`)
- CustomButton + CustomTextField components
- Branded splash screen
- Optimized login/signup screens

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
| 0.6.1 | Patches & Background GPS | ✅ Complete | 100% | Mar 5, 2026 |
| **0.7.0** | **Multi-Role System** | **🔄 In Progress** | **0%** | **Mar 2026** |
| 0.8.0 | Core Automation (BLE) | ⏸️ Planned | 0% | TBD |

---

## 🎯 Next Release: [0.7.0] - Multi-Role System Expansion

**Status:** 🔄 In Progress — starting from Step 7.1

### First steps:
1. Update `RestrictedArea` model (additive, no risk)
2. Update Sign Up to write `role: "rider"`
3. Update `AuthWrapper` for 3-role routing
4. Seed Super Admin in Firestore console manually

---

## 🎯 Future Release: [0.8.0] - Core Automation

**Target Date:** TBD — blocked on ESP32 BLE UUIDs from hardware team

### Planned Features:
- Define ESP32 BLE service/characteristic UUIDs with hardware team
- Send valve OPEN/CLOSE commands via BLE on geofence exit/entry
- Notification when exhaust state changes automatically
- Log history of automatic closures

---

**Maintained by:** Development Team
**Last Updated:** March 9, 2026
**Format:** [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)