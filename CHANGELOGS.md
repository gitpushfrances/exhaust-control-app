# 📝 CHANGELOG - Exhaust Controller App

All notable changes to this project will be documented in this file.

---

## [0.7.4 patch 7] - Ride Session Storage Fix, Zone Overlap Guard & Official Logs Redesign

**Status:** ✅ COMPLETED — August 26, 2026

### 🎯 What This Phase Achieved:
Fixed a critical data-loss bug where ride sessions silently failed to log
whenever Bluetooth wasn't connected — meaning all speed/zone/timing data
was lost on every test run without HC-05 paired, not just the dB fields
that were expected to be zero. Also fixed a second bug where the overall
`avg_speed_kph` field always wrote as `0.0` even on sessions that did log,
due to a buffer being read after it was already cleared. Added a
same-barangay zone-overlap check on the official's Submit Request screen,
and added the barangay's approved zone(s) as visible circles on that same
map so officials can see their own active zone before submitting a new
one. Redesigned the official's Ride Logs screen from a horizontal tab bar
(one tab per approved zone) to a tappable card list, pushing into a
per-zone detail screen — same summary/records content, cleaner navigation
for barangays with multiple approved zones.

### 🐞 Bugs Found & Fixed During Implementation
- **Ride sessions never created without a confirmed BT command** —
  `checkRestrictedAreaStatus()` gated `_startSession()` behind
  `if (sent)`, where `sent` is the result of `ClassicBluetoothService
  .sendRaw('ZENTER')`. Every test run without HC-05 paired had `sent ==
  false` on every zone entry, so no Firestore document was ever created
  — confirmed via terminal log showing `ZENTER failed — BT not
  connected` on every entry with no accompanying `_startSession called`
  line, and via Firestore showing no new documents newer than the last
  session logged while BT happened to be connected. This was not a
  partial-data bug (e.g. only dB missing) — it was total data loss for
  every unconnected test ride. Fixed by removing the `if (sent)` gate;
  session creation is now independent of hardware command success,
  matching the existing `0.0`-until-hardware pattern already used for
  dB fields.
- **`avg_speed_kph` always stored as `0.0`** — `_closeSession()` read
  `SpeedService.instance.averageKph` to get the overall session speed,
  but `_finalizeExitWindow()` had already called `SpeedService.instance
  .captureAndClear()` two lines earlier for the exiting-phase average,
  which empties the internal buffer as a side effect. The subsequent
  `averageKph` read in `_closeSession()` was therefore always reading
  an empty buffer. Confirmed via Firestore document inspection showing
  `avg_speed_kph: 0` despite non-zero phase-level speeds already stored
  correctly (`speed_avg_approach`, `speed_avg_inside`,
  `speed_avg_exiting`, which are captured into local variables *before*
  each clear and were never affected). Fixed by computing
  `avg_speed_kph` from the mean of the three already-captured phase
  averages instead of re-reading the drained live buffer.

### ✅ Modified Files

#### `lib/providers/exhaust_provider.dart`
- **Modified:** `checkRestrictedAreaStatus()` — `_startSession()` now
  called unconditionally on zone entry, no longer gated behind BT send
  success
- **Modified:** `_closeSession()` — `avgSpeedKph` now computed as the
  mean of `_avgSpeedApproach` / `_avgSpeedInside` / `_avgSpeedExiting`
  (filtered to non-zero values) instead of reading
  `SpeedService.instance.averageKph` after the buffer was already
  cleared

#### `lib/services/firestore_service.dart`
- **Added:** `findOverlappingZone()` — checks all pending/approved
  zones in a barangay against a proposed new zone's center + radius
  using Haversine distance; returns the conflicting zone's name if the
  circles overlap, `null` otherwise

#### `lib/screens/barangay/barangay_submit_request_screen.dart`
- **Added field:** `_existingAreas` — holds the barangay's approved
  zones for map display
- **Modified:** `_loadBoundary()` — now also subscribes to
  `streamApprovedAreasForBarangay()` and stores results in
  `_existingAreas`
- **Added:** `CircleLayer` rendering `_existingAreas` as green circles
  on the submission map, alongside the existing boundary polygon and
  tapped-pin circle
- **Modified:** `_submitRequest()` — now calls `findOverlappingZone()`
  before submission; blocks and shows an error snackbar naming the
  conflicting zone if an overlap is found

#### `lib/screens/barangay/barangay_ride_logs_screen.dart`
- **Removed:** `_ZoneTabsView` / `_ZoneTabsViewState` — horizontal
  `TabBar` + `TabBarView` per approved zone
- **Added:** `_ZoneCardList` — renders one tappable card per approved
  zone, each showing zone name and a live ride-count subtitle via
  `streamRideSessionsForZone()`
- **Added:** `_ZoneCard` — individual card widget, navigates to
  `_ZoneDetailScreen` on tap
- **Added:** `_ZoneDetailScreen` — pushed screen hosting the existing
  `_ZoneLogView` (summary grid, Latest Record, Previous Records —
  unchanged) scoped to the tapped zone

### ⚠️ Known Limitations (documented, not fixed this session)
- `decibel_*` fields remain `0.0` across all sessions until HC-05
  hardware is physically connected during a ride — this is expected,
  not a bug; the same storage pipeline that now correctly captures
  speed will populate dB automatically once
  `ClassicBluetoothService.instance.averageDb` has real readings to
  average, with no further code changes anticipated
- `findOverlappingZone()` blocks only on radius-circle overlap between
  zones in the *same* barangay; it does not currently prevent a
  barangay from having multiple non-overlapping approved zones — that
  was confirmed as intended behavior, not a gap, for this session
- Zone-overlap check runs as a separate read before submission
  (`get()` on `restricted_areas`) rather than as a Firestore security
  rule or transaction — a race between two officials submitting
  overlapping zones at nearly the same moment is still theoretically
  possible and not addressed here

