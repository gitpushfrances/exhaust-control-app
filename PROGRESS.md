# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 9, 2026

---

## 🎯 Overall Progress: ~60% Complete
> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Original rider-only scope was 90% complete. Role expansion resets overall to ~55%.
> Phase 7 foundation work (Steps 7.1–7.7 + 7.12) now complete — bumped to ~60%.

```
[███████████████████░░░░░░░░░░░░░] 60%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~95% | Zone management buttons removed ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens (actual content) | ~10% | Nav shell + global map list done, dashboards pending |
| Barangay Official screens (actual content) | ~10% | Nav shell + submit skeleton done, logic pending |
| Phase 8 BLE Automation | 0% | Blocked on ESP32 UUIDs |

---

## 📋 PHASE DETAILS

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~40% of phase complete)

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

#### Progress:
```
[████████████░░░░░░░░░░░░░░░░░░░░] ~40% of phase
```

#### Step Checklist:

**Group A — Low-risk additive changes**
- [x] 7.1 — `RestrictedArea` model updated (new fields with defaults) ✅
- [x] 7.2 — Sign Up screen writes `role: "rider"` on register ✅
- [x] 7.3 — `AuthWrapper` routes to 3 navigation screens by role ✅
- [ ] 7.4 — ⏳ Seed Super Admin manually in Firestore console — **NEXT ACTION**
- [x] 7.5 — `streamApprovedAreas()` filters `status == "approved"` ✅
- [x] 7.6 — Manage/Add area buttons removed from rider UI ✅

**Group B — Admin screens**
- [x] 7.7 — `AdminNavigationScreen` + skeleton screens created ✅
- [ ] 7.8 — Admin Home Dashboard (stat cards, recent activity)
- [ ] 7.9 — Request Inbox + Detail + Approve/Reject flow
- [ ] 7.10 — Manage Officials + Create Official form
- [ ] 7.11 — Admin Global Map (filter chips, add zone directly) *(list view exists, full map pending)*

**Group C — Barangay Official screens**
- [x] 7.12 — `BarangayNavigationScreen` + skeleton screens created ✅
- [ ] 7.13 — Barangay Home Dashboard
- [ ] 7.14 — Submit Request screen (real logic, boundary check)
- [ ] 7.15 — Barangay boundary check (Option A — Haversine circle)
- [ ] 7.16 — My Requests screen (3 inner tabs)
- [ ] 7.17 — Notifications screen + bell icon

**Group D — Wiring + security**
- [ ] 7.18 — Write Firestore notification documents on events
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### What Was Done in Phase 7 So Far

| File | Change | Type |
|------|--------|------|
| `lib/models/app_user.dart` | Created — full AppUser model with role, isActive, barangayId | ➕ New |
| `lib/models/restricted_area.dart` | Added status, barangayId, submittedByUid, rejectionReason, approvedAt, approvedByUid | ✏️ Updated |
| `lib/services/firestore_service.dart` | Added getUser(), createUserDoc(), streamApprovedAreas(); removed old getRestrictedAreas(email), streamRestrictedAreas(), old deleteRestrictedArea(id, email) | ✏️ Updated |
| `lib/providers/auth_provider.dart` | Added AppUser field, role getter, _loadAppUser(), deactivated account block; updated signUp() to write Firestore doc and accept name param | ✏️ Updated |
| `lib/providers/restricted_areas_provider.dart` | initialize() takes zero args now, uses streamApprovedAreas() stream; removed _userEmail and loadRestrictedAreas() | ✏️ Updated |
| `lib/services/auth_service.dart` | Restored — was accidentally overwritten with auth_provider content | 🔧 Fixed |
| `lib/screens/signup_screen.dart` | Added name field + controller; passes name to signUp() | ✏️ Updated |
| `lib/main.dart` | AuthWrapper now routes by role to 3 nav screens | ✏️ Updated |
| `lib/screens/rider/` | New folder — all 4 rider screens moved here, import paths fixed (../ → ../../) | 📁 Restructured |
| `lib/screens/rider/map_screen.dart` | Removed "Manage Areas" IconButton from AppBar | ➖ Removed |
| `lib/screens/rider/profile_screen.dart` | Removed "Restricted Areas" settings item and ManageRestrictedAreasScreen navigation | ➖ Removed |
| `lib/screens/rider/main_navigation_screen.dart` | initialize() call fixed — no longer passes userEmail arg | 🔧 Fixed |
| `lib/screens/admin/` | New folder — AdminNavigationScreen + 4 screens (home/inbox/officials/map skeletons) | ➕ New |
| `lib/screens/admin/admin_global_map_screen.dart` | Repurposed from manage_restricted_areas_screen; class renamed, Add Zone screen nav removed, FAB shows snackbar | 🔄 Repurposed |
| `lib/screens/barangay/` | New folder — BarangayNavigationScreen + 4 screens (home/submit/requests/profile) | ➕ New |
| `lib/screens/barangay/barangay_submit_request_screen.dart` | Repurposed from add_restricted_area_screen; class renamed to BarangaySubmitRequestScreen, map-tap logic preserved | 🔄 Repurposed |
| `lib/screens/stats_screen.dart` | Deleted — removed in Phase 6.1, was dead file | ❌ Deleted |
| `lib/screens/settings_screen.dart` | Deleted — was never wired up, dead file | ❌ Deleted |
| `lib/screens/manage_restricted_areas_screen.dart` | Deleted from root — repurposed to admin_global_map_screen | ❌ Deleted |
| `lib/screens/add_restricted_area_screen.dart` | Deleted from root — repurposed to barangay_submit_request_screen | ❌ Deleted |
| `lib/models/restricted_area.dart.bak` | Deleted — backup file, no longer needed | ❌ Deleted |

---

### ⚠️ Immediate Next Actions
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
   - Go to Firestore → `/users` collection → Add document
   - Fields: `uid` (Firebase Auth UID), `name`, `email`, `role: "superadmin"`, `is_active: true`, `created_at`
2. Run `flutter analyze` — confirm zero errors before building new screens
3. Start **Step 7.8** — Admin Home Dashboard

---

### ✅ PHASE 6.1: PATCHES & BACKGROUND GPS (100% Complete)

**Status:** ✅ COMPLETE — March 5, 2026

- [x] Stats tab removed (4 → 3 tabs)
- [x] Timer → getPositionStream for background GPS
- [x] Foreground service + background location permissions
- [x] Map-tap area creation rewrite (pin drops instantly, async geocoding)
- [x] Address format: Street → Barangay → Municipality → Province → Region
- [x] AnimationController render storm removed
- [x] Firestore database created + rules fixed
- [x] isActive filter bug fixed
- [x] Provider initialization bug fixed
- [x] Verified on Infinix X6833B (Android 13)

---

### ✅ PHASE 6: MAP INTEGRATION (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] flutter_map + OSM tiles
- [x] Motorcycle marker at real GPS position
- [x] Red circle overlays for restricted areas
- [x] MapController + center-on-user button

---

### ✅ PHASE 5: GPS & LOCATION SERVICES (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] Geolocator high-accuracy GPS
- [x] Reverse geocoding → human-readable address
- [x] Live location + isInRestrictedArea badge on dashboard

---

### ✅ PHASE 4: BLUETOOTH INTEGRATION (100% Complete)

**Status:** ✅ COMPLETE — February 17, 2026

- [x] Real BLE scanning + connection via flutter_blue_plus 1.31.15
- [x] BluetoothDevice reference stored for Phase 8
- [x] 6 bugs fixed

---

### ✅ PHASE 3: DEVICE PERMISSIONS (100% Complete)

**Status:** ✅ COMPLETE — February 11, 2026

- [x] AppPermissionHandler — BT + GPS (Android 12+ support)
- [x] 7 permissions in AndroidManifest

---

### ✅ PHASE 2: DASHBOARD & NAVIGATION (100% Complete)

**Status:** ✅ COMPLETE — February 11, 2026

- [x] Bottom nav with IndexedStack
- [x] RestrictedArea model + Haversine formula
- [x] AuthWrapper routing bug fixed

---

### 🔄 PHASE 1: UI/UX FOUNDATION (80% Complete)

- [x] Color system, typography, CustomButton, CustomTextField
- [x] Branded splash, login/signup screens
- [ ] ⏳ Logo integration (waiting for asset)

---

### ✅ PHASE 0: FOUNDATION (100% Complete)

Firebase Auth, Provider, basic routing, core screens.

---

### ⏸️ PHASE 8: CORE AUTOMATION (0% — Blocked)

**Status:** ⏸️ BLOCKED — waiting on ESP32 BLE UUIDs from hardware team

- [ ] ESP32 BLE Service UUID + Characteristic UUID
- [ ] OPEN/CLOSE command protocol
- [ ] Send valve CLOSE on geofence entry
- [ ] Send valve OPEN on geofence exit
- [ ] Auto-closure log history

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
| 8 | Role Foundation (models, routing, structure) | ✅ Done | Mar 9 |
| 9 | Multi-Role Screens (Admin + Barangay) | 🔄 In Progress | Mar 2026 |
| 10 | MVP Complete (Automation) | ⏸️ Blocked | TBD |

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Debug `print()` in splash + permission handler | Low | Clean before final demo |
| BLE scan not filtered to ESP32 UUID | Medium | Fix in Phase 8 |
| ESP32 BLE UUIDs not defined | **Blocker** | Needed for Phase 8 |
| iOS Info.plist not configured | Low | Android only for capstone |
| Firestore rules too permissive | Medium | Tighten in Step 7.19 — do last |
| Admin request detail screen not yet created | Medium | Needed for Step 7.9 |
| barangay_notifications_screen.dart not yet created | Medium | Needed for Step 7.17 |
| admin_request_detail_screen.dart not yet created | Medium | Needed for Step 7.9 |
| admin_create_official_screen.dart not yet created | Medium | Needed for Step 7.10 |

---

**For detailed changes, see:** CHANGELOGS.md
**Last Updated:** March 9, 2026