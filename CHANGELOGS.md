# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

### 🎯 What This Phase Will Achieve:
Expand the app from a single-role rider app into a full 3-role system — Super Admin, Barangay Official, and Rider. Adds role-based routing, Admin screens (dashboard, request inbox, manage officials, global map), Barangay Official screens (dashboard, submit request, request history, notifications), barangay boundary enforcement, and an in-app notification system.

---

### 📋 Implementation Steps

| Step | Task | Risk | Status |
|------|------|------|--------|
| 7.1 | Update `RestrictedArea` model — add `status`, `barangay_id`, `submitted_by_uid`, `remarks`, `rejection_reason`, `approved_at`, `approved_by_uid` fields with defaults | None | ✅ Done |
| 7.2 | Update Sign Up screen — write `role: "rider"` on register | None | ✅ Done |
| 7.3 | Update `AuthWrapper` — role-based routing to 3 navigation screens | Low | ✅ Done |
| 7.4 | Seed Super Admin in Firestore console manually | None | ⏳ Pending |
| 7.5 | Update `streamRestrictedAreas()` — replaced with `streamApprovedAreas()` filter `status == "approved"` | Low | ✅ Done |
| 7.6 | Remove Add Restricted Area button from rider UI (map screen + profile screen) | None | ✅ Done |
| 7.7 | Create `AdminNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.8 | Build Admin Home Dashboard (stat cards, recent activity feed) | None | ⏳ Pending |
| 7.9 | Build Request Inbox + Detail screen + Approve/Reject flow | None | ⏳ Pending |
| 7.10 | Build Manage Officials + Create Official form | None | ⏳ Pending |
| 7.11 | Build Admin Global Map with filter chips + Add Zone directly | None | ⏳ Pending |
| 7.12 | Create `BarangayNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.13 | Build Barangay Home Dashboard (zone stats, request summary, bell icon) | None | ⏳ Pending |
| 7.14 | Build Submit Request screen (extend existing map-tap logic) | None | ⏳ Pending |
| 7.15 | Implement barangay boundary check — Option A circle (Haversine reuse) | None | ⏳ Pending |
| 7.16 | Build My Requests screen — 3 inner tabs (Pending / Approved / Rejected) | None | ⏳ Pending |
| 7.17 | Build Notifications screen + bell icon on Barangay Home | None | ⏳ Pending |
| 7.18 | Write Firestore notification documents on approve / reject / submit events | Low | ⏳ Pending |
| 7.19 | Tighten Firestore security rules (all roles) | **HIGH** | ⏳ Pending |
| 7.20 | Add FCM push notifications (optional, add last) | Low | ⏳ Pending |

---

### ✅ Completed So Far (Steps 7.1–7.7 + 7.12)

#### 1. New Model — `AppUser` (`lib/models/app_user.dart`)
- **Added:** New file — uid, name, email, role, barangayId, barangayName, isActive, createdAt, createdBy
- **Added:** Convenience getters: `isSuperAdmin`, `isBarangayOfficial`, `isRider`
- **Added:** `fromMap()` and `toMap()` for Firestore serialization

#### 2. Updated `RestrictedArea` Model (`lib/models/restricted_area.dart`)
- **Added:** `status` field — `"pending"` | `"approved"` | `"rejected"`, defaults to `"approved"` for backward compatibility with old docs
- **Added:** `barangayId`, `submittedByUid`, `remarks`, `rejectionReason`, `approvedAt`, `approvedByUid` fields (all nullable)
- **Kept:** All existing fields unchanged — `id`, `name`, `latitude`, `longitude`, `radius`, `createdBy`, `createdAt`
- **Kept:** Haversine `containsPoint()` logic untouched

#### 3. Updated `FirestoreService` (`lib/services/firestore_service.dart`)
- **Added:** `getUser(uid)` — reads `/users/{uid}` doc, returns `AppUser?`
- **Added:** `createUserDoc(AppUser)` — writes new user document to Firestore
- **Added:** `streamApprovedAreas()` — real-time stream filtered by `status == "approved"` (replaces old `getRestrictedAreas`)
- **Removed:** `getRestrictedAreas(userEmail)` — old method that loaded all areas filtered by `createdBy` email
- **Removed:** `streamRestrictedAreas()` — old unfiltered stream
- **Removed:** `deleteRestrictedArea(areaId, userEmail)` — replaced with `deleteRestrictedArea(docId)` (no email needed)

#### 4. Updated `AuthProvider` (`lib/providers/auth_provider.dart`)
- **Added:** `AppUser? _appUser` field — holds the Firestore user document
- **Added:** `appUser` getter — exposes full `AppUser` object
- **Added:** `role` getter — exposes `_appUser?.role` string
- **Added:** `_loadAppUser(uid)` — reads Firestore user doc after every login/auth state change
- **Added:** Deactivated account block — if `isActive == false`, login rejected with message `"Account deactivated. Contact administrator."`
- **Updated:** `signUp()` — now requires `name` parameter, creates Firestore user doc with `role: "rider"` on register
- **Updated:** `signIn()` — calls `_loadAppUser()` after Firebase Auth success
- **Removed:** Old `signUp()` that only called Firebase Auth without writing to Firestore