---

## [0.7.4 patch 9] - GPS Boundary Debounce & BT Command Completion Confirmation

**Status:** ✅ COMPLETED

### 🎯 What This Phase Achieved:
Fixed GPS jitter at restricted-zone boundaries causing rapid duplicate
zone-entry/exit commands. Renamed BT protocol words ZENTER/ZEXIT to
INSIDE/OUTSIDE. Added an explicit Arduino completion signal
(DONE:CLOSE / DONE:OPEN) sent only after the 45° valve rotation actually
finishes, replacing reliance on the immediate ACK fired the instant the
motor starts moving. Flutter's `send()` now waits for the correct
completion signal per command instead of a same-string echo.

### 🐞 Bugs Found & Fixed
- **GPS boundary flapping could fire duplicate INSIDE/OUTSIDE commands**
  — confirmed via field log showing `isInRestricted` flipping true/false
  repeatedly near a zone edge. Fixed with a 1.5s dwell timer in
  `checkRestrictedAreaStatus()`: a raw state flip only commits (and only
  then sends a BT command) after holding for 1.5s.
- **`_valveError` could only detect a disconnected Bluetooth link, not a
  failed or corrupted command** — `sendRaw()` returned true on a
  successful write regardless of whether Arduino received/executed it.
  Fixed by routing INSIDE/OUTSIDE through `send()`, which now waits for
  a command-specific completion line (`DONE:CLOSE`/`DONE:OPEN`) with a
  1s timeout, tightened from the prior 2s default to match the 500ms
  rotation duration.
- **Corrupted BT bytes on the HC-05 link correctly rejected, confirmed
  on hardware** — two garbage reads occurred during field testing;
  word-based command matching rejected both with zero motor misfire.

### ✅ Modified Files
#### `lib/providers/exhaust_provider.dart`
- **Added:** 1.5s dwell debounce (`_pendingRestrictedState`,
  `_restrictedDwellTimer`) in `checkRestrictedAreaStatus()`, now
  synchronous; actual zone-entry/exit logic moved to new
  `_applyRestrictedAreaChange()`
- **Renamed:** BT commands `ZENTER`/`ZEXIT` → `INSIDE`/`OUTSIDE`, sent
  via `send()` instead of `sendRaw()`

#### `lib/services/classic_bluetooth_service.dart`
- **Added:** `_expectedReplyFor()` — maps INSIDE/CLOSE → `DONE:CLOSE`,
  OUTSIDE/OPEN → `DONE:OPEN`, STOP → `ACK:STOP`
- **Modified:** `send()` timeout default 2s → 1s; `_routeLine()` now
  matches the full expected line for both `ACK:` and `DONE:` prefixes

#### Arduino sketch
- **Added:** `DONE:CLOSE`/`DONE:OPEN` sent (mirrored to Serial Monitor)
  only after the timed 45° rotation actually completes
- **Fixed:** direction read after `stopMotor()` always evaluated false,
  causing every completion to log as "open" regardless of actual
  direction
- **Fixed:** `valveRotating` not cleared inside `stopMotor()`, which
  could permanently lock out future rotation commands if stopped
  mid-rotation by another path
- **Changed:** manual OPEN/CLOSE now routed through the same calibrated
  `startValveRotation()` as automatic zone commands, instead of running
  unbounded until the 400ms dead-man's switch cut it off mid-swing
- **Silenced:** ZPING heartbeat no longer logs "unknown command" every
  second

### ⚠️ Known Limitations (not fixed this session)
- Direction-label mismatch still unresolved: `setMotor()` labels
  `CLOSING` as `(CCW)`, while the zone-command handler labels the same
  `CLOSING` action as `45 deg CW`. Physically correct direction not yet
  confirmed against hardware; both print statements need to agree once
  it is.
- 1.5s dwell time is not yet validated against real riding speed vs.
  zone size — picked as a starting value, not field-tuned.
- A suspiciously flat, sustained dB reading (~85 dB, motor idle) was
  observed during this session's test run — possible interference
  source not yet investigated.

---

## [0.7.4 patch 8] - Phase-Averaged Speed & dB Summary (Admin + Barangay Reports)

**Status:** ✅ COMPLETED

### 🎯 What This Phase Achieved:
Replaced the single overall avg-speed / avg-dB-reduced summary on both the
Admin Reports screen and Barangay Ride Logs screen with a phase-level
breakdown — Approach, Inside, Exiting — each showing its own avg speed and
avg dB. Matches the level of detail already captured per-session in
`ride_sessions.snapshots` but not previously surfaced in the summary view.

### ⚠️ Note
- The previous single `avg_db_reduced` figure (before vs. after) is no
  longer displayed anywhere in these two screens — confirm this is the
  intended replacement, not an unintentional loss of the "how much
  quieter" headline metric.

### ✅ Modified Files
#### `lib/screens/admin/admin_reports_screen.dart`
- **Replaced:** `_SummaryCard` (single value) → `_PhaseSummaryCard`
  (speed + dB per phase); added `_avg()` helper filtering to non-zero
  values only

#### `lib/screens/barangay/barangay_ride_logs_screen.dart`
- **Replaced:** `_SummaryTile` → `_PhaseSummaryTile`, same phase
  breakdown pattern as above

---

## [0.7.4 patch 6] - Classic Bluetooth Reliability: Reconnect, Command Verification & BT Pin Remap

**Status:** ✅ COMPLETED — August 12, 2026

### 🎯 What This Phase Achieved:
Fixed a cluster of related Bluetooth reliability issues surfaced during
hands-on HC-05 testing: manual Quick Action commands (`openExhaust()` /
`closeExhaust()`) updated UI state immediately without confirming the
Arduino actually received the command, silent failed reconnects required
a full app restart to recover from, and no auto-connect existed on app
launch (rider had to manually open the connection modal every session).
Also diagnosed and fixed an intermittent BT disconnect issue traced to
the HC-05 TX/RX pins sharing address space with noise-prone Arduino
pins; moved HC-05 wiring from D8/D9 to D2/D3, resolving repeated
mid-session drops confirmed via Serial Monitor garbage-byte output and
spurious `setup()` re-runs (brownout resets).

