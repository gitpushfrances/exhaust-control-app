# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 15, 2026

---

## 🎯 Overall Progress: ~88% Complete

> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Phase 7 is now ~95% done — all screens built, notifications wired, UI fully polished. Only boundary check + security rules remain.

```
[████████████████████████████░░░░] 88%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~98% | All screens done, stats removed, GPS dot map, compact UI ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Detail, Officials, Global Map — all live + polished ✅ |
| Barangay Official screens | ~95% | All screens live; notifications working; boundary check pending |
| Notification system | 100% | In-app notifications fully wired end-to-end ✅ |
| UI/UX Polish | 100% | All 3 roles — pro navbars, profile redesign, map improvements ✅ |
| End-to-end flow | ✅ Working | Submit → Admin inbox → Approve/Reject → Rider map + Official notification |
| Phase 8 BLE Automation | 0% | Blocked on ESP32 UUIDs |

---

## 📋 PHASE DETAILS

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~95% of phase complete)

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

#### Progress:
```
[██████████████████████████████░░] ~95% of phase
```

#### Step Checklist:

**Group A — Low-risk additive changes**
- [x] 7.1 — `RestrictedArea` model updated ✅
- [x] 7.2 — Sign Up writes `role: "rider"` ✅
- [x] 7.3 — `AuthWrapper` routes by role to 3 nav screens ✅
- [ ] 7.4 — ⏳ Seed Super Admin in Firestore console — **STILL PENDING (manual step)**
- [x] 7.5 — `streamApprovedAreas()` filters approved only ✅
- [x] 7.6 — Zone management removed from rider UI ✅

**Group B — Admin screens**
- [x] 7.7 — `AdminNavigationScreen` + skeleton screens ✅
- [x] 7.8 — Admin Home Dashboard (stat cards + recent activity + geocoding) ✅
- [x] 7.9 — Request Inbox + Detail + Approve/Reject ✅
- [x] 7.10 — Manage Officials + Create Official form ✅
- [x] 7.11 — Admin Global Map (filter chips, pin markers, legend, recenter) ✅

**Group C — Barangay Official screens**
- [x] 7.12 — `BarangayNavigationScreen` + skeleton screens ✅
- [x] 7.13 — Barangay Home Dashboard (stats + recent requests) ✅
- [x] 7.14 — Submit Request screen (real pending submission + submitted_by_name) ✅
- [ ] 7.15 — ⏳ Barangay boundary check (Haversine)
- [x] 7.16 — My Requests (3 tabs: Pending / Approved / Rejected) ✅
- [x] 7.17 — Notifications screen + bell icon ✅

**Group D — Wiring + security**
- [x] 7.18 — Firestore notification docs on approve/reject/submit ✅
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### ✅ What Was Done This Session — UI/UX Polish + Notification Fix (March 15, 2026)

| File / Area | Change | Type |
|-------------|--------|------|
| Firebase Console — Indexes | Created 2 notification indexes: `uid+created_at`, `uid+is_read` | 🔧 Fix |
| `lib/services/firestore_service.dart` | Added `submittedByName` param + `submitted_by_name` field to `submitZoneRequest()` | ✏️ Updated |
| `lib/screens/barangay/barangay_submit_request_screen.dart` | Added `submittedByName: official?.name` to submit call | 🔧 Fix |
| `lib/screens/admin/admin_home_screen.dart` | Full rebuild — welcome card, stat cards, reverse-geocoded area list, officials overview | ✏️ Updated |
| `lib/screens/admin/admin_navigation_screen.dart` | Replaced with custom `_ProNavBar` — pill highlight, live pending badge | ✏️ Updated |
| `lib/screens/admin/admin_global_map_screen.dart` | Pin markers, pulsing GPS dot, recenter + legend moved to top-right | ✏️ Updated |
| `lib/screens/rider/dashboard_screen.dart` | Removed stats card, removed bell icon, compact exhaust status | ✏️ Updated |
| `lib/screens/rider/map_screen.dart` | Pulsing GPS dot, removed CLEAR badge, added recenter FAB | ✏️ Updated |
| `lib/screens/rider/main_navigation_screen.dart` | Replaced with `_ProNavBar` — compact, pill highlight, rounded icons | ✏️ Updated |
| `lib/screens/barangay/barangay_navigation_screen.dart` | Replaced with `_ProNavBar` — clean icons, notification badge | ✏️ Updated |
| `lib/screens/shared/shared_profile_screen.dart` | Full redesign — gradient header card, info rows, sections, role fix | ✏️ Updated |

#### Bugs Fixed This Session
| Bug | Root Cause | Fix |
|-----|-----------|-----|
| Notifications screen showing empty | Missing Firestore composite indexes on `notifications` collection | Created 2 indexes in Firebase Console |
| Official name showing as UID in admin dashboard | `submitted_by_name` field not written on submit | Added field to `submitZoneRequest()` and submit call |
| Super Admin profile showing "User" label | Role key mismatch — code used `"super_admin"`, Firestore stores `"superadmin"` | Normalized with `.replaceAll('_', '')` before map lookup |
| Admin map showing target/crosshair icon for user location | Old `Icons.my_location` inside a Container used as marker | Replaced with pulsing animated GPS dot using `AnimationController` |
| Rider map showing large motorcycle icon | `Icons.motorcycle` in a blue circle — too big and unprofessional | Replaced with 14px pulsing blue dot with white border |

---

### ✅ What Was Done Previously — Patches & Fixes (March 9, 2026)

| File / Area | Change | Type |
|-------------|--------|------|
| `lib/models/restricted_area.dart` | Fixed `fromMap()` — Timestamp-aware date parser | 🔧 Fix |
| Firebase Console — Indexes | 3 composite indexes for `restricted_areas` | 🔧 Fix |
| Firebase Console — Data | Deleted 3 legacy documents with wrong schema | 🔧 Fix |
| `lib/screens/admin/admin_request_detail_screen.dart` | Converted to `StatefulWidget` with `_isProcessing` guard | 🔧 Fix |
| `lib/screens/admin/admin_global_map_screen.dart` | Added live location stream, blue dot, recenter FAB | ✏️ Updated |
| `lib/screens/barangay/barangay_submit_request_screen.dart` | Added live location stream, blue dot, recenter FAB | ✏️ Updated |

---

### ⚠️ Immediate Next Actions (Phase 7 tail)
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
2. **Step 7.15** — Barangay boundary check using Haversine
3. **Step 7.19** — Tighten Firestore security rules (do last, high risk)
4. **Step 7.20** — FCM push notifications (optional)

---

### 🔜 NEXT PHASE — Phase 8: Core BLE Automation

**Status:** ⏸️ BLOCKED — waiting on ESP32 BLE UUIDs from hardware team

| Task | Notes |
|------|-------|
| Obtain ESP32 Service UUID + Characteristic UUID | From hardware team |
| Define OPEN/CLOSE byte command protocol | Agree with hardware team |
| Wire `ExhaustProvider` — send `CLOSE` on geofence entry | Uses existing Haversine check |
| Wire `ExhaustProvider` — send `OPEN` on geofence exit | |
| Log auto-closure events to Firestore | For audit trail |
| End-to-end test on device | Rider enters zone → BLE fires → valve closes |

---

### ✅ PHASE 6.1: PATCHES & BACKGROUND GPS (100% Complete)
**Status:** ✅ COMPLETE — March 5, 2026

---

### ✅ PHASE 6: MAP INTEGRATION (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

---

### ✅ PHASE 5: GPS & LOCATION SERVICES (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

---

### ✅ PHASE 4: BLUETOOTH INTEGRATION (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

---

### ✅ PHASE 3: DEVICE PERMISSIONS (100% Complete)
**Status:** ✅ COMPLETE — February 11, 2026

---

### ✅ PHASE 2: DASHBOARD & NAVIGATION (100% Complete)
**Status:** ✅ COMPLETE — February 11, 2026

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
| 9 | Admin Screens Complete | ✅ Done | Mar 9 |
| 10 | Barangay Screens (core) | ✅ Done | Mar 9 |
| 11 | End-to-end flow verified (Submit → Approve → Rider map) | ✅ Done | Mar 9 |
| 12 | Notifications fully wired + UI/UX Polish (all 3 roles) | ✅ Done | Mar 15 |
| 13 | Boundary Check + Security Rules | 🔄 Next | Mar 2026 |
| 14 | MVP Complete (Automation) | ⏸️ Blocked | TBD |

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` deprecation warnings (~35 instances) | Low | Batch fix before demo |
| `activeColor` → `activeThumbColor` (2 instances) | Low | Minor deprecation |
| BLE scan not filtered to ESP32 UUID | Medium | Fix in Phase 8 |
| ESP32 BLE UUIDs not defined | **Blocker** | Needed for Phase 8 |
| iOS Info.plist not configured | Low | Android only for capstone |
| Firestore rules too permissive | **High** | Fix in Step 7.19 before demo |
| `barangay_profile_screen.dart` still a placeholder | Low | Uses shared profile — functional but no barangay-specific content |
| Step 7.15 boundary check not implemented | Medium | Officials can submit outside their barangay |
| Step 7.4 Super Admin not seeded | Medium | Required to log in as admin |
| Old test zone documents missing `submitted_by_name` | Low | Only affects pre-patch documents — new submissions show correctly |

---

**For detailed changes, see:** CHANGELOG.md
**Last Updated:** March 15, 2026