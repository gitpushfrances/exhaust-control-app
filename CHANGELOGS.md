# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~95% of phase complete)
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
| 7.17 | Build Notifications screen + bell icon on Barangay Home | None | ✅ Done |
| 7.18 | Write Firestore notification documents on approve / reject / submit events | Low | ✅ Done |
| 7.19 | Tighten Firestore security rules (all roles) | **HIGH** | ⏳ Pending |
| 7.20 | Add FCM push notifications (optional, add last) | Low | ⏳ Pending |

---

### ✅ Completed This Session — UI/UX Polish & Fixes (March 15, 2026)

---

#### Feature — Notification System fully wired
- **Fixed:** `streamNotifications()` and `streamUnreadNotificationCount()` were silently returning empty — missing Firestore composite indexes
- **Fix:** Created 2 composite indexes in Firebase Console:
  - `notifications`: `uid ASC` + `created_at DESC`
  - `notifications`: `uid ASC` + `is_read ASC`
- **Verified:** `approveRequest()` and `rejectRequest()` in `FirestoreService` already call `createNotification()` — notifications now appear correctly on official's screen
- **Impact:** Barangay official notification screen fully functional — unread badge, mark all read, real-time updates

#### Feature — `submitted_by_name` field added to zone requests
- **Added:** `submittedByName` parameter to `submitZoneRequest()` in `firestore_service.dart`
- **Added:** `submitted_by_name` field written to Firestore on every new zone submission
- **Updated:** `barangay_submit_request_screen.dart` — passes `official?.name ?? ''` on submit
- **Impact:** Admin dashboard and request inbox now show official's name instead of raw UID

#### Feature — Admin Home Dashboard rebuilt (`lib/screens/admin/admin_home_screen.dart`)
- **Replaced:** Placeholder "coming soon" with full production dashboard
- **Added:** Welcome gradient card (indigo) with admin name
- **Added:** 4 live stat cards — Pending Requests (with alert dot), Approved Zones, Officials, Riders
- **Added:** Recent Zone Activity — last 5 areas with reverse-geocoded address, barangay, radius, submitted-by name, status badge
- **Added:** Officials Overview — last 3 officials with avatar initial, name, barangay, email, active/inactive badge
- **Added:** Local reverse geocoding on `_AreaItem` — resolves lat/lng to human-readable address on render, no data stored in Firestore, skeleton placeholder while loading

#### Feature — Admin Navigation Screen rebuilt (`lib/screens/admin/admin_navigation_screen.dart`)
- **Replaced:** Default `BottomNavigationBar` with custom `_ProNavBar`
- **Added:** Animated pill highlight on active tab
- **Added:** Live red badge on Requests tab — driven by `streamPendingRequestsCount()`, auto-clears when count drops
- **Added:** Cleaner rounded icons (`grid_view_rounded`, `inbox_rounded`, `people_rounded`, `map_rounded`, `person_rounded`)

#### Feature — Admin Global Map UI improved (`lib/screens/admin/admin_global_map_screen.dart`)
- **Replaced:** Target/crosshair location icon with clean pulsing blue GPS dot (same as rider map)
- **Replaced:** Large motorcycle marker with professional color-coded pin markers (circle + tail, white border, color-matched shadow)
- **Moved:** Recenter FAB from bottom-right to top-right below filter chips
- **Moved:** Legend from bottom-right to below recenter FAB with gap — right-aligned, clean
- **Updated:** Area bottom sheet now shows `barangay_name` and `submitted_by_name` instead of raw IDs
- **Added:** `SingleTickerProviderStateMixin` for pulse animation on location dot

#### Feature — Rider Dashboard cleaned up (`lib/screens/rider/dashboard_screen.dart`)
- **Removed:** `_StatisticsSummaryCard` widget and all `_StatItem` code — stats section removed entirely
- **Removed:** Bell/notification icon from AppBar — riders have no notification system
- **Redesigned:** `_ExhaustStatusCard` — compact horizontal layout (icon + label side by side) instead of large stacked layout, cuts card height in half
- **Kept:** BT connection card, exhaust status, quick actions, location card — all unchanged

#### Feature — Rider Map improved (`lib/screens/rider/map_screen.dart`)
- **Replaced:** Large motorcycle icon marker with pulsing GPS dot (blue circle with white border + animated pulse ring)
- **Removed:** CLEAR green badge from location overlay — only shows RESTRICTED red badge when inside a zone
- **Added:** Recenter FAB (bottom-right, white card, blue icon)
- **Added:** `SingleTickerProviderStateMixin` for pulse animation

#### Feature — Rider Navigation Screen rebuilt (`lib/screens/rider/main_navigation_screen.dart`)
- **Replaced:** Oversized custom `_NavBarItem` with compact `_ProNavBar`
- **Added:** Animated pill highlight, 60px height, compact icon sizing
- **Updated:** Icons to rounded variants (`home_rounded`, `map_rounded`, `person_rounded`)