#### 5. Updated `SignupScreen` (`lib/screens/signup_screen.dart`)
- **Added:** `_nameController` — new text field for Full Name
- **Added:** Full Name field in form UI (above Email field)
- **Updated:** `signUp()` call now passes `name: _nameController.text`
- **Added:** `_nameController.dispose()` in `dispose()`

#### 6. Updated `RestrictedAreasProvider` (`lib/providers/restricted_areas_provider.dart`)
- **Updated:** `initialize()` — now takes zero arguments (old version required `userEmail`)
- **Updated:** Internally uses `streamApprovedAreas()` stream instead of `loadRestrictedAreas()`
- **Removed:** `_userEmail` field — no longer needed
- **Removed:** `loadRestrictedAreas()` — replaced by real-time stream
- **Kept:** `addRestrictedArea()`, `deleteRestrictedArea()`, `isPointInRestrictedArea()`, `getRestrictedAreaAtPoint()`, `clear()`

#### 7. Updated `AuthService` (`lib/services/auth_service.dart`)
- **Fixed:** File was accidentally overwritten with `auth_provider.dart` content during session — restored to correct implementation
- **Kept:** `signIn()`, `signUp()`, `signOut()`, `currentUser`, `authStateChanges`, `_handleAuthException()`

#### 8. Updated `main.dart`
- **Updated:** `AuthWrapper` — now routes by role: `superadmin` → `AdminNavigationScreen`, `barangay_official` → `BarangayNavigationScreen`, `rider` → `MainNavigationScreen`
- **Added:** Imports for `AdminNavigationScreen`, `BarangayNavigationScreen`
- **Kept:** All existing theme, providers, and route definitions

#### 9. Folder Restructure
- **Created:** `lib/screens/rider/` — all rider screens moved here
- **Moved:** `dashboard_screen.dart` → `lib/screens/rider/`
- **Moved:** `map_screen.dart` → `lib/screens/rider/`
- **Moved:** `profile_screen.dart` → `lib/screens/rider/`
- **Moved:** `main_navigation_screen.dart` → `lib/screens/rider/`
- **Updated:** All moved files — import paths updated from `../` to `../../`
- **Created:** `lib/screens/admin/` — new folder for Admin role
- **Created:** `lib/screens/barangay/` — new folder for Barangay Official role
- **Deleted:** `lib/screens/stats_screen.dart` — removed in Phase 6.1, dead file
- **Deleted:** `lib/screens/settings_screen.dart` — never wired up, dead file

#### 10. Admin Skeleton Screens (`lib/screens/admin/`)
- **Created:** `admin_navigation_screen.dart` — 4-tab bottom nav (Home, Requests, Officials, Map)
- **Created:** `admin_home_screen.dart` — placeholder "coming soon"
- **Created:** `admin_request_inbox_screen.dart` — placeholder "coming soon"
- **Created:** `admin_manage_officials_screen.dart` — placeholder "coming soon"
- **Created:** `admin_global_map_screen.dart` — repurposed from old `manage_restricted_areas_screen.dart`; lists all approved zones with delete, class renamed to `AdminGlobalMapScreen`, FAB shows "coming soon" snackbar, Add Zone screen navigation removed

#### 11. Barangay Skeleton Screens (`lib/screens/barangay/`)
- **Created:** `barangay_navigation_screen.dart` — 4-tab bottom nav (Home, Submit, Requests, Profile)
- **Created:** `barangay_home_screen.dart` — placeholder "coming soon"
- **Created:** `barangay_submit_request_screen.dart` — repurposed from old `add_restricted_area_screen.dart`; class renamed to `BarangaySubmitRequestScreen`, full map-tap logic preserved (will be extended in Step 7.14)
- **Created:** `barangay_my_requests_screen.dart` — placeholder "coming soon"
- **Created:** `barangay_profile_screen.dart` — placeholder "coming soon"

#### 12. Rider UI Cleanup
- **Removed:** "Manage Areas" `IconButton` from `map_screen.dart` AppBar — riders cannot manage zones per system flow
- **Removed:** `manage_restricted_areas_screen.dart` import from `profile_screen.dart`
- **Removed:** "Restricted Areas" settings item from `profile_screen.dart` — riders have no zone management access

---

