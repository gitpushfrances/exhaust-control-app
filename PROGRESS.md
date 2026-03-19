# 📊 PROJECT PROGRESS - Exhaust Controller App

**Project Type:** Capstone Project - Automatic Motorcycle Exhaust Noise Control System
**Technology:** Flutter, Firebase, Bluetooth, GPS, OpenStreetMap
**Last Updated:** March 19, 2026

---

## 🎯 Overall Progress: ~91% Complete

> ⚠️ Scope expanded to include 3-role system (Super Admin + Barangay Official + Rider).
> Phase 7 is ~98% done. HC-05 hardware validated — relay clicks on OPEN/CLOSE. Phase 8 is now unblocked.

```
[█████████████████████████████░░░] 91%
```

### Scope Breakdown:
| Scope | Progress | Notes |
|-------|----------|-------|
| Rider functionality | ~98% | All screens done, GPS dot map, compact UI ✅ |
| Phase 7 foundation (models, routing, structure) | 100% | Steps 7.1–7.7, 7.12 done ✅ |
| Super Admin screens | 100% | Dashboard, Inbox, Detail, Officials, Global Map — all live + polished ✅ |
| Barangay Official screens | ~98% | All screens live, notifications working, boundary check done ✅ |
| Notification system | 100% | In-app notifications fully wired end-to-end ✅ |
| UI/UX Polish | 100% | All 3 roles — pro navbars, profile redesign, map improvements ✅ |
| End-to-end flow | ✅ Working | Submit → Admin inbox → Approve/Reject → Rider map + Official notification |
| HC-05 Hardware Validation | 100% | Two-way comms confirmed, relay clicks ✅ |
| Phase 8 BLE Automation | 0% | Unblocked — ready to wire into ExhaustProvider |

---

## 📋 PHASE DETAILS

---

### ✅ PHASE 7.1: HC-05 HARDWARE VALIDATION (100% Complete)

**Status:** ✅ COMPLETE — March 19, 2026

| Task | Status |
|------|--------|
| Add `flutter_bluetooth_serial` package | ✅ Done |
| Fix `build.gradle` namespace AGP issue | ✅ Done |
| Create `bt_classic_test_screen.dart` | ✅ Done |
| Add dev test button to rider dashboard | ✅ Done |
| Configure HC-05 baud rate via AT commands (9600) | ✅ Done |
| Wire HC-05 TX→Pin6, RX→Pin7, Relay→Pin8 | ✅ Done |
| Validate Flutter → Arduino command receive | ✅ Done |
| Validate Arduino → Flutter ACK response | ✅ Done |
| Validate relay actuation on OPEN/CLOSE | ✅ Done |

#### Key Technical Details:
- **HC-05 baud:** 9600 (permanently set via AT+UART=9600,0,0)
- **SoftwareSerial pins:** RX=6, TX=7
- **Relay pin:** 8 — LOW=open, HIGH=closed
- **Command matching:** `indexOf()` — handles hidden `\r\n` from Flutter serial
- **Package fix:** Patched `flutter_bluetooth_serial` cache `build.gradle` — namespace + compileSdkVersion 34 + mavenCentral

---

### 🔄 PHASE 7: MULTI-ROLE SYSTEM EXPANSION (~98% of phase complete)

**Status:** 🔄 IN PROGRESS
**Date Started:** March 2026