#### Feature — Barangay Navigation Screen rebuilt (`lib/screens/barangay/barangay_navigation_screen.dart`)
- **Replaced:** Default `BottomNavigationBar` with custom `_ProNavBar` matching admin style
- **Replaced:** `add_location` icon (hospital-looking) with `add_circle_rounded`
- **Replaced:** `list_alt` with `folder_rounded`
- **Updated:** Notification badge uses same red circle system as admin — not Flutter's default `Badge` widget
- **Updated:** All icons to rounded variants

#### Feature — Profile Screen redesigned (`lib/screens/shared/shared_profile_screen.dart`)
- **Replaced:** Bland white header with gradient card — color-matched per role (green/rider, blue/official, indigo/admin)
- **Added:** Avatar with white border inside gradient card, role badge overlay
- **Added:** Account Details section — name, email, barangay (officials only), role — as info rows with colored icon boxes
- **Added:** App section — About and Help in rounded card
- **Added:** Session section — Sign Out in its own card
- **Added:** Version footer at bottom
- **Fixed:** Role label mismatch — `"superadmin"` was showing as "User" because map key used `"super_admin"` with underscore. Fixed by normalizing role string with `.replaceAll('_', '')` before lookup — handles both formats

#### Patch — Firestore composite indexes for notifications
- **Created:** `notifications`: `uid ASC` + `created_at DESC`
- **Created:** `notifications`: `uid ASC` + `is_read ASC`

---

### ✅ Completed Previously — Patches & Fixes (March 9, 2026)

#### Patch — `RestrictedArea.fromMap()` Firestore Timestamp crash fix
- **Bug:** `fromMap()` was calling `DateTime.parse()` on Firestore `Timestamp` objects
- **Fix:** Added `parseDate()` and `parseDateNullable()` helpers handling Timestamp, DateTime, and String

#### Patch — Firestore composite indexes for restricted_areas
- **Created:** `restricted_areas`: `submitted_by_uid ASC` + `created_at DESC`
- **Created:** `restricted_areas`: `status ASC` + `created_at DESC`
- **Created:** `restricted_areas`: `status ASC` + `approved_at DESC`

#### Patch — `admin_request_detail_screen.dart` converted to `StatefulWidget`
- **Added:** `_isProcessing` boolean, `CircularProgressIndicator`, `mounted` checks

#### Patch — Live location stream added to Admin and Barangay maps
- **Added:** `_startLocationStream()` to `AdminGlobalMapScreen` (8s) and `BarangaySubmitRequestScreen` (4s)

---

### ✅ Completed Previously (Steps 7.8–7.16)

#### Step 7.9 — Request Inbox + Detail
#### Step 7.10 — Manage Officials + Create Official
#### Step 7.13 — Barangay Home Dashboard
#### Step 7.14 — Submit Request (real pending submission logic)
#### Step 7.16 — My Requests (3-tab: Pending / Approved / Rejected)

---

### ✅ Completed Earlier (Steps 7.1–7.7 + 7.12)

#### Models — `AppUser`, updated `RestrictedArea`
#### Auth — Sign Up writes `role: "rider"`, `AuthWrapper` routes by role

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
│   ├── shared/
│   │   └── shared_profile_screen.dart     ✅ redesigned
│   ├── rider/
│   │   ├── main_navigation_screen.dart    ✅ pro nav rebuilt
│   │   ├── dashboard_screen.dart          ✅ stats removed, compact status
│   │   ├── map_screen.dart                ✅ GPS dot, no CLEAR badge
│   │   └── profile_screen.dart
│   ├── admin/
│   │   ├── admin_navigation_screen.dart   ✅ pro nav + pending badge
│   │   ├── admin_home_screen.dart         ✅ full dashboard + geocoding
│   │   ├── admin_request_inbox_screen.dart ✅ live
│   │   ├── admin_request_detail_screen.dart ✅ live + patched
│   │   ├── admin_manage_officials_screen.dart ✅ live
│   │   ├── admin_create_official_screen.dart ✅ live
│   │   └── admin_global_map_screen.dart   ✅ pin markers + top controls
│   └── barangay/
│       ├── barangay_navigation_screen.dart ✅ pro nav rebuilt
│       ├── barangay_home_screen.dart       ✅ live
│       ├── barangay_submit_request_screen.dart ✅ submits submitted_by_name
│       ├── barangay_my_requests_screen.dart ✅ live
│       ├── barangay_notifications_screen.dart ✅ live + indexes fixed
│       └── barangay_profile_screen.dart   ⏳ uses shared profile
└── utils/
    ├── app_colors.dart
    ├── app_text_styles.dart
    └── permission_handler.dart
```

---

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.15** — Barangay boundary check (Haversine — verify official submits only within their barangay)
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
| 0.7.0 (patch 1) | Multi-Role Foundation + Admin/Barangay Screens | ✅ Complete | Mar 9, 2026 |
| **0.7.0 (patch 2)** | **Notifications, UI/UX Polish, Pro Nav, Profile Redesign** | **✅ Complete** | **Mar 15, 2026** |
| 0.7.0 (final) | Boundary Check + Security Rules | 🔄 Next | Mar 2026 |
| 0.8.0 | Core Automation (BLE) | ⏸️ Blocked on ESP32 UUIDs | TBD |

---

**Maintained by:** Development Team
**Last Updated:** March 15, 2026