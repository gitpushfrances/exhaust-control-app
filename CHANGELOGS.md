# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~80% of phase complete)
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

### ✅ Completed This Session (Steps 7.8–7.16)

---

#### Step 7.8 — Admin Home Dashboard (`lib/screens/admin/admin_home_screen.dart`)
- **Replaced:** Placeholder "coming soon" with full dashboard UI
- **Added:** 4 live stat cards — Pending Requests, Approved Zones, Officials, Riders — each backed by a real Firestore stream
- **Added:** Stat card tap navigates to relevant tab (Pending → Requests tab, Officials → Officials tab) via `_AdminNavigationState` abstract interface
- **Added:** Recent Activity feed — shows last 5 approved/rejected zones with color-coded icons and relative timestamps
- **Added:** `_StatCard`, `_ActivityItem` private widgets

#### Step 7.8 — FirestoreService additions
- **Added:** `streamPendingRequestsCount()` — live count of `status == "pending"` docs
- **Added:** `streamApprovedAreasCount()` — live count of `status == "approved"` docs
- **Added:** `streamOfficialsCount()` — live count of `role == "barangay_official"` users
- **Added:** `streamRidersCount()` — live count of `role == "rider"` users
- **Added:** `streamRecentActivity()` — last 5 approved/rejected areas ordered by `approved_at`

#### Step 7.9 — Request Inbox (`lib/screens/admin/admin_request_inbox_screen.dart`)
- **Replaced:** Placeholder with full pending requests list
- **Added:** `_RequestCard` — shows zone name, barangay, radius, relative time, pending badge, chevron
- **Added:** Tapping a card navigates to `AdminRequestDetailScreen`
- **Removed:** Unused `provider` and `auth_provider` imports (were flagged by analyzer)

#### Step 7.9 — Request Detail (`lib/screens/admin/admin_request_detail_screen.dart`) ← NEW FILE
- **Created:** Full detail screen — map preview (OSM + circle + pin), info card (name, barangay, coords, radius, remarks)
- **Added:** Approve button — calls `approveRequest()`, shows snackbar, pops back
- **Added:** Reject button — opens bottom sheet with reason text field, calls `rejectRequest()` on confirm
- **Added:** `_InfoRow` private widget

#### Step 7.9 — FirestoreService additions
- **Added:** `streamPendingRequests()` — real-time stream of all pending areas ordered by `created_at`
- **Added:** `approveRequest({docId, adminUid})` — updates status to `"approved"`, writes `approved_at` + `approved_by_uid`
- **Added:** `rejectRequest({docId, adminUid, reason})` — updates status to `"rejected"`, writes `rejection_reason`

#### Step 7.10 — Manage Officials (`lib/screens/admin/admin_manage_officials_screen.dart`)
- **Replaced:** Placeholder with full officials list
- **Added:** Active/Inactive toggle filter in AppBar (segmented button style)
- **Added:** `_OfficialCard` — avatar initial, name, barangay, email, status badge, Deactivate/Reactivate button
- **Added:** Confirm dialog before toggling active status
- **Added:** FAB → navigates to `AdminCreateOfficialScreen`

#### Step 7.10 — Create Official (`lib/screens/admin/admin_create_official_screen.dart`) ← NEW FILE
- **Created:** Full form — Full Name, Email, Password (toggle visibility), Barangay Name, Barangay ID
- **Added:** Creates Firebase Auth account via `FirebaseAuth.instance.createUserWithEmailAndPassword()`
- **Added:** Writes Firestore `/users/{uid}` doc with `role: "barangay_official"`, `barangay_id`, `barangay_name`, `is_active: true`
- **Fixed:** `AuthProvider` name clash with `firebase_auth`'s own `AuthProvider` — resolved by aliasing both imports (`app_auth`, `fb_auth`)

#### Step 7.10 — FirestoreService additions
- **Added:** `streamOfficials()` — real-time stream of all `role == "barangay_official"` users as `List<AppUser>`
- **Added:** `setOfficialActiveStatus(uid, isActive)` — updates `is_active` field on user doc
- **Removed:** `createOfficialAccount()` stub — actual account creation handled directly in `AdminCreateOfficialScreen` using Firebase Auth

#### Step 7.11 — Admin Global Map (`lib/screens/admin/admin_global_map_screen.dart`)
- **Replaced:** Static list view with full interactive OSM map
- **Added:** `streamAllAreas()` — streams ALL areas regardless of status (pending + approved + rejected)
- **Added:** Filter chips — All, Approved (green), Pending (amber), Rejected (red) — updates map in real time
- **Added:** Color-coded circle overlays and pin markers per status
- **Added:** Tapping a pin opens bottom sheet — shows name, barangay, radius, status badge, Delete button
- **Added:** Delete confirm dialog — calls `deleteRestrictedArea(docId)`
- **Added:** Legend overlay (bottom-right) — color key for 3 statuses
- **Added:** Header overlay (top) — zone count updates with filter
- **Removed:** Old list-based `ListView.builder` UI
- **Removed:** FAB "coming soon" snackbar — replaced by map interaction

#### Step 7.11 — FirestoreService additions
- **Added:** `streamAllAreas()` — streams entire `restricted_areas` collection ordered by `created_at` descending, returns `List<Map>` with `doc_id`

