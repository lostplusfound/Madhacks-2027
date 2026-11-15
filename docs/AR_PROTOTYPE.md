# Android AR localization prototype

The app home is now a list of named maps. Map and anchor metadata are saved in
SharedPreferences on this phone. Cloud Anchor hosting and resolution use Google
Cloud directly; no Serverpod domain endpoints or migrations are required.

The published `ar_flutter_plugin_plus` version remains pinned at 1.1.3. A local
override under `third_party/` fixes its Android cloud-result delivery from the
render thread, reports native cloud errors, and prevents a fast-upload callback
race. It also handles camera-surface replacement during compact/expanded layout,
exposes consistent localization frames, and supports retained/cancelled anchors.
See [patch provenance](../third_party/ar_flutter_plugin_plus/PATCHES.md).
This source came from the published package, not the InsideOut prototype.
After this native patch, fully stop and rebuild/run the app yourself; hot reload
or Dart hot restart cannot replace its Android code. App builds, installation,
and launches require the user's explicit request.

## Current status

The latest local integration includes map-first floor-1 navigation, tappable and
rotatable map controls, heading-follow, estimated return-to-route guidance, and
compact/expanded AR. See [floor setup and controls](FLOOR_NAVIGATION.md) and the
[testing guide](TESTING.md) for the complete behavior and physical checklist.
The legacy AR-first layout remains available by disabling floor association.

Latest recorded checks on November 14, 2026: **80 Flutter tests passed**, analysis
had no errors/warnings (informational notices remain), and the Android debug APK
built. Historical 19/30/36-test snapshots below describe earlier stages. Current
compact-device localization and measured navigation accuracy remain unverified.

## Configure and run

Use an ARCore-compatible Android phone (initial test target: Pixel 6a), enable
camera permission, and keep an internet connection. In your existing Google
Cloud project enable the ARCore API. New anchors request a 365-day lifetime using
Android keyless authorization (OAuth); API keys support only one day.

1. Obtain the signing SHA-1 for the build you will install. From
   `madmaps_flutter/android`, run `./gradlew.bat signingReport` with Java 17;
   copy the debug variant's SHA1 for local builds.
