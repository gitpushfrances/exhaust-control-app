# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 9, 2026

---

## 🎯 Overall Progress: ~80% Complete

> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Phase 7 is now ~90% done — all major screens built and working end-to-end. Only notifications + security rules remain.

```
[██████████████████████████░░░░░░] 80%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~95% | All rider screens done, zone management removed ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Detail, Officials, Create Official, Global Map all live ✅ |
| Barangay Official screens | ~85% | Home, Submit, My Requests done and working; Notifications + profile pending |
| End-to-end flow | ✅ Working | Submit → Admin inbox → Approve/Reject → Rider map update — full flow verified |
| Phase 8 BLE Automation | 0% | Blocked on ESP32 UUIDs |

---

## 📋 PHASE DETAILS

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~90% of phase complete)

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

#### Progress:
```
[████████████████████████████░░░░] ~90% of phase
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
- [x] 7.8 — Admin Home Dashboard (stat cards + recent activity) ✅
- [x] 7.9 — Request Inbox + Detail + Approve/Reject ✅
- [x] 7.10 — Manage Officials + Create Official form ✅
- [x] 7.11 — Admin Global Map (filter chips, circle overlays, area sheet) ✅

**Group C — Barangay Official screens**
- [x] 7.12 — `BarangayNavigationScreen` + skeleton screens ✅
- [x] 7.13 — Barangay Home Dashboard (stats + recent requests) ✅
- [x] 7.14 — Submit Request screen (real pending submission logic) ✅
- [ ] 7.15 — ⏳ Barangay boundary check (Haversine)
- [x] 7.16 — My Requests (3 tabs: Pending / Approved / Rejected) ✅
- [ ] 7.17 — ⏳ Notifications screen + bell icon

**Group D — Wiring + security**
- [ ] 7.18 — ⏳ Write Firestore notification docs on approve/reject events
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### ✅ What Was Done This Session — Patches & Fixes (March 9, 2026)

| File / Area | Change | Type |
|-------------|--------|------|
| `lib/models/restricted_area.dart` | Fixed `fromMap()` — handles Firestore Timestamp, DateTime, and String for date fields; fixed field key `created_at` vs `createdAt` | 🔧 Fix |
| Firebase Console — Indexes | Created 3 composite indexes: `submitted_by_uid+created_at`, `status+created_at`, `status+approved_at` | 🔧 Fix |
| Firebase Console — Data | Deleted 3 legacy documents with wrong schema (missing `status`, `submitted_by_uid`) | 🔧 Fix |
| `lib/screens/admin/admin_request_detail_screen.dart` | Converted to `StatefulWidget`; added `_isProcessing` loading state; disabled buttons during write; added `mounted` guards; extracted all data to `initState()` | 🔧 Fix |
| `lib/screens/admin/admin_global_map_screen.dart` | Added live location stream (8s interval), blue dot marker, recenter FAB | ✏️ Updated |
| `lib/screens/barangay/barangay_submit_request_screen.dart` | Added live location stream (4s interval), blue dot marker, recenter FAB, fixed map widget wrapped in Stack | ✏️ Updated |
| `lib/screens/rider/map_screen.dart` | Confirmed working — already had live location stream and recenter | ✅ Verified |
| `lib/screens/` root | Deleted ghost `main_navigation_screen.dart` and `profile_screen.dart` — restored by git, caused duplicate errors | 🔧 Fix |

#### Bugs Fixed This Session
| Bug | Root Cause | Fix |
|-----|-----------|-----|
| Rider map not showing approved zones | `fromMap()` crashed on Firestore Timestamp — objects silently dropped | Added Timestamp-aware date parser in `fromMap()` |
| Barangay home + My Requests showing empty | Missing Firestore composite indexes — `where + orderBy` silently returns nothing | Created 3 composite indexes in Firebase Console |
| Admin inbox showing empty | Same missing index issue (`status + created_at`) | Same fix above |
| Old test documents not matching new schema | Legacy docs written by old screen — missing `status`, `submitted_by_uid` | Deleted all 3 from Firebase Console |
| Admin approve/reject — potential black screen on slow connection | `StatelessWidget` with no loading state, multiple tap possible | Converted to `StatefulWidget` with `_isProcessing` guard |
| Admin + Barangay maps hardcoded to Cebu | No location stream wired to those screens | Added `_startLocationStream()` to both |

---

### ✅ What Was Done Previously (Steps 7.8–7.16)

| File | Change | Type |
|------|--------|------|
| `lib/screens/admin/admin_home_screen.dart` | Full dashboard — 4 live stat cards + recent activity feed | ✏️ Updated |
| `lib/screens/admin/admin_request_inbox_screen.dart` | Full pending requests list with cards + navigation to detail | ✏️ Updated |
| `lib/screens/admin/admin_request_detail_screen.dart` | Map preview, info card, approve + reject (with reason) flow | ➕ New |
| `lib/screens/admin/admin_manage_officials_screen.dart` | Full officials list with active/inactive filter + deactivate/reactivate | ✏️ Updated |
| `lib/screens/admin/admin_create_official_screen.dart` | Creates Firebase Auth account + Firestore user doc for official | ➕ New |
| `lib/screens/admin/admin_navigation_screen.dart` | Added `jumpTo()` for stat card taps | ✏️ Updated |
| `lib/screens/admin/admin_global_map_screen.dart` | Full OSM map — color-coded circles/pins, filter chips, area bottom sheet, delete | ✏️ Updated |
| `lib/screens/barangay/barangay_home_screen.dart` | Full dashboard — welcome card, 4 stat cards, recent requests list | ✏️ Updated |
| `lib/screens/barangay/barangay_submit_request_screen.dart` | Real submission logic — writes `status: pending` to Firestore | ✏️ Updated |
| `lib/screens/barangay/barangay_my_requests_screen.dart` | 3-tab screen — Pending/Approved/Rejected; rejection reason shown | ✏️ Updated |
| `lib/services/firestore_service.dart` | Added 14 new methods across all roles | ✏️ Updated |

---

### ⚠️ Immediate Next Actions (Phase 7 tail)
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
2. **Step 7.17** — `barangay_notifications_screen.dart` + bell icon in barangay nav
3. **Step 7.18** — Write `/notifications` Firestore docs when admin approves/rejects
4. **Step 7.19** — Tighten Firestore security rules (do last, high risk)
5. **Step 7.15** — Barangay boundary check using Haversine

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
| 12 | Notifications + Security Rules | 🔄 Next | Mar 2026 |
| 13 | MVP Complete (Automation) | ⏸️ Blocked | TBD |

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
| `barangay_profile_screen.dart` still a placeholder | Low | Needs real profile UI |
| Step 7.15 boundary check not implemented | Medium | Officials can submit outside their barangay |
| Step 7.4 Super Admin not seeded | Medium | Required to log in as admin |

---

**For detailed changes, see:** CHANGELOGS.md
**Last Updated:** March 9, 2026