### 🐞 Bugs Found & Fixed During Implementation
- **Manual commands didn't verify hardware receipt** — `openExhaust()`/
  `closeExhaust()` called `ClassicBluetoothService.send()` without
  awaiting the result, so `setExhaustState()` fired unconditionally.
  If BT was disconnected at tap time, the UI would show OPEN/CLOSED
  while the Arduino never moved. This mirrored a bug already fixed in
  `checkRestrictedAreaStatus()` back in patch 3's known limitations —
  the manual path had the same class of bug and was still unfixed.
  Fixed by awaiting `send()` and only calling `setExhaustState()` on
  confirmed success, setting `_valveError` otherwise.
- **Stuck reconnect state after unexpected drop** — `_connection` was
  only nulled out on disconnect, never actually disposed. Reconnecting
  to the same device address afterward would silently fail or hang,
  requiring a full app restart to recover. Fixed with a proper
  `_forceCloseConnection()` / disposal path in `_handleDisconnect()`
  and before new connect attempts.
- **No connect retry or backoff** — a single failed `toAddress()` call
  gave up immediately with no visibility into why. Added a 3-attempt
  retry loop (800ms delay between attempts, 8s timeout per attempt)
  with `debugPrint` logging of each failure reason.
- **Garbage bytes / spurious resets on HC-05 D8/D9 wiring** — confirmed
  via Serial Monitor showing raw mojibake output interleaved with
  reprinted `"Arduino ready..."` boot messages, indicating actual
  Arduino resets (not just a BT-level drop). Root-caused to the HC-05
  TX/RX pins; moved to D2/D3, confirmed stable across repeated
  OPEN/CLOSE cycles afterward.

### ✅ Modified Files

#### `lib/services/classic_bluetooth_service.dart`
- **Added field:** `_lastDeviceAddress` — tracks the most recently
  connected device for reconnect purposes
- **Modified:** `connect()` — force-closes any stale connection first,
  retries up to 3 times with 800ms backoff and an 8s per-attempt
  timeout, logs each failure via `debugPrint`
- **Added:** `_forceCloseConnection()` — properly finishes/disposes the
  native connection object instead of just nulling the reference
- **Added:** `autoConnect({nameContains = 'HC-05'})` — scans paired
  devices for a name match and connects automatically
- **Added:** `reconnectToLast()` — reconnects to `_lastDeviceAddress`
  without requiring the user to reopen the device picker modal
- **Modified:** `_handleDisconnect()` — now disposes `_connection`
  before nulling it, preventing the stuck-socket restart requirement

#### `lib/providers/exhaust_provider.dart`
- **Modified:** `openExhaust()` / `closeExhaust()` — converted to
  `Future<void>`, now await `send()`'s result and only update
  `ExhaustState` on confirmed success; sets `_valveError` on failure,
  matching the pattern already used in `checkRestrictedAreaStatus()`

#### `lib/main.dart`
- **Added:** `ClassicBluetoothService.instance.autoConnect()` call
  inside the existing rider `postFrameCallback` block, alongside
  `setRiderUid()` and `RestrictedAreasProvider.initialize()`

#### `lib/screens/rider/dashboard_screen.dart`
- **Modified:** `_BluetoothConnectionCard` — added a connecting-state
  spinner and a manual "Retry" button (`reconnectToLast()`) shown when
  disconnected and not currently connecting
- **Added:** Inline warning banner in `_QuickActionsSection`, shown
  when `exhaustProvider.valveError` is true, surfacing failed
  commands instead of failing silently

#### Arduino sketch (`exhaust_valve/exhaust_valve.ino`)
- **Changed:** `SoftwareSerial` pins — HC-05 TX/RX moved from D8/D9 to
  D2/D3 to resolve intermittent disconnects and garbage-byte reads
- **Unchanged:** L298N `IN1`/`IN2` remain on D7/D6; OPEN = CW, CLOSE = CCW

### ⚠️ Known Limitations (documented, not fixed this session)
- `reconnectToLast()` has nothing to reconnect to on a completely fresh
  install before any successful connection this session — relies on
  `autoConnect()` to cover that first-time case instead
- BT reliability fixes not yet validated with the L298N motor actually
  running — motor current draw sagging the shared power rail was
  flagged as a likely contributor to drops and is still untested as a
  standalone variable now that the pin remap is in place
- No decoupling capacitor added yet near HC-05 VCC/GND, still a
  candidate fix if drops resume once the motor is back in the loop
- `BluetoothProvider` (BLE, `flutter_blue_plus`) remains registered in
  `main.dart`'s `MultiProvider` but is unused for HC-05 (Classic/SPP);
  flagged as dead weight, not removed this session

---

## [0.7.4 patch 5] - Barangay-Aware Live Address + GPS Jitter/Accuracy Filtering

**Status:** ✅ COMPLETED — August 4, 2026