#### Step 7.13 — Barangay Home Dashboard (`lib/screens/barangay/barangay_home_screen.dart`)
- **Replaced:** Placeholder with full dashboard
- **Added:** Welcome card with gradient background showing official's name
- **Added:** 4 stat cards (Total, Pending, Approved, Rejected) backed by `streamMyRequestStats(uid)`
- **Added:** Recent Requests list — last 3 of the official's own submissions with color-coded status dots

#### Step 7.14 — Submit Request (`lib/screens/barangay/barangay_submit_request_screen.dart`)
- **Updated:** Was saving directly as `approved` via `RestrictedAreasProvider` — now submits as `status: "pending"` via `FirestoreService.submitZoneRequest()`
- **Added:** Remarks field (optional, sent to admin)
- **Updated:** AppBar title changed from "Add Restricted Area" to "Submit Zone Request"
- **Updated:** Submit button label changed to "Submit for Approval"
- **Updated:** Circle preview color changed from red to amber (pending color)
- **Updated:** Pin color changed from red to amber
- **Updated:** Success snackbar message updated to "Request submitted — awaiting admin approval"
- **Removed:** Direct dependency on `RestrictedAreasProvider` and `FirebaseAuth` — now reads official info from `AuthProvider.appUser`
- **Fixed:** `const AndroidSettings` error — removed erroneous `const` keyword

#### Step 7.14 — FirestoreService additions
- **Added:** `submitZoneRequest({name, latitude, longitude, radius, barangayId, barangayName, submittedByUid, remarks})` — writes new doc with `status: "pending"` and `FieldValue.serverTimestamp()`
- **Added:** `streamMyRequests(uid)` — streams all areas where `submitted_by_uid == uid`, ordered by `created_at` descending
- **Added:** `streamMyRequestStats(uid)` — derives `{total, pending, approved, rejected}` counts from `streamMyRequests`

#### Step 7.16 — My Requests (`lib/screens/barangay/barangay_my_requests_screen.dart`)
- **Replaced:** Placeholder with 3-tab screen (Pending / Approved / Rejected)
- **Added:** `TabController` with `SingleTickerProviderStateMixin`
- **Added:** Single `streamMyRequests(uid)` stream split into 3 filtered lists fed into `TabBarView`
- **Added:** `_RequestCard` — shows name, radius, status badge; rejected cards show rejection reason in a red info box
- **Added:** Empty state per tab with appropriate message

---

### ✅ Completed Earlier (Steps 7.1–7.7 + 7.12)

#### 1. New Model — `AppUser` (`lib/models/app_user.dart`)
- **Added:** New file — uid, name, email, role, barangayId, barangayName, isActive, createdAt, createdBy
- **Added:** Convenience getters: `isSuperAdmin`, `isBarangayOfficial`, `isRider`
- **Added:** `fromMap()` and `toMap()` for Firestore serialization

#### 2. Updated `RestrictedArea` Model (`lib/models/restricted_area.dart`)
- **Added:** `status`, `barangayId`, `submittedByUid`, `remarks`, `rejectionReason`, `approvedAt`, `approvedByUid` fields (all nullable, status defaults to `"approved"` for backward compat)
- **Kept:** All existing fields + Haversine `containsPoint()` untouched

#### 3–12. (See previous session entries above — Steps 7.1–7.7 + 7.12 details unchanged)

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
│   │   ├── admin_navigation_screen.dart    ✅ live
│   │   ├── admin_home_screen.dart          ✅ live (7.8)
│   │   ├── admin_request_inbox_screen.dart ✅ live (7.9)
│   │   ├── admin_request_detail_screen.dart ✅ NEW (7.9)
│   │   ├── admin_manage_officials_screen.dart ✅ live (7.10)
│   │   ├── admin_create_official_screen.dart  ✅ NEW (7.10)
│   │   └── admin_global_map_screen.dart    ✅ live (7.11)
│   └── barangay/
│       ├── barangay_navigation_screen.dart ✅ live
│       ├── barangay_home_screen.dart       ✅ live (7.13)
│       ├── barangay_submit_request_screen.dart ✅ live (7.14)
│       ├── barangay_my_requests_screen.dart    ✅ live (7.16)
│       └── barangay_profile_screen.dart    ⏳ skeleton
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

### 🔜 Next Phase — Phase 7 Completion + Phase 8

**Immediate next steps (Phase 7 tail end):**
1. Step 7.17 — Notifications screen (`barangay_notifications_screen.dart`) + bell icon wired to `barangay_navigation_screen.dart`
2. Step 7.18 — Write `/notifications` Firestore docs when admin approves or rejects a request
3. Step 7.19 — Tighten Firestore security rules
4. Step 7.4 — Seed Super Admin manually in Firebase console

**After Phase 7 is complete → Phase 8: Core BLE Automation**
> ⏸️ Currently blocked on ESP32 BLE UUIDs from hardware team.
- Wire `exhaust_provider.dart` to send BLE `CLOSE` command on geofence entry
- Send BLE `OPEN` command on geofence exit
- Log auto-closure events to Firestore
- Test end-to-end: rider enters zone → BLE fires → valve closes

---

## [0.6.1] - Phase 6 Patches & Background GPS

**Status:** ✅ COMPLETED — March 5, 2026

*(No changes — see previous entries)*

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
| **0.7.0** | **Multi-Role System** | **🔄 ~80% of phase done** | **Mar 2026** |
| 0.8.0 | Core Automation (BLE) | ⏸️ Blocked on ESP32 UUIDs | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 9, 2026