### 🗂️ Final Folder Structure (after restructure)
```
lib/
├── main.dart
├── models/
│   ├── app_user.dart               ← NEW
│   └── restricted_area.dart        ← UPDATED
├── providers/
│   ├── auth_provider.dart          ← UPDATED
│   ├── bluetooth_provider.dart     ← untouched
│   ├── exhaust_provider.dart       ← untouched
│   └── restricted_areas_provider.dart ← UPDATED
├── services/
│   ├── auth_service.dart           ← RESTORED (was overwritten by mistake)
│   └── firestore_service.dart      ← UPDATED
├── screens/
│   ├── login_screen.dart           ← untouched
│   ├── signup_screen.dart          ← UPDATED
│   ├── splash_screen.dart          ← untouched
│   ├── rider/
│   │   ├── main_navigation_screen.dart   ← MOVED + imports fixed
│   │   ├── dashboard_screen.dart         ← MOVED + imports fixed
│   │   ├── map_screen.dart               ← MOVED + imports fixed + manage button removed
│   │   └── profile_screen.dart           ← MOVED + imports fixed + manage item removed
│   ├── admin/
│   │   ├── admin_navigation_screen.dart  ← NEW
│   │   ├── admin_home_screen.dart        ← NEW (skeleton)
│   │   ├── admin_request_inbox_screen.dart ← NEW (skeleton)
│   │   ├── admin_manage_officials_screen.dart ← NEW (skeleton)
│   │   └── admin_global_map_screen.dart  ← REPURPOSED + renamed
│   └── barangay/
│       ├── barangay_navigation_screen.dart     ← NEW
│       ├── barangay_home_screen.dart           ← NEW (skeleton)
│       ├── barangay_submit_request_screen.dart ← REPURPOSED + renamed
│       ├── barangay_my_requests_screen.dart    ← NEW (skeleton)
│       └── barangay_profile_screen.dart        ← NEW (skeleton)
└── utils/
    ├── app_colors.dart             ← untouched
    ├── app_text_styles.dart        ← untouched
    └── permission_handler.dart     ← untouched
```

---

### ⚠️ Known Issues / Still Pending Before Building New Screens
- [ ] Step 7.4 — Super Admin not yet seeded in Firestore console
- [ ] `flutter analyze` — confirm zero errors after all import fixes and git cleanup

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

#### 5. Animation Render Storm — Fixed
- **Root cause:** `AnimationController` + `_mapController.move()` called on every animation tick
- **Fix:** Removed `AnimationController`, `_latAnim`, `_lngAnim`, `SingleTickerProviderStateMixin` entirely
- Replaced with direct `_mapController.move()` call

#### 6. Firestore — Database Created + Rules Fixed
- Created Firestore database (Standard edition, `asia-southeast1`, production mode)
- **Fixed rules:** `allow read, write: if request.auth != null;`

#### 7. Firestore — `isActive` Filter Bug Fixed
- **File Modified:** `lib/services/firestore_service.dart`
- **Bug:** `.where('isActive', isEqualTo: true)` on docs that never had `isActive` → empty list
- **Fix:** Removed `isActive` filter from both methods

#### 8. Provider Initialization Bug Fixed
- **File Modified:** `lib/screens/main_navigation_screen.dart`
- **Bug:** `RestrictedAreasProvider.initialize()` was never called
- **Fix:** Added `initState` with `addPostFrameCallback`

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

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding

**Status:** ✅ COMPLETED — February 17, 2026

- Real OSM tiles via `flutter_map`
- Real-time GPS tracking (8s interval → upgraded to stream in 6.1)
- Reverse geocoding → human-readable address
- Live location sync to Dashboard + `isInRestrictedArea` badge

---

## [0.4.0] - Phase 4: Bluetooth Hardware Integration

**Status:** ✅ COMPLETED — February 17, 2026

- Real BLE scanning + connection via `flutter_blue_plus 1.31.15`
- 6 bugs fixed including splash never shown, connect button broken, wrong Android version detection

---

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI

**Status:** ✅ COMPLETED — February 11, 2026

- `AppPermissionHandler` — BT + GPS (Android 12+ support)
- 7 permissions in AndroidManifest
- Permission dialogs in splash screen flow

---

## [0.2.0] - Phase 2: Dashboard & Navigation

**Status:** ✅ COMPLETED — February 11, 2026

- Bottom Navigation (3 tabs after 6.1 cleanup), `IndexedStack`
- `RestrictedArea` model + Haversine formula
- Fixed `AuthWrapper` → `MainNavigationScreen` routing bug

---

## [0.1.0] - Phase 1: UI/UX Foundation & Branding

**Status:** 🔄 80% Complete

- Color system, typography, CustomButton, CustomTextField
- Branded splash screen, login/signup screens
- ⏳ Logo integration pending (waiting for asset)

---

## [0.0.1] - Core Foundation

**Status:** ✅ COMPLETED

- Flutter project, Firebase Auth, Provider state management, basic screens, Firestore service

---

## 📈 Version History Summary

| Version | Phase | Status | Date |
|---------|-------|--------|------|
| 0.0.1 | Foundation | ✅ Complete | Before Feb 11 |
| 0.1.0 | UI/UX | 🔄 80% | Feb 11, 2026 |
| 0.2.0 | Navigation | ✅ Complete | Feb 11, 2026 |
| 0.3.0 | Permissions | ✅ Complete | Feb 11, 2026 |
| 0.4.0 | Bluetooth | ✅ Complete | Feb 17, 2026 |
| 0.5.0 | GPS | ✅ Complete | Feb 17, 2026 |
| 0.6.0 | Map | ✅ Complete | Feb 17, 2026 |
| 0.6.1 | Patches & Background GPS | ✅ Complete | Mar 5, 2026 |
| **0.7.0** | **Multi-Role System** | **🔄 ~40% of phase done** | **Mar 2026** |
| 0.8.0 | Core Automation (BLE) | ⏸️ Blocked on ESP32 UUIDs | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 9, 2026