2. In the same Google Cloud project, open **APIs & Services > Credentials >
   Create credentials > OAuth client ID**. Choose **Android**, use package name
   `space.serverpod.madmaps`, and paste that SHA-1. Complete any Google Auth
   Platform setup the console requires. Create a client for each different signing
   certificate (teammates' debug keys, production, or Play app-signing key).
3. No client ID or client secret needs to be pasted into Flutter. The plugin
   already includes Google's required Play Services auth dependency. The app
   removes `com.google.android.ar.API_KEY` from the merged manifest so ARCore uses
   keyless authorization. Old `arcore.apiKey` / `ARCORE_API_KEY` settings are ignored
   and can be removed locally.
4. Fully stop and rebuild/reinstall the Android app, preserving app data; hot
   reload/restart cannot update the native configuration. Do not uninstall if you
   want to keep the phone's locally saved maps.
5. Host a new anchor and confirm its displayed expiry is approximately 365 days
   away. Close and reopen the app, then resolve it near the same location. Repeat
   after 24 hours to validate persistence beyond the old limit. If hosting reports
   NOT_AUTHORIZED, check API enablement, package name, and the installed build's
   signing SHA-1 in that same Cloud project.

Existing saved anchors retain their original expiry; this change does not renew
previously hosted anchors. Add new anchors while their map is still localizable,
or create a new map if all old anchors have expired. The shared lifetime setting
is `lib/features/localization/cloud_anchor_config.dart` (maximum 365 days).
Remote OAuth registration and physical long-term persistence still require
verification; a successful build alone does not validate authorization.
See Google's [Android authorization guide](https://developers.google.com/ar/develop/authorization?platform=android).

The pinned AR plugin requires a Java 17 toolchain. Use a Windows ARM64/AArch64
JDK on an ARM64 computer. This workspace has a portable Microsoft JDK 17 under
the ignored `.dart_tool/toolchains/jdk17/`; its JVM reports `os.arch = aarch64`.
For a build using this installation without changing global Flutter settings,
run this from the repository root after `flutter pub get`:

```powershell
$arJdk = Get-ChildItem .dart_tool/toolchains/jdk17 -Directory |
    Select-Object -First 1 -ExpandProperty FullName
$env:JAVA_HOME = $arJdk
cd madmaps_flutter/android
./gradlew.bat assembleDebug
```

On another computer, replace `$arJdk` with that computer's Java 17 installation.
The portable JDK is a local build dependency and is not included in source control.
For Flutter/runner builds, select that ARM64 JDK with
`flutter config --jdk-dir <absolute-jdk17-path>` (this changes Flutter's global
JDK setting), or register Java 17 with Gradle's toolchain discovery. This machine's
Flutter JDK setting now points to the portable ARM64 Java 17 above, so normal
Flutter launches use the required toolchain. Restart open editors if they cached
the previous Java 21 setting. If you move or delete `.dart_tool`, configure a new
Java 17 installation before building again.

On Windows, enable Developer Mode if `flutter pub get` reports that plugins need
symlink support. Connect the phone through wireless ADB or USB. Use the Serverpod
runner's Flutter launch/restart tools when available; the configured driver entry
point is `lib/driver.dart`. For a standalone manual Android build:

```powershell
cd madmaps_flutter
flutter pub get
flutter build apk --debug
```

## Use

1. Create and open a named map. Move slowly until ARCore detects a horizontal
   or vertical surface (such as a wall). Choose **Add anchor**, then tap where
   you want to place it.
2. Scan around the point. The movement-coverage bar is advisory and does not
   represent ARCore feature-map quality, which the pinned plugin does not expose.
   Keep the surrounding surfaces in view and move sideways around the point.
   Press **Save anchor** whenever you choose, enter a name, and wait for cloud
   hosting. Save remains available even with low coverage while tracking works.
   A success message confirms persistence. Failed saves retain the draft for retry;
   **Cancel** discards it. Add more anchors in the same tracked session.
3. In the legacy AR-first layout, select **Anchors** and tap a destination,
   or tap its mini-map marker. The arrow
   points directly toward it; walls and obstacles are not considered. Arrival is
   within one horizontal meter.
4. In the legacy layout, expand the mini-map with its upper-right button;
   pinch to zoom and pan. The
   blue dot is your current position and its line shows camera heading. Orange
   marks the selected destination, teal marks anchors, and gray marks expired ones.
5. From home, choose **Find my location** and scan near any saved anchor.
   Initial discovery searches distinct, unexpired Cloud Anchor IDs across this
   phone's saved maps in batches of at most 20. The first successful match opens its map in the same AR
   session, with the position dot and existing navigation. Treat each saved map
   as one floor and name it accordingly. Alternatively, open a map and use the
   location icon to search only that map, or choose an anchor's **Localize here**
   menu item for manual localization. Then select a destination or add anchors.
6. Menus support renaming and deleting local records. Deletion does not revoke
   hosted Cloud Anchors. Records remain after cloud expiry; expired anchors cannot
   be used to localize, but remain usable as destination coordinates after
   localization using another live anchor. If all anchors expire, create a new map.

Opening a floor-associated map automatically searches that map's live anchors.
Once a map is established, **Locate** / **Find my location again** refreshes its
alignment while retaining the old fix on failure. Global discovery across saved
maps is available by returning home and using **Find my location**. No unknown
nearby IDs are discovered, and there is no continuous floor detection or
cross-floor route guidance.

Automatic discovery batches time out after 10 seconds and retry after 20 seconds
from completion of the search. Explicit initial searches retain the 90-second
per-batch timeout. Larger catalogs continue through subsequent batches rather
than being rejected or silently truncated. **Cancel search** stops pending
resolves and automatic discovery retries until Locate or reopening an associated map.
Expired records are skipped. Metadata and IDs stay local to this phone; Google
Cloud hosting/resolution still requires internet and configured authorization.
Similar-looking floors need physical testing for incorrect matches.

Placement accepts detected horizontal and vertical planes, preserving their full
orientation and height. Curved or arbitrary sloped surfaces are not guaranteed by
ARCore's plane detection. The map axes stay gravity aligned even when the first
anchor is on a wall. Distances and arrival checks continue to use horizontal X/Z
only; mounting height does not add to walking distance.

New Cloud Anchors use a 365-day TTL, with expiry estimated locally from hosting
completion. Hosting and explicit initial/manual anchor resolution have a
90-second timeout; automatic discovery and refresh batches use the shorter
bounds described below. Native errors are surfaced in the UI and diagnostic logs. Retry with a better scan, working internet, and correct
credentials. No cloud ID is saved for a failed operation.

## Coordinates and lifecycle

Matrices use meters, column vectors, Y up, and X/Z horizontal. The first hosted
anchor supplies the map origin. Map axes retain the initial gravity-aligned AR
session orientation, rather than geographic north. Store all 16 matrix entries
to preserve anchor rotation and height.

`T_map_session = T_map_anchor * inverse(T_session_anchor)` and
`T_map_camera = T_map_session * T_session_camera`.

Camera forward is local −Z. Heading is `atan2(forwardX, -forwardZ)`, and the arrow
uses destination bearing minus camera heading. All navigation distances use
`sqrt(dx*dx + dz*dz)`, ignoring height. The mini-map shows +X right and +Z down.
Localization sampling is scheduled every 100 ms; candidate validation samples
separately. Tracking loss hides the live dot
and pauses guidance. Backgrounding invalidates the old pose/alignment and
cancels pending work; resuming automatically rediscovers the current map while
preserving a same-map destination. Fresh sessions still require actual anchor
resolution, which floor-associated maps start automatically.

## Verification

Run `dart analyze`, `dart format`, and `flutter test --no-pub`. Automated tests
cover rotated/translated alignment, height-independent distance, arrow directions,
storage, creation/renaming, failed placement, tracking loss, disposal, resolution
timeout, and stale resolution responses.

Physical acceptance remains necessary: host three anchors in a measured hallway,
verify horizontal distance while changing phone height, terminate/relaunch,
resolve each anchor in separate sessions, navigate between them, add a new anchor
after relocalizing, and verify tracking loss/recovery. Test denied camera
permission, disconnected internet, expired IDs, background/resume, and walking
while rotating the phone. Record measured position/heading error; automated tests
cannot establish real-device AR accuracy.

### Earlier hosting verification on November 14, 2026 (36-test snapshot)

- Pixel 6a connected over wireless ADB: the user confirmed successful anchor
  saving after rebuilding with the Android Cloud Anchor callback patch.
- The configured API key matched the installed APK. Key values remain only in
  ignored local configuration; no credential is needed in tracked source.
- All 36 Flutter tests pass, including native failure propagation and an upload
  completion arriving before the native acknowledgement. Analysis reports no
  errors or warnings, only Material import deprecation notices.
- Earlier debug builds succeeded using ARM64 Java 17. The user performed the
  native-patch rebuild and device run; no agent rebuild/launch was performed for
  that patch.

The user subsequently reported that the updated discovery/refresh flow works well
in hands-on use. This is qualitative functional feedback, not a measured accuracy
result. Record the full restart-and-resolve, multi-anchor navigation, extension,
and position/heading acceptance checklist separately.

### Hosting timeout diagnosis

The failing save reached **Waiting for ARCore hosting result** and timed out after
90 seconds. The published 1.1.3 plugin polled cloud tasks from the render thread
and invoked Flutter channels there; the render loop silently swallowed exceptions.
The local patch delivers terminal callbacks through Android's main looper, polls
all pending tasks rather than only anchors with pose updates, and forwards native
failure states to Dart. It also registers uploads before invoking native code to
avoid losing a fast completion callback. The user confirmed saving worked after
this patch.

Opening the name keyboard also resized the virtual-display AR surface, with
camera-buffer abandonment and an ARCore fatal texture error observed in logs.
The AR screen now keeps its size fixed while the keyboard is visible.

If saving fails again, record the displayed stage and exact ARCore error. The
stages distinguish configuration, native placement, starting hosting, and waiting
for the cloud result. Check API restrictions/network only after identifying the
failing stage; movement-coverage guidance does not guarantee cloud success.

### Local runner limitation

The Serverpod runner could not start with the installed SDK because its expected
`dart_runtime_service_vm.dart.snapshot` was missing. Serverpod MCP restart/log
inspection was unavailable in this session. This local-only AR prototype does
not require a backend round trip; backend map persistence remains future work.

### Earlier automatic discovery implementation validation

On November 14, 2026, all 19 Flutter tests passed. `dart analyze` reported no
errors or warnings (existing deprecation notices remain), formatting completed,
and the Android debug APK built successfully with the local ARM64 Java 17.
The APK has not been installed or physically validated for this change.

Automated coverage includes candidate selection across maps, expired and duplicate
IDs, rotated wall-anchor alignment, first success after an individual failure,
all failures, timeout, cancellation/retry with stale callbacks, catalog limits,
background cancellation, and map selection retaining the same AR session.
The Android plugin supports per-attempt request names and detaches pending and
unsuccessful search anchors during cleanup. Navigation now retains its active
reference as described below.

Physical acceptance is still pending for this change. Fully rebuild/reinstall the
Android app because the plugin's native code changed; hot restart is insufficient.
On Pixel 6a, verify fresh-session manual resolution first, then host floor and wall
anchors in two named maps, relaunch, discover each map from its surroundings,
navigate between anchors at different heights, and repeat cancel/retry and
background/resume. Record position/heading error and any incorrect floor match.

### Drift reduction and reference handoffs

Navigation now retains the active native anchor and recomputes alignment from its
live pose. Camera and reference/candidate poses are sampled together on Android's
render thread. Walking triggers a background refresh after **20 horizontal meters
of travel or 20 seconds** after the previous refresh attempt completes, whether
it succeeded or failed. Initial localization/hosting starts the first interval.
These are tuning defaults, not an accuracy guarantee or anchor visibility radius.

Background searches resolve three nearby, unexpired anchors on the current map,
then broaden through the remaining candidates after failures.
Each cloud batch and subsequent stability validation has a 10-second timeout;
only one refresh attempt runs at a time. Every completed attempt resets the
travel/time scheduling baseline without changing fix freshness on failure. Explicit **Refresh location** searches
up to 20 anchors on the current map. To search other saved maps, return home and open the global **Find my location** flow.

A candidate must produce at least five tracking-valid alignment samples over
0.5 seconds, agreeing within 15 cm horizontally and 3 degrees of heading. Every
stable, gravity-consistent match is accepted automatically, including large
position or heading corrections. Corrections blend over 0.5 seconds; there is no
stop-and-rescan or manual acceptance requirement. The old reference is released
after acceptance.

Failed refreshes report failure while keeping the accepted alignment and estimated
guidance. All errors, including authorization and quota failures, remain eligible
for the next 20m/20s interval. Detailed error reasons appear in diagnostic logs.
After a failed refresh, after 30 seconds without a confirmation, or beyond 24
horizontal meters of the reference, proximity is labeled estimated. Tracking loss
hides the dot and live guidance without discarding alignment, while timed retries
continue. Background/resume clears the old pose and automatically rediscovers the
current map. Initial discovery failures retry after 20 seconds; cancelling a search
stops discovery retries until Locate or reopening an associated map. Regular use refreshes even with no destination selected.

Map extension recommends a reference confirmed within 30 seconds, currently
tracking, with camera and new placement within 20 horizontal meters of it. These
are advisory warnings: placement proceeds without a forced refresh. A temporary
native anchor is created on tap and hosted after scanning. Saving uses the live
reference alignment when available, otherwise the retained map alignment; the
latter may retain drift. A session still needs initial localization to extend an
existing map, and actual AR tracking is required for placement/hosting. Refreshes
and alignment blending pause from entering placement through scanning, naming,
hosting, and saving. Entering placement cancels pending candidates, including ones
already being validated. Cancel or successful save resumes regular mode with a new
20m/20s interval, without treating the mode change as a fresh fix.
First-anchor hosting establishes a new map and reference without this extension gate.

Existing records are not rewritten or deleted. Recreate maps to avoid retaining
coordinates measured before this change. Keep distances in X/Z regardless of wall
anchor height. Test distinctive, overlapping visual areas; 20-meter refresh travel
does not imply that every anchor can resolve from 20 meters away.

Validation includes scheduling at twenty meters, repeated time-based retries,
single-attempt execution, candidate broadening/expiry, large stable corrections
and blending, tracking loss, mapping advisories, late candidate disposal, retained-anchor cleanup,
and hosting an existing draft with retry. Physical accuracy remains unverified:
rebuild/reinstall the app, create a measured hallway map, compare outbound/return
walks with repeated handoffs, and record position/heading error and correction jumps.

On November 14, 2026, all 30 Flutter tests passed for the handoff implementation;
analysis reported no errors or warnings, and the Android debug build succeeded.
No installation or physical drift measurements were performed. Serverpod MCP
restart/log tools were unavailable in this session. Native changes require a
full reinstall/relaunch, rather than Flutter hot restart alone.

### Earlier continuous refresh verification

On November 14, 2026, all 36 Flutter tests passed after separating attempt timing
from fix freshness and removing large-correction blocking. Analysis reports no
errors or warnings (existing deprecation notices remain). Coverage includes
repeated authorization/quota/network failures, distance and time interval resets,
long-running attempts, mapping cancellation during resolution and validation,
and automatic blending of large position and heading corrections. These changes
are Dart-only; restart the running app to recreate the controller. Live Serverpod
restart/log tools were unavailable, so device behavior has not been revalidated.

### User feedback after continuous refresh changes

On November 14, 2026, the user reported that the updated app works well in
hands-on use and requested that the implementation and documentation be committed.
The current intended behavior is the continuous 20m/20s refresh flow above, including
automatic retries after failure, automatic acceptance of stable corrections, and
advisory mapping warnings. Formal accuracy measurements remain outstanding.


### Latest navigation and recovery integration (November 14, 2026)

The combined Flutter suite now has **80 passing tests**; analysis reports no
errors/warnings, formatting completed, and the Android debug APK built. This
includes automatic discovery retry/cancellation, background reacquisition, camera
widget retention across expansion, estimated AR movement after cloud failures,
timed retries while camera samples are lost or blocked, and heading-follow/map
interaction. No new physical accuracy or live-device validation is claimed.

Time scheduling runs independently of successful camera sampling, including when
a sample is outstanding. Interval revisions prevent a fast failed refresh from
counting pre-attempt movement toward a second immediate refresh. Reference loss
uses the saved map catalog for automatic reacquisition. Tracking loss hides the
dot rather than freezing a last-known position; turn/ETA guidance pauses until a
valid pose returns. Failed cloud refreshes with valid AR tracking retain the
accepted alignment and update estimated movement; estimate notices do not replace
turn instructions. Detailed navigation and controls are in FLOOR_NAVIGATION.md.