#### Progress:
```
[████████████████████████████████] ~98% of phase
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
- [x] 7.8 — Admin Home Dashboard ✅
- [x] 7.9 — Request Inbox + Detail + Approve/Reject ✅
- [x] 7.10 — Manage Officials + Create Official form ✅
- [x] 7.11 — Admin Global Map ✅

**Group C — Barangay Official screens**
- [x] 7.12 — `BarangayNavigationScreen` + skeleton screens ✅
- [x] 7.13 — Barangay Home Dashboard ✅
- [x] 7.14 — Submit Request screen ✅
- [x] 7.15 — Barangay boundary check (GeoJSON polygon) ✅
- [x] 7.16 — My Requests (3 tabs: Pending / Approved / Rejected) ✅
- [x] 7.17 — Notifications screen + bell icon ✅

**Group D — Wiring + security**
- [x] 7.18 — Firestore notification docs on approve/reject/submit ✅
- [ ] 7.19 — ⚠️ Firestore security rules (HIGH RISK — do last)
- [ ] 7.20 — FCM push notifications (optional)

---

### ⚠️ Immediate Next Actions (Phase 7 tail)
1. **Step 7.4** — Seed Super Admin in Firestore console (manual, 5 min)
2. **Step 7.19** — Tighten Firestore security rules (do last, high risk)
3. **Step 7.20** — FCM push notifications (optional)

---

### 🔜 NEXT PHASE — Phase 8: Core HC-05 Automation

**Status:** 🟡 UNBLOCKED — hardware validated March 19, 2026

| Step | Task | Status |
|------|------|--------|
| 8.1 | Create `ClassicBluetoothService` — wraps HC-05 connection + send | ⏳ Next |
| 8.2 | Wire `ExhaustProvider` — send `CLOSE` on geofence entry | ⏳ Next |
| 8.3 | Wire `ExhaustProvider` — send `OPEN` on geofence exit | ⏳ Next |
| 8.4 | Replace `BluetoothProvider` BLE scan with HC-05 Classic BT | ⏳ Next |
| 8.5 | Log auto-closure events to Firestore | ⏳ Next |
| 8.6 | End-to-end test — enter zone → relay clicks → valve closes | ⏳ Next |
| 8.7 | Remove `_DevTestButton` + `bt_classic_test_screen.dart` from build | ⏳ Next |

---

### ✅ PHASE 6.1: PATCHES & BACKGROUND GPS (100% Complete)
**Status:** ✅ COMPLETE — March 5, 2026

### ✅ PHASE 6: MAP INTEGRATION (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

### ✅ PHASE 5: GPS & LOCATION SERVICES (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

### ✅ PHASE 4: BLUETOOTH INTEGRATION (100% Complete)
**Status:** ✅ COMPLETE — February 17, 2026

### ✅ PHASE 3: DEVICE PERMISSIONS (100% Complete)
**Status:** ✅ COMPLETE — February 11, 2026

### ✅ PHASE 2: DASHBOARD & NAVIGATION (100% Complete)
**Status:** ✅ COMPLETE — February 11, 2026

### 🔄 PHASE 1: UI/UX FOUNDATION (80% Complete)
- [x] Color system, typography, CustomButton, CustomTextField
- [x] Branded splash, login/signup screens
- [ ] ⏳ Logo integration (waiting for asset)

### ✅ PHASE 0: FOUNDATION (100% Complete)
Firebase Auth, Provider, basic routing, core screens.

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
flutter_bluetooth_serial: ^0.4.0   # NEW — HC-05 Classic BT
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
| 11 | End-to-end flow verified | ✅ Done | Mar 9 |
| 12 | Notifications + UI/UX Polish (all 3 roles) | ✅ Done | Mar 15 |
| 13 | Barangay Boundary Check + GeoJSON Seeding | ✅ Done | Mar 18 |
| **14** | **HC-05 Hardware Validated + Relay Confirmed** | **✅ Done** | **Mar 19** |
| 15 | Security Rules + Super Admin Seed | 🔄 Next | Mar 2026 |
| 16 | MVP Complete (Phase 8 Automation) | ⏳ Next | TBD |

---

## 📝 TECHNICAL DEBT

| Item | Priority | Notes |
|------|----------|-------|
| Debug `print()` throughout codebase | Low | Clean before final demo |
| `withOpacity` → `withValues()` deprecation warnings (~35 instances) | Low | Batch fix before demo |
| `activeColor` → `activeThumbColor` (2 instances) | Low | Minor deprecation |
| `_DevTestButton` + `bt_classic_test_screen.dart` | Medium | Remove before production — dev-only |
| `flutter_bluetooth_serial` cache `build.gradle` patch | Low | Document for fresh installs — patch needs reapplying |
| Firestore rules too permissive | **High** | Fix in Step 7.19 before demo |
| Step 7.4 Super Admin not seeded | Medium | Required to log in as admin |
| `barangay_profile_screen.dart` still a placeholder | Low | Uses shared profile — functional |
| Old test zone documents missing `submitted_by_name` | Low | Only affects pre-patch documents |
| iOS Info.plist not configured | Low | Android only for capstone |

---

**For detailed changes, see:** CHANGELOG.md
**Last Updated:** March 19, 2026