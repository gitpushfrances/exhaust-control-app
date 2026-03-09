# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~90% of phase complete)
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
| 7.8 | Build Admin Home Dashboard (stat cards, recent activity feed) | None | ✅ Done |
| 7.9 | Build Request Inbox + Detail screen + Approve/Reject flow | None | ✅ Done |
| 7.10 | Build Manage Officials + Create Official form | None | ✅ Done |
| 7.11 | Build Admin Global Map with filter chips + circle overlays | None | ✅ Done |
| 7.12 | Create `BarangayNavigationScreen` + 4 skeleton screens | None | ✅ Done |
| 7.13 | Build Barangay Home Dashboard (zone stats, request summary) | None | ✅ Done |
| 7.14 | Build Submit Request screen (real logic — submits pending to Firestore) | None | ✅ Done |
| 7.15 | Implement barangay boundary check — Option A circle (Haversine reuse) | None | ⏳ Pending |
| 7.16 | Build My Requests screen — 3 inner tabs (Pending / Approved / Rejected) | None | ✅ Done |
| 7.17 | Build Notifications screen + bell icon on Barangay Home | None | ⏳ Pending |
| 7.18 | Write Firestore notification documents on approve / reject / submit events | Low | ⏳ Pending |
| 7.19 | Tighten Firestore security rules (all roles) | **HIGH** | ⏳ Pending |
| 7.20 | Add FCM push notifications (optional, add last) | Low | ⏳ Pending |

---

### ✅ Completed This Session — Patches & Fixes (March 9, 2026)

---

#### Patch — `RestrictedArea.fromMap()` Firestore Timestamp crash fix (`lib/models/restricted_area.dart`)
- **Bug:** `fromMap()` was calling `DateTime.parse()` on Firestore `Timestamp` objects — causes a silent crash, objects get dropped from the stream
- **Root cause:** New documents from `submitZoneRequest()` write `created_at` as `FieldValue.serverTimestamp()` (a Firestore Timestamp), but `fromMap()` expected a plain ISO string
- **Fix:** Added `parseDate()` and `parseDateNullable()` helpers inside `fromMap()` that handle all 3 types — Firestore Timestamp, DateTime, and String
- **Fix:** Field key corrected — reads `created_at` (snake_case) with fallback to `createdAt` (camelCase) for backward compat with old documents
- **Impact:** Rider map now correctly shows approved zones submitted through the new barangay flow

#### Patch — Firestore composite indexes created (Firebase Console)
- **Bug:** `streamMyRequests()` and `streamPendingRequests()` were silently returning empty results — Firestore refuses `where + orderBy` queries without a composite index
- **Root cause:** Three queries all use compound filters that require indexes not previously created
- **Fix:** Created 3 composite indexes in Firebase Console:
  - `restricted_areas`: `submitted_by_uid ASC` + `created_at DESC`
  - `restricted_areas`: `status ASC` + `created_at DESC`
  - `restricted_areas`: `status ASC` + `approved_at DESC`
- **Impact:** Barangay home stats, My Requests tabs, and Admin inbox all now populate correctly

#### Patch — Old dirty Firestore documents deleted
- **Bug:** Legacy test documents in `restricted_areas` written by the old `add_restricted_area_screen.dart` were missing `status`, `submitted_by_uid`, `barangay_id` fields — causing silent query misses
- **Fix:** Manually deleted all 3 legacy documents from Firebase Console
- **Impact:** Clean collection, all documents now follow the correct schema