### 🎯 What This Phase Achieved:
Fixed two related rider-facing issues on the Map screen: the live location
address showing only municipality/province ("Guiuan, Eastern Visayas,
Philippines") with no barangay, and the GPS marker/speed drifting while
the device was stationary. Barangay resolution now checks the rider's
live coordinates against the app's own 16 seeded barangay polygons
(reusing the same ray-casting point-in-polygon logic already trusted for
zone-request boundary enforcement in `barangay_submit_request_screen.dart`),
falling back to OSM's `subLocality` only if no seeded polygon matches.
GPS/speed jitter was addressed with a layered filter: an accuracy-based
rejection (fixes worse than 20m are dropped, except the very first fix
after cold start so the UI doesn't stall on "Fetching location..."), a
6-meter stationary-radius gate that skips marker/address/zone-check
updates for fixes that aren't meaningfully different from the last
accepted position, and a `SpeedService`-level fix that ignores
low-accuracy readings and floors small speed values as GPS noise rather
than real movement.

### 🐞 Bugs Found & Fixed During Implementation
- **OSM `subLocality` empty for rural barangays** — confirmed via device
  logs that `placemarkFromCoordinates()` succeeds but returns an empty
  `subLocality` for Guiuan-area coordinates; not a plugin bug, OSM simply
  has no barangay-level boundary tags for this rural municipality.
  Resolved by resolving barangay locally against seeded polygon data
  instead of depending on third-party geocoder coverage.
- **Fallback speed formula amplified GPS jitter** — `SpeedService`'s
  position-diff fallback divides distance by elapsed time at 250ms
  polling; a couple meters of ordinary GPS scatter on a stationary
  device was translating into false 5-20 kph readings. Fixed with an
  accuracy-based reject plus a raised stationary floor (6 kph).
  Confirmed root cause via device log showing `pos.speed` and computed
  fallback kph moving in step with `accuracy` degrading from 3m to 34m.
- **Marker/address updating on every tick regardless of real movement**
  — `distanceFilter: 0` meant every GPS fix (including pure noise)
  triggered a full re-geocode + zone re-check + marker move. Fixed with
  a 6m stationary-radius gate keyed off the last *accepted* position.
- **Accuracy filter stalled first-fix display** — an early version of
  the accuracy gate rejected the very first GPS fix after app launch
  (which is typically low-accuracy before the chip fully locks),
  regressing the "instant fetch" feel the app previously had. Fixed by
  letting the first fix through unconditionally and only applying the
  accuracy/stationary filters to fixes after `_locationReady` is true.
- **Silent geocoding failures** — the original `catch (_) {}` around
  `placemarkFromCoordinates()` swallowed all exceptions with no
  visibility. Replaced with a logged catch (`[Geocode ERROR]`) to keep
  future geocoding failures diagnosable instead of failing invisibly.

### ✅ Modified Files

#### `lib/utils/geo_utils.dart`
- **Added:** `getBarangayForPoint(lat, lng, barangays)` — checks a GPS
  point against every seeded barangay's `boundary_polygon` using the
  existing `isPointInPolygon()` ray-casting function; returns the
  matching `barangay_name`, or `''` if the point falls outside all
  seeded boundaries

#### `lib/services/firestore_service.dart`
- **Added:** `getAllBarangays()` — fetches all docs in the `barangays`
  collection for local point-in-polygon lookups (existing
  `getBarangaysByMunicipality()` and `getBarangayBoundary()` methods
  were scoped differently and didn't cover this use case)

#### `lib/services/speed_service.dart`
- **Added:** Accuracy-based reject in `_tick()` — fixes worse than 15m
  accuracy are held at `0.0` kph rather than trusted for speed
  calculation
- **Updated:** Stationary floor raised from 3.0 → 6.0 kph to absorb
  GPS-chip-native (`pos.speed`, Doppler-based) noise independent of any
  position-diff filtering happening elsewhere

#### `lib/screens/rider/map_screen.dart`
- **Added import:** `firestore_service.dart`, `geo_utils.dart`
- **Added fields:** `_allBarangays`, `_lastAcceptedLat`/`_lastAcceptedLng`,
  `_stationaryRadiusMeters` (6.0)
- **Added:** `_loadBarangays()` — fetches all seeded barangay polygons
  once on `initState()`
- **Modified:** `_onPositionUpdate()` — added accuracy-based reject
  (skipped for the very first fix), 6m stationary-radius gate, barangay
  resolution via `getBarangayForPoint()` with OSM `subLocality` fallback,
  and logged geocoding error handling
- **Modified:** Address string now composed as street → barangay
  (resolved or OSM fallback) → municipality → province → region

### ⚠️ Known Limitations (documented, not fixed this session)
- Barangay resolution depends on the 16 hand-traced polygon boundaries
  seeded in Phase 0.7.3 patch 1 — confirmed via device testing that at
  least one real-world coordinate near central Guiuan falls in a gap
  between seeded polygons and returns no barangay match (falls back to
  OSM, which is also typically empty for this area). Polygon coverage
  is accurate within traced wards but not guaranteed gap-free at edges.
- OSM/Play Services reverse geocoding remains unreliable on the test
  device — `GoogleApiManager: SecurityException: Unknown calling package
  name 'com.google.android.gms'` recurs throughout logs, likely tied to
  this being a Transsion/Infinix (MediaTek) device with nonstandard
  Play Services behavior. Not blocking (app now resolves barangay
  locally regardless), but flagged in case other Play Services-dependent
  features surface issues on similar devices.
- 20m accuracy threshold and 6m stationary radius are initial values,
  not yet tuned against a real outdoor ride — worth revisiting once
  field-tested with actual motorcycle movement rather than stationary
  bench testing.
- Investigated PSGC (Philippine Statistics Authority) official barangay
  shapefiles as a potential free, higher-accuracy replacement for the
  hand-traced polygons — confirmed availability via
  `github.com/altcoder/philippines-psgc-shapefiles`, not yet imported.
  Deferred; current polygons considered sufficient for now.

**Status:** ✅ COMPLETED — July 25, 2026

### 🎯 What This Phase Achieved:
UI/UX polish pass on the Rider Map and Dashboard screens. Added a
Google-Maps-style compass to the map — always visible, needle rotates
opposite the map's rotation to keep pointing true north, tap triggers a
smooth animated snap-back (rotation to 0°, zoom to default 15.0, and
recenter on the rider's actual live GPS position, not just the last
panned viewport). Configured `flutter_map`'s built-in disk tile cache
(300MB limit, 1-day freshness override) so previously-seen tiles render
instantly on weak/unstable connections instead of re-fetching. Map now
shows the device's last-known GPS fix immediately on screen load instead
of sitting on a hardcoded default coordinate while waiting for the first
live fix. Quick Actions (Open/Close Exhaust) converted from two
independent flat buttons into a true toggle pair driven by real
`ExhaustProvider` state — whichever button matches the actual exhaust
state is lit/solid, the other dims, with a press-scale bounce for tap
feedback. Added a live telemetry card below Quick Actions showing
real-time speed and a decibel placeholder (same `0.0`-until-hardware
pattern used in ride session snapshots).

### 🐞 Bugs Found & Fixed During Implementation
- **`overrideFreshAge` misplaced** — initially passed to `NetworkTileProvider` directly; correct location is inside `BuiltInMapCachingProvider.getOrCreateInstance()`. Caused an `undefined_named_parameter` build error, fixed by moving the argument.
- **`SingleTickerProviderStateMixin` ticker collision** — `_MapScreenState` already ran one continuous ticker for the GPS pulse-dot animation; adding a second `AnimationController` for the compass-reset animation threw "multiple tickers were created." Fixed by switching to `TickerProviderStateMixin`.
- **Compass reset landed on stale center** — first version of `_resetNorth()` only animated rotation/zoom around the map's current viewport center, so if the user had panned away from their GPS dot before tapping, it "reset" to the wrong spot. Fixed by also tweening the center toward `_currentLat`/`_currentLng` (the live position) in the same animation.
- **Duplicate recenter control** — compass was initially placed alongside the existing bottom-right recenter FAB, creating two overlapping circular buttons. Removed the redundant FAB (recenter already lives in the AppBar action) and moved the compass into that freed bottom-right slot.

### ✅ Modified Files

#### `lib/screens/rider/map_screen.dart`
- **Changed:** `SingleTickerProviderStateMixin` → `TickerProviderStateMixin`
- **Added:** `_loadLastKnownPosition()` — renders cached GPS fix immediately on init instead of waiting for first live stream event
- **Added:** Map rotation tracking via `mapController.mapEventStream`
- **Added:** Compass widget (bottom-right, replaces old recenter FAB) — needle rotates opposite map rotation, always visible
- **Added:** `_resetNorth()` — animated (350ms, easeOutCubic) combined rotation-to-0 + zoom-to-15.0 + recenter-to-live-position on compass tap
- **Removed:** Redundant bottom-right recenter `FloatingActionButton` (recenter already available via AppBar action)
- **Updated:** `TileLayer` — `tileProvider` now uses `NetworkTileProvider` with `BuiltInMapCachingProvider.getOrCreateInstance()`, 300MB cache limit, 1-day `overrideFreshAge`

#### `lib/services/speed_service.dart`
- **Added:** `currentDb` getter — `0.0` placeholder, same pattern as other dB fields pending IoT hardware

#### `lib/screens/rider/dashboard_screen.dart`
- **Added import:** `speed_service.dart`
- **Modified:** `_QuickActionsSection` — Open/Close buttons now pass `isActive` derived from real `exhaustProvider.isOpen` / `isClosed`, not just tap history
- **Modified:** `_ActionButton` — converted to `StatefulWidget`, added press-scale animation (`AnimatedScale`, 100ms) and lit/dimmed color states based on `isActive`
- **Added:** `_LiveTelemetryCard` + `_TelemetryStat` — live speed (km/h) and dB placeholder display below Quick Actions, listens to `SpeedService` via `AnimatedBuilder`

### ⚠️ Known Limitations (not yet field-tested)
- Tile caching improvement has only been confirmed to build and run correctly — not yet tested under actual weak/unstable signal conditions (e.g. airplane-mode-mid-load) or on an actual moving ride
- Compass rotate gesture and reset-to-north animation confirmed working on-device, but not yet tested during actual motorcycle movement/vibration

---

## [0.7.4 patch 3] - GPS Geofence Auto-Trigger Validated (Simulated)

**Status:** ✅ COMPLETED — July 10, 2026

### 🎯 What This Phase Achieved:
Discovered that Phase 8 automation logic (`checkRestrictedAreaStatus()` calling `ClassicBluetoothService.instance.send('CLOSE'/'OPEN')` on zone entry/exit) was already implemented in `exhaust_provider.dart`, despite prior docs listing Phase 8 as 0%/unblocked-not-started. Debugged and fixed a silent GPS→trigger failure caused by a loose HC-05 TX/RX jumper wire connection (intermittent noise on serial line). After rewiring, validated the full automatic chain using Lockito GPS mock through a real seeded barangay zone: entry correctly triggered `CLOSE` (motor spun via single relay), exit correctly triggered `OPEN` (motor stopped). This is real hardware response to simulated GPS movement — not yet tested on an actual moving ride.

### 🐞 Bugs Found & Fixed
- **Loose HC-05 TX/RX jumper wires** — caused continuous garbage bytes (`�`) on serial read, blocking all real command parsing. Fixed by reseating connections firmly; confirmed via clean single-command echo.

### ⚠️ Known Limitations (documented, not fixed this session)
- `ClassicBluetoothService.send()` silently no-ops if BT is disconnected — `checkRestrictedAreaStatus()` does not currently verify the command reached the Arduino before logging state/session/closure count. Flagged as High priority tech debt.
- Test was simulated GPS (Lockito) with stationary hardware bench setup — not validated on an actual moving motorcycle yet.
- Single relay only — spin/stop confirmed, no CW/CCW direction control yet (Phase 7.4 hardware, second relay in hand, not yet wired).

### 📝 Also Identified
- Unused/dead hand-rolled trigonometry (`DoubleExtension.sin/cos/asin/sqrt/atan`) and unused `_toRadians()` in `restricted_area.dart` — not called anywhere, real logic correctly uses `dart:math`. Flagged for removal, not a functional bug.

---

## [0.7.4 patch 2] - Admin Reports Screen + GPS Smoothing + Speed Overlay

**Status:** ✅ COMPLETED — Jun 11, 2026

### 🎯 What This Phase Achieved:
Added a Reports tab to the Super Admin navigation with a barangay list screen and a detailed per-barangay report screen showing the assigned official, summary stats (riders passed, avg speed, avg dB, avg dB reduced), and per-session zone pass records with approach/entry/exit snapshot breakdown. Improved GPS update rate from 8 seconds to 250ms for smoother map movement. Added a live speed overlay (km/h) on the Rider map screen. Updated SpeedService polling to 250ms to match GPS rate.

### ✅ New Files

| File | Purpose |
|------|---------|
| `lib/screens/admin/admin_reports_screen.dart` | Reports tab — barangay list → detail with official info, summary cards, session records |

### ✅ Modified Files

#### `lib/screens/rider/map_screen.dart`
- **Updated:** `_startLocationStream()` — interval changed from 8s to 250ms, accuracy upgraded to `bestForNavigation`, `distanceFilter` set to 0
- **Added:** Speed overlay widget — live km/h display bottom-left of map, reads from `SpeedService.instance.currentKph`

#### `lib/services/speed_service.dart`
- **Updated:** Timer interval changed from 1 second to 250ms to match GPS update rate

#### `lib/screens/admin/admin_navigation_screen.dart`
- **Added import:** `admin_reports_screen.dart`
- **Added:** Reports `_NavItem` (bar chart icon) between Map and Profile tabs
- **Added:** `AdminReportsScreen()` to screens list

### 📝 Pending — Code Hygiene (tracked, not yet applied)
- `withOpacity` → `withValues()` — 8 instances across login, signup, splash, permission_handler, custom_button, custom_text_field
- `value` → `initialValue` — 4 instances in admin_create_official, admin_manage_officials
- `use_build_context_synchronously` — admin_create_official, barangay_notifications
- `curly_braces_in_flow_control_structures` — restricted_area.dart, admin_create_official
- `dangling_library_doc_comment` — geo_utils.dart
- `prefer_final_fields` — restricted_areas_provider
- `use_null_aware_elements` — admin_global_map_screen

---

## [0.7.4 patch 1] - Speed Tracking, Ride Session Logging & Speed Monitor

**Status:** ✅ COMPLETED — May 10, 2026

### 🎯 What This Phase Achieved:
Implemented a full speed tracking and ride session logging system. GPS speed is captured every second with a position-diff fallback when GPS speed is unavailable. Zone pass-throughs are recorded as ride sessions with 3 snapshots per zone (approach, entry, exit). Barangay Officials now have a Logs tab to view session data including average speed, decibel reduction (placeholder until IoT hardware arrives), and per-snapshot breakdowns. A live Speed Monitor screen was added to Super Admin Developer Tools for Lockito mock testing and real GPS speed validation.

### ✅ New Files

| File | Purpose |
|------|---------|
| `lib/services/speed_service.dart` | Singleton — GPS speed every second, position-diff fallback, rolling buffer, average calculator |
| `lib/models/ride_session.dart` | `RideSnapshot`, `RideSession` data models with `toMap()`/`fromMap()` |
| `lib/screens/barangay/barangay_ride_logs_screen.dart` | Logs tab for Barangay Official — streams sessions, shows speed/dB stats, snapshot breakdown |
| `lib/screens/test/speed_monitor_screen.dart` | Super Admin Dev Tools — live speed gauge, GPS vs fallback tag, last 20 readings log, clear button |

### ✅ Modified Files

#### `lib/services/firestore_service.dart`
- **Added import:** `ride_session.dart`
- **Added:** `createRideSession()` — creates a new `ride_sessions` doc, returns doc ID
- **Added:** `closeRideSession()` — updates session with avg speed, dB reduction, snapshots, end time
- **Added:** `streamRideSessions(barangayId)` — streams last 50 sessions for a barangay official
- **Added:** `streamRiderSessions(riderUid)` — streams last 50 sessions for a specific rider

#### `lib/providers/exhaust_provider.dart`
- **Added imports:** `SpeedService`, `FirestoreService`, `RideSession`, `RestrictedArea`
- **Added fields:** `_activeSessionId`, `_activeZoneId`, `_activeZoneName`, `_activeZoneBarangayId`, `_riderUid`, `_sessionSnapshots`, `_approachSnapshotTaken`, `_approachRadiusBuffer` (50m)
- **Added getter:** `currentSpeedKph` — reads from `SpeedService.instance`
- **Added:** `setRiderUid(uid)` — call after login to attach rider UID to session tracking
- **Modified:** `updateLocation()` — now accepts `nearestZone` + `distanceToZone`, starts speed tracking on first fix, fires approach snapshot at 50m buffer before zone edge
- **Modified:** `checkRestrictedAreaStatus()` — now accepts optional `zone` parameter; fires entry/exit snapshots, starts/closes Firestore session, clears speed buffer on entry
- **Added:** `_takeSnapshot()` — creates `RideSnapshot` at approach/entry/exit with current speed and dB placeholder
- **Added:** `_startSession()` — creates Firestore `ride_sessions` doc on zone entry
- **Added:** `_closeSession()` — closes session doc with avg speed, dB values, all snapshots on zone exit

#### `lib/screens/rider/map_screen.dart`
- **Added imports:** `SpeedService`, `RestrictedArea`, `dart:math`
- **Added:** `_haversineMeters()` helper — calculates distance between two GPS coordinates
- **Modified:** `_onPositionUpdate()` — feeds each position to `SpeedService.instance.onPositionUpdate()`
- **Modified:** `updateLocation()` call — now computes nearest zone + distance across all areas and passes them to `ExhaustProvider`

#### `lib/screens/barangay/barangay_navigation_screen.dart`
- **Added import:** `barangay_ride_logs_screen.dart`
- **Added:** Logs `_NavItem` (bar chart icon) between Alerts and Profile tabs
- **Added:** `BarangayRideLogsScreen()` to the screens list

#### `lib/screens/shared/shared_profile_screen.dart`
- **Added import:** `speed_monitor_screen.dart`
- **Added:** `_Divider()` + Speed Monitor `_ActionRow` under HC-05 row in Developer Tools section

#### `lib/main.dart`
- **Added import:** `speed_service.dart`
- **Added:** `ChangeNotifierProvider.value(value: SpeedService.instance)` to provider list

### ✅ Firestore

#### New Collection: `ride_sessions`
```
ride_sessions/{session_id}
├── rider_uid         string
├── zone_id           string
├── zone_name         string
├── barangay_id       string
├── started_at        string (ISO 8601)
├── ended_at          string (ISO 8601)
├── avg_speed_kph     number
├── decibel_before    number   ← 0.0 placeholder until IoT arrives
├── decibel_after     number   ← 0.0 placeholder until IoT arrives
├── decibel_reduced   number   ← calculated: before - after
└── snapshots         array
    └── { type, speed_kph, decibel_db, exhaust_state, zone_id, zone_name, timestamp }
```

#### New Composite Indexes
| Collection | Field 1 | Field 2 | Scope |
|---|---|---|---|
| `ride_sessions` | `barangay_id` ASC | `started_at` DESC | Collection |
| `ride_sessions` | `rider_uid` ASC | `started_at` DESC | Collection |

### 📝 Logging Strategy
| Trigger | What Is Logged |
|---------|----------------|
| 50m before zone edge | Approach snapshot — speed + dB + exhaust state |
| Zone entry | Entry snapshot — speed + dB + exhaust state; session doc created |
| Zone exit | Exit snapshot — speed + dB + exhaust state; session doc closed with averages |
| Every second always | Speed reading stored in `SpeedService` buffer (not written to Firestore per tick) |

### 📝 Notes
- Decibel readings are `0.0` placeholders throughout — IoT noise sensor hardware has not arrived yet. When it does, only `decibelDb: 0.0` in `exhaust_provider.dart → _takeSnapshot()` needs to be replaced with the live BT reading.
- `SpeedService` uses `geolocator` GPS speed (`m/s → km/h`). Falls back to Haversine position-diff calculation when GPS returns `-1`.
- Speed Monitor screen is Super Admin only — not visible to Rider or Barangay Official roles.
- `flutter analyze` — zero new errors. 21 pre-existing `info`-level warnings remain (tracked in tech debt — unchanged).

### 🗂️ Folder Impact
```
lib/
├── main.dart                                              ✅ UPDATED — SpeedService provider
├── models/
│   └── ride_session.dart                                  ✅ NEW
├── services/
│   ├── firestore_service.dart                             ✅ UPDATED — ride session methods
│   └── speed_service.dart                                 ✅ NEW
├── providers/
│   └── exhaust_provider.dart                              ✅ UPDATED — speed + snapshot wiring
├── screens/
│   ├── rider/
│   │   └── map_screen.dart                                ✅ UPDATED — SpeedService feed + zone distance
│   ├── barangay/
│   │   ├── barangay_navigation_screen.dart                ✅ UPDATED — Logs tab added
│   │   └── barangay_ride_logs_screen.dart                 ✅ NEW
│   ├── shared/
│   │   └── shared_profile_screen.dart                     ✅ UPDATED — Speed Monitor in Dev Tools
│   └── test/
│       └── speed_monitor_screen.dart                      ✅ NEW
```

---

## [0.7.3 patch 1] - Barangay Polygon Expansion

**Status:** ✅ COMPLETED — March 23, 2026

### 🎯 What This Phase Achieved:
Expanded the `/barangays` Firestore collection from 2 entries to 16 by seeding 14 Poblacion ward polygons for Guiuan, Eastern Samar. All polygon boundaries were manually created. Uploaded via the existing `add_barangay.js` Node.js seeding script.

### ✅ Barangays Seeded

| Document ID | Barangay | Points | Result |
|-------------|----------|--------|--------|
| guiuan-lupok | Lupok | 51 | Overwritten (re-upload) |
| guiuan-salug | Salug | 23 | Overwritten (re-upload) |
| guiuan-poblacion-ward-1 | Poblacion Ward 1 | 16 | New |
| guiuan-poblacion-ward-2 | Poblacion Ward 2 | 8 | New |
| guiuan-poblacion-ward-3 | Poblacion Ward 3 | 19 | New |
| guiuan-poblacion-ward-4 | Poblacion Ward 4 | 25 | Overwritten (was seeded earlier) |
| guiuan-poblacion-ward-4a | Poblacion Ward 4-A | 10 | New |
| guiuan-poblacion-ward-5 | Poblacion Ward 5 | 25 | New |
| guiuan-poblacion-ward-6 | Poblacion Ward 6 | 36 | New |
| guiuan-poblacion-ward-7 | Poblacion Ward 7 | 20 | New |
| guiuan-poblacion-ward-8 | Poblacion Ward 8 | 20 | New |
| guiuan-poblacion-ward-9 | Poblacion Ward 9 | 12 | New |
| guiuan-poblacion-ward-9a | Poblacion Ward 9-A | 16 | New |
| guiuan-poblacion-ward-10 | Poblacion Ward 10 | 30 | New |
| guiuan-poblacion-ward-11 | Poblacion Ward 11 | 35 | New |
| guiuan-poblacion-ward-12 | Poblacion Ward 12 | 19 | New |

### 🗂️ Folder Impact
> No Flutter code changes. All work was Firestore data seeding via Node.js script.

### 📝 Notes
- Polygon coordinates hand-crafted per barangay — no third-party GeoJSON source
- Script (`add_barangay.js`) overwrites existing documents safely — safe to re-run
- More barangays to be added incrementally as needed

---

## [0.7.3] - Phase 7.3: DC Motor Hardware Test + Relay Wiring Validation

**Status:** ✅ COMPLETED — March 21, 2026

### 🎯 What This Phase Achieved:
Validated DC motor spin control via single 5V relay module using a dedicated 9V battery as the motor power supply. Confirmed that the existing Arduino sketch (no code changes needed) can spin and stop a DC motor salvaged from an Epson printer using OPEN/CLOSE commands from the Flutter app over HC-05. This serves as the physical prototype foundation for the exhaust valve mechanism.

### ✅ Validation Results
- ✅ CLOSE command → relay energizes → motor spins confirmed
- ✅ OPEN command → relay de-energizes → motor stops confirmed
- ✅ Dedicated 9V battery successfully powers motor without affecting Arduino
- ✅ Shared ground between 9V battery and Arduino confirmed working
- ⚠️ Single relay = spin/stop only — no direction reversal possible with current setup

### 🗂️ Folder Impact
> No Flutter code changes this session. All work was hardware wiring and validation.

---

## [0.7.2] - Phase 7.2: UI Hardening, Dev Tool Relocation & Dashboard Cleanup

**Status:** ✅ COMPLETED — March 21, 2026

### 🎯 What This Phase Achieved:
Cleaned up the rider dashboard by fully removing the temporary HC-05 dev test shortcut. Relocated the hardware test screen exclusively to the Super Admin profile under a new "Developer Tools" section. Fixed a stray brace compile error introduced during the removal. Verified zero errors on `flutter analyze` before pushing.

### ✅ Modified Files
- `shared_profile_screen.dart` — Added Developer Tools section (superadmin only), HC-05 ActionRow, version bump v0.7.0 → v0.7.1
- `dashboard_screen.dart` — Removed `_DevTestButton` widget, import, and class entirely. Fixed stray `}` compile error.

---

## [0.7.1] - Phase 7.1: HC-05 Classic Bluetooth Hardware Validation

**Status:** ✅ COMPLETED — March 19, 2026

### 🎯 What This Phase Achieved:
Validated full two-way Classic Bluetooth communication between Flutter app and Arduino Uno via HC-05 module. Confirmed relay actuation from Flutter app. Unblocked Phase 8 hardware automation.

### ✅ Validation Results
- ✅ Flutter → HC-05 → Arduino: HELLO, OPEN, CLOSE received correctly
- ✅ Arduino → HC-05 → Flutter: ACK responses displayed in app serial log
- ✅ Relay clicks on CLOSE, releases on OPEN
- ✅ Full two-way communication confirmed at 9600 baud

---

## [0.7.0] - Phase 7: Multi-Role System Expansion

**Status:** 🔄 IN PROGRESS (~98% of phase complete)
**Date Started:** March 2026

### 🎯 What This Phase Achieved:
Expanded from single-role rider app to full 3-role system. Adds Admin screens (dashboard, inbox, officials, global map), Barangay Official screens (dashboard, submit, history, notifications), barangay boundary enforcement, and in-app notification system.

### ⚠️ Still Pending in Phase 7
- [ ] **7.4** — Seed Super Admin in Firestore console (manual, 5 min)
- [ ] **7.19** — Firestore security rules (HIGH RISK — do last before demo)
- [ ] **7.20** — FCM push notifications (optional)

---

## [0.6.1] - Phase 6 Patches & Background GPS
**Status:** ✅ COMPLETED — March 5, 2026

## [0.6.0] - Phase 5 & 6: GPS, Map Integration & Geocoding
**Status:** ✅ COMPLETED — February 17, 2026

## [0.4.0] - Phase 4: Bluetooth Hardware Integration
**Status:** ✅ COMPLETED — February 17, 2026

## [0.3.0] - Phase 3: Device Permissions & Enhanced UI
**Status:** ✅ COMPLETED — February 11, 2026

## [0.2.0] - Phase 2: Dashboard & Navigation
**Status:** ✅ COMPLETED — February 11, 2026

## [0.1.0] - Phase 1: UI/UX Foundation & Branding
**Status:** 🔄 80% Complete — logo integration pending

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
| 0.7.0 (patch 2) | Notifications, UI/UX Polish, Pro Nav, Profile Redesign | ✅ Complete | Mar 15, 2026 |
| 0.7.0 (patch 3) | Barangay Geofencing + Manual Polygon Seeding + Boundary Check | ✅ Complete | Mar 18, 2026 |
| 0.7.1 | HC-05 Classic BT Validation + Relay Test | ✅ Complete | Mar 19, 2026 |
| 0.7.2 | Dev Tool Relocation + Rider Dashboard Cleanup | ✅ Complete | Mar 21, 2026 |
| 0.7.3 | DC Motor Spin Test + Relay Wiring Validation | ✅ Complete | Mar 21, 2026 |
| 0.7.3 patch 1 | Barangay Polygon Expansion — 16 barangays seeded | ✅ Complete | Mar 23, 2026 |
| **0.7.4 patch 1** | **Speed Tracking + Ride Session Logging + Speed Monitor Dev Tool** | **✅ Complete** | **May 10, 2026** |
| **0.7.4 patch 2** | **Admin Reports Screen + Nav Tab + Code Cleanup (pending)** | **✅ Complete** | **Jun 11, 2026** |
| 0.7.4 patch 5 | Barangay-Aware Live Address + GPS Jitter/Accuracy Filtering | ✅ Complete | Aug 4, 2026 |
| **0.7.4 patch 6** | **Classic Bluetooth Reliability: Reconnect, Command Verification & BT Pin Remap** | **✅ Complete** | **Aug 12, 2026** |
| 0.7.4 | Second Relay + Solder + CW/CCW Direction Control | 🟡 Next (hardware) | TBD |
| 0.8.0 | Core HC-105 Automation (geofence → relay → motor) | ⏳ Pending | TBD |

---

**Maintained by:** Development Team
**Last Updated:** August 12, 2026