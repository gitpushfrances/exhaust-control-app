# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 9, 2026

---

## 🎯 Overall Progress: ~55% Complete
> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Original rider-only scope was 90% complete. Role expansion resets overall completion to ~55%.

```
[██████████████████░░░░░░░░░░░░░░] 55%
```

### Scope Breakdown:
| Scope | Progress |
|-------|----------|
| Rider functionality (original scope) | ~95% — minor removals pending |
| Super Admin screens | 0% — build from scratch |
| Barangay Official screens | 0% — build from scratch |
| Phase 8 BLE Automation | 0% — blocked on ESP32 UUIDs |

---

### Phase Breakdown:
- ✅ **Foundation:** 100% Complete
- 🔄 **Phase 1 (UI/UX):** 80% Complete (logo pending)
- ✅ **Phase 2 (Navigation):** 100% Complete
- ✅ **Phase 3 (Permissions):** 100% Complete
- ✅ **Phase 4 (Bluetooth):** 100% Complete
- ✅ **Phase 5 (GPS):** 100% Complete
- ✅ **Phase 6 (Map):** 100% Complete
- ✅ **Phase 6.1 (Patches):** 100% Complete
- 🔄 **Phase 7 (Multi-Role System):** 0% — active next
- ⏸️ **Phase 8 (BLE Automation):** 0% — blocked on ESP32 UUIDs

---

## 📋 PHASE DETAILS

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (0% — Starting Now)

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

#### Progress: 0%
```
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0%
```

#### Step Checklist:

**Group A — Low-risk additive changes (do first)**
- [ ] 7.1 — Update `RestrictedArea` model (new fields with defaults)
- [ ] 7.2 — Update Sign Up screen → write `role: "rider"` on register
- [ ] 7.3 — Update `AuthWrapper` → route to 3 navigation screens by role
- [ ] 7.4 — Seed Super Admin manually in Firestore console
- [ ] 7.5 — Update `streamRestrictedAreas()` → filter `status == "approved"`
- [ ] 7.6 — Remove Add Restricted Area button from rider UI

**Group B — Admin screens (new files only)**
- [ ] 7.7 — `AdminNavigationScreen` + 4 skeleton screens
- [ ] 7.8 — Admin Home Dashboard (stat cards, recent activity)
- [ ] 7.9 — Request Inbox + Detail screen + Approve/Reject flow
- [ ] 7.10 — Manage Officials + Create Official form
- [ ] 7.11 — Admin Global Map (filter chips, add zone directly)

**Group C — Barangay Official screens (new files only)**
- [ ] 7.12 — `BarangayNavigationScreen` + 4 skeleton screens
- [ ] 7.13 — Barangay Home Dashboard
- [ ] 7.14 — Submit Request screen (extend existing map-tap logic)
- [ ] 7.15 — Barangay boundary check (Option A — Haversine circle)
- [ ] 7.16 — My Requests screen (3 inner tabs: Pending / Approved / Rejected)
- [ ] 7.17 — Notifications screen + bell icon

**Group D — Wiring + security (do last)**
- [ ] 7.18 — Write Firestore notification documents on approve/reject/submit
- [ ] 7.19 — ⚠️ Tighten Firestore security rules (HIGH RISK — test all roles after)
- [ ] 7.20 — FCM push notifications (optional)

#### Estimated Time:
| Task | Estimate |
|------|----------|
| RestrictedArea model update | 30 min |
| Role routing in AuthWrapper | 1 hr |
| Super Admin all 4 screens | 2–3 days |
| Barangay Official all 4 screens | 1.5–2 days |
| Boundary enforcement (Option A) | 2 hrs |
| Notification documents | 3 hrs |
| Firestore security rules | 2 hrs |
| FCM push (optional) | 4 hrs |

#### New Files (planned):
```
lib/screens/admin/
├── admin_navigation_screen.dart
├── admin_home_screen.dart
├── admin_request_inbox_screen.dart
├── admin_request_detail_screen.dart
├── admin_manage_officials_screen.dart
├── admin_create_official_screen.dart
└── admin_global_map_screen.dart

lib/screens/barangay/
├── barangay_navigation_screen.dart
├── barangay_home_screen.dart
├── barangay_submit_request_screen.dart
├── barangay_my_requests_screen.dart
└── barangay_notifications_screen.dart
```

#### Files to Modify (planned):
```
lib/models/restricted_area.dart
lib/screens/auth/sign_up_screen.dart
lib/screens/auth/auth_wrapper.dart
lib/screens/home_screen.dart
lib/services/firestore_service.dart
lib/utils/auth_provider.dart
```

---

### ✅ PHASE 6.1: PATCHES & BACKGROUND GPS (100% Complete)

**Status:** ✅ COMPLETE
**Completion Date:** March 5, 2026

#### Completed Tasks:
- [x] Remove Stats tab — 4 tabs → 3 tabs (Home, Map, Profile)
- [x] Replace `Timer.periodic` with `Geolocator.getPositionStream()` for background GPS
- [x] Add foreground service notification for background location
- [x] Add background location permissions to AndroidManifest
- [x] Add background location runtime request to permission handler
- [x] Rewrite Add Restricted Area screen — map-tap instead of manual lat/lng
- [x] Pin drops instantly on tap, geocoding runs async in background
- [x] Address format: Street → Barangay → Municipality → Province → Region
- [x] Map centers on real GPS on open (not hardcoded Manila)
- [x] Fix `RestrictedArea` constructor — `createdBy`/`createdAt`, removed `userEmail`
- [x] Remove `AnimationController` render storm — replaced with direct `_mapController.move()`
- [x] Create Firestore database (Standard, asia-southeast1, production mode)
- [x] Fix Firestore security rules — `PERMISSION_DENIED` on writes
- [x] Fix `isActive` filter bug in `firestore_service.dart` — areas never loading
- [x] Fix provider initialization — `RestrictedAreasProvider.initialize()` never called
- [x] Push to GitHub main branch

---

### ✅ PHASE 6: MAP INTEGRATION (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] `flutter_map` + OSM tiles
- [x] Motorcycle marker at real GPS position
- [x] Red circle overlays for restricted areas
- [x] `MapController` + center-on-user button

---

### ✅ PHASE 5: GPS & LOCATION SERVICES (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] `Geolocator` high-accuracy GPS
- [x] Reverse geocoding → human-readable address
- [x] Live location + `isInRestrictedArea` badge on dashboard

---

### ✅ PHASE 4: BLUETOOTH INTEGRATION (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] Real BLE scanning + connection via `flutter_blue_plus 1.31.15`
- [x] `BluetoothDevice` reference stored for Phase 8 commands
- [x] 6 bugs fixed (see CHANGELOG)

---

### ✅ PHASE 3: DEVICE PERMISSIONS (100% Complete)

**Status:** ✅ COMPLETE — February 11, 2026

- [x] `AppPermissionHandler` — BT + GPS (Android 12+ support)
- [x] 7 permissions in AndroidManifest

---

### ✅ PHASE 2: DASHBOARD & NAVIGATION (100% Complete)

**Status:** ✅ COMPLETE — February 11, 2026

- [x] AuthWrapper → MainNavigationScreen fixed
- [x] Bottom nav with IndexedStack
- [x] `RestrictedArea` model + Haversine formula

---

### 🔄 PHASE 1: UI/UX FOUNDATION & BRANDING (80% Complete)

- [x] Color system, typography, CustomButton, CustomTextField
- [x] Splash screen, login/signup screens
- [ ] ⏳ ReWatch logo integration (waiting for asset)
- [ ] ⏸️ Final animation polish

---

### ✅ PHASE 0: FOUNDATION (100% Complete)

Firebase Auth, Provider state management, basic routing, core screens.

---

### ⏸️ PHASE 8: CORE AUTOMATION (0% — Blocked)

**Status:** ⏸️ BLOCKED — waiting on ESP32 BLE UUIDs from hardware team

- [ ] Get ESP32 BLE Service UUID + Characteristic UUID
- [ ] Define command protocol (OPEN/CLOSE bytes or strings)
- [ ] Send valve CLOSE on geofence entry
- [ ] Send valve OPEN on geofence exit
- [ ] Auto-closure notification + log history

---

## 📦 FULL PACKAGE DEPENDENCIES

```yaml
# Core
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
provider: ^6.1.5+1
shared_preferences: ^2.5.4

# Hardware
flutter_blue_plus: 1.31.15
geolocator: ^14.0.2
permission_handler: ^12.0.1
device_info_plus: ^10.1.0

# Map & Location
flutter_map: ^8.2.2
latlong2: ^0.9.1
geocoding: ^4.0.0

# UI
font_awesome_flutter: ^10.7.0
awesome_dialog: ^3.2.1
flutter_svg: ^2.0.10
lottie: ^3.1.2

# Dev
flutter_launcher_icons: ^0.14.1
```

---

## 🎯 MILESTONES

| # | Milestone | Status | Date |
|---|-----------|--------|------|
| 1 | Foundation | ✅ Done | Before Feb 11 |
| 2 | Professional UI | 🔄 80% | Feb 11 |
| 3 | Full Navigation | ✅ Done | Feb 11 |
| 4 | Permission System | ✅ Done | Feb 11 |
| 5 | Hardware Ready (BLE) | ✅ Done | Feb 17 |
| 6 | Live Map & GPS | ✅ Done | Feb 17 |
| 7 | Background GPS + Map-tap Areas | ✅ Done | Mar 5 |
| 8 | Multi-Role System | 🔄 0% | Mar 2026 |
| 9 | MVP Complete (Automation) | ⏸️ Blocked | TBD |

---

## 🎓 CLIENT PRESENTATION READINESS

### Demo-Ready Features:
1. ✅ User signup and login
2. ✅ Professional modern UI
3. ✅ 3-tab navigation (Home, Map, Profile)
4. ✅ Dashboard with live location + restricted zone badge
5. ✅ Real OpenStreetMap with live GPS tracking
6. ✅ Human-readable address (Street → Barangay → Municipality → Province)
7. ✅ Add restricted areas by tapping map
8. ✅ Restricted area red circles on map
9. ✅ Background GPS (survives app minimize)
10. ✅ Real BLE device scanning + connection
11. ✅ Permission system with dialogs
12. ✅ Profile management
13. ⏳ Logo branding (pending asset)
14. 🔄 Multi-role system (in progress)
15. ❌ Automatic valve control (Phase 8 — blocked)

### Presentation Score: **55/100** (expanded scope)
> Was 90/100 on original rider-only scope. Role system in progress.

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Debug `print()` in splash + permission handler | Low | Clean before final demo |
| BLE scan not filtered to ESP32 UUID | Medium | Fix in Phase 8 |
| ESP32 BLE UUIDs not defined | **Blocker** | Needed for Phase 8 |
| iOS Info.plist not configured | Low | Android only for capstone |
| `id: ''` saved in Firestore docs | Low | Should save Firestore doc ID back to document |
| Firestore rules too permissive | Medium | Tighten in Step 7.19 |

---

**For detailed changes, see:** [CHANGELOG.md](./CHANGELOG.md)
**Last Updated:** March 9, 2026