#### Patch — `admin_request_detail_screen.dart` converted to `StatefulWidget` with loading state
- **Bug:** Approve/Reject buttons had no loading state — tapping during Firestore write could trigger multiple calls or cause a black screen flash on slow connections
- **Fix:** Converted from `StatelessWidget` to `StatefulWidget`
- **Added:** `_isProcessing` boolean — disables both buttons during any ongoing Firestore write
- **Added:** `CircularProgressIndicator` replaces Approve button icon while processing
- **Added:** `mounted` check before all `setState` and `Navigator.pop` calls — prevents calling setState on disposed widget
- **Added:** All data extracted in `initState()` from `widget.data` — no more reading `data[]` in `build()` which caused reference issues after conversion
- **Removed:** Stale local variable references (`fs`, `adminUid`, `docId` etc.) from `build()` — replaced with `_fs`, `_adminUid`, `_docId` instance fields
- **Impact:** Approve/Reject flow is now race-condition safe and production-ready

#### Patch — Live location stream added to Admin and Barangay maps
- **Bug:** Admin global map was hardcoded to Cebu coordinates. Barangay submit map fetched location once with no updates
- **Fix:** Added `_startLocationStream()` with 8-second interval to `AdminGlobalMapScreen`
- **Fix:** Added `_startLocationStream()` with 4-second interval to `BarangaySubmitRequestScreen`
- **Added:** `_currentLat`, `_currentLng`, `_locationReady` fields to admin map state
- **Added:** `_currentLat`, `_currentLng` fields to barangay submit state
- **Added:** Blue dot current location marker on both admin and barangay maps
- **Added:** Recenter FAB on admin map (bottom right, above legend)
- **Added:** Recenter FAB on barangay submit map (bottom right of map)
- **Added:** `_positionStream?.cancel()` in `dispose()` on both screens — no memory leaks
- **Impact:** All 3 role maps now show live user location with recenter capability

#### Patch — Barangay submit map widget structure fixed
- **Bug:** `SizedBox` containing `FlutterMap` was not wrapped in a `Stack` — could not overlay the recenter FAB or blue dot marker
- **Fix:** Wrapped `FlutterMap` inside `Stack` within the `SizedBox`
- **Impact:** Blue dot and recenter button render correctly on barangay submit map

#### Patch — Ghost files removed from `lib/screens/` root
- **Bug:** Old `main_navigation_screen.dart` and `profile_screen.dart` at root `lib/screens/` were restored by git, causing duplicate class errors and stale analyzer cache
- **Fix:** Deleted both root-level ghost files with `rm`
- **Fix:** Committed deletions immediately to prevent git from restoring them again
- **Impact:** Zero duplicate class errors, clean analyzer output

---

### ✅ Completed Previously (Steps 7.8–7.16)

#### Step 7.8 — Admin Home Dashboard (`lib/screens/admin/admin_home_screen.dart`)
- **Replaced:** Placeholder "coming soon" with full dashboard UI
- **Added:** 4 live stat cards — Pending Requests, Approved Zones, Officials, Riders
- **Added:** Recent Activity feed — last 5 approved/rejected zones with relative timestamps

#### Step 7.9 — Request Inbox + Detail (`lib/screens/admin/admin_request_inbox_screen.dart`, `admin_request_detail_screen.dart`)
- **Added:** Full pending requests list with `_RequestCard`
- **Added:** Detail screen — OSM map preview, info card, Approve + Reject flow with reason bottom sheet

#### Step 7.10 — Manage Officials + Create Official (`lib/screens/admin/admin_manage_officials_screen.dart`, `admin_create_official_screen.dart`)
- **Added:** Officials list with active/inactive filter, deactivate/reactivate toggle
- **Added:** Create Official form — creates Firebase Auth account + Firestore user doc

#### Step 7.11 — Admin Global Map (`lib/screens/admin/admin_global_map_screen.dart`)
- **Added:** Full OSM map, filter chips (All/Approved/Pending/Rejected), color-coded circles/pins
- **Added:** Area bottom sheet on pin tap — delete confirm dialog

#### Step 7.13 — Barangay Home Dashboard (`lib/screens/barangay/barangay_home_screen.dart`)
- **Added:** Welcome card, 4 live stat cards, recent requests list (last 3)

#### Step 7.14 — Submit Request (`lib/screens/barangay/barangay_submit_request_screen.dart`)
- **Updated:** Now submits as `status: "pending"` via `submitZoneRequest()` instead of writing directly as approved

#### Step 7.16 — My Requests (`lib/screens/barangay/barangay_my_requests_screen.dart`)
- **Added:** 3-tab screen — Pending / Approved / Rejected; rejected cards show rejection reason

---

### ✅ Completed Earlier (Steps 7.1–7.7 + 7.12)

#### 1. New Model — `AppUser` (`lib/models/app_user.dart`)
- **Added:** uid, name, email, role, barangayId, barangayName, isActive, createdAt, createdBy
- **Added:** `isSuperAdmin`, `isBarangayOfficial`, `isRider` convenience getters
- **Added:** `fromMap()` and `toMap()` for Firestore serialization

#### 2. Updated `RestrictedArea` Model (`lib/models/restricted_area.dart`)
- **Added:** `status`, `barangayId`, `submittedByUid`, `remarks`, `rejectionReason`, `approvedAt`, `approvedByUid` fields

#### 3–12. Steps 7.1–7.7 + 7.12 — See previous entries

---

### 🗂️ Updated Folder Structure
```
lib/
├── main.dart
├── models/
│   ├── app_user.dart
│   └── restricted_area.dart
├── providers/
│   ├── auth_provider.dart
│   ├── bluetooth_provider.dart
│   ├── exhaust_provider.dart
│   └── restricted_areas_provider.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── rider/
│   │   ├── main_navigation_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── map_screen.dart
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_navigation_screen.dart       ✅ live
│   │   ├── admin_home_screen.dart             ✅ live (7.8)
│   │   ├── admin_request_inbox_screen.dart    ✅ live (7.9)
│   │   ├── admin_request_detail_screen.dart   ✅ live (7.9 + patched)
│   │   ├── admin_manage_officials_screen.dart ✅ live (7.10)
│   │   ├── admin_create_official_screen.dart  ✅ live (7.10)
│   │   └── admin_global_map_screen.dart       ✅ live (7.11 + patched)
│   └── barangay/
│       ├── barangay_navigation_screen.dart    ✅ live
│       ├── barangay_home_screen.dart          ✅ live (7.13)
│       ├── barangay_submit_request_screen.dart ✅ live (7.14 + patched)
│       ├── barangay_my_requests_screen.dart   ✅ live (7.16)
│       └── barangay_profile_screen.dart       ⏳ skeleton
└── utils/
    ├── app_colors.dart
    ├── app_text_styles.dart
    └── permission_handler.dart
```

---

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.15** — Barangay boundary check (Haversine — verify official submits only within their barangay)
- [ ] **7.17** — Notifications screen + bell icon on Barangay Home
- [ ] **7.18** — Write Firestore `/notifications` docs on approve/reject events
- [ ] **7.19** — ⚠️ Firestore security rules (HIGH RISK — do last before demo)
- [ ] **7.20** — FCM push notifications (optional)

---

### 🔜 Next Phase — Phase 8: Core BLE Automation

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

## [0.6.1] - Phase 6 Patches & Background GPS

**Status:** ✅ COMPLETED — March 5, 2026

---

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding

**Status:** ✅ COMPLETED — February 17, 2026

---

## [0.4.0] - Phase 4: Bluetooth Hardware Integration

**Status:** ✅ COMPLETED — February 17, 2026

---

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI

**Status:** ✅ COMPLETED — February 11, 2026

---

## [0.2.0] - Phase 2: Dashboard & Navigation

**Status:** ✅ COMPLETED — February 11, 2026

---

## [0.1.0] - Phase 1: UI/UX Foundation & Branding

**Status:** 🔄 80% Complete — logo integration pending

---

## [0.0.1] - Core Foundation

**Status:** ✅ COMPLETED

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
| **0.7.0** | **Multi-Role System** | **🔄 ~90% of phase done** | **Mar 2026** |
| 0.8.0 | Core Automation (BLE) | ⏸️ Blocked on ESP32 UUIDs | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 9, 2026