# Android AR localization prototype

The app home is now a list of named maps. Map and anchor metadata are saved in
SharedPreferences on this phone. Cloud Anchor hosting and resolution use Google
Cloud directly; no Serverpod domain endpoints or migrations are required.

The published `ar_flutter_plugin_plus` version remains pinned at 1.1.3. A local
override under `third_party/` fixes its Android cloud-result delivery from the
render thread, reports native cloud errors, and prevents a fast-upload callback
race. See [patch provenance](../third_party/ar_flutter_plugin_plus/PATCHES.md).
This source came from the published package, not the InsideOut prototype.
After this native patch, fully stop and rebuild/run the app yourself; hot reload
or Dart hot restart cannot replace its Android code. App builds, installation,
and launches require the user's explicit request.

## Configure and run

Use an ARCore-compatible Android phone (initial test target: Pixel 6a), enable
camera permission, and keep an internet connection. In your existing Google
Cloud project enable the ARCore API and configure an Android-restricted API key
for application ID `space.serverpod.madmaps` and the signing certificate used for
the installed build. See Google's [authorization guide](https://developers.google.com/ar/develop/authorization).

Put `arcore.apiKey=YOUR_KEY` in the ignored
`madmaps_flutter/android/local.properties`, or set the `ARCORE_API_KEY` environment
variable before building. Do not commit the key. A full rebuild is required after
changing the key; Dart hot reload cannot update Android manifest configuration.
An empty key allows compilation, but Save/Localize immediately shows an API-key configuration error.

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
   surface. Choose **Add anchor**, then tap where you want to place it.
2. Scan around the point. The movement-coverage bar is advisory and does not
   represent ARCore feature-map quality, which the pinned plugin does not expose.
   Keep the surrounding surfaces in view and move sideways around the point.
   Press **Save anchor** whenever you choose, enter a name, and wait for cloud
   hosting. Save remains available even with low coverage while tracking works.
   A success message confirms persistence. Failed saves retain the draft for retry;
   **Cancel** discards it. Add more anchors in the same tracked session.
3. Select **Anchors** and tap a destination, or tap its mini-map marker. The arrow
   points directly toward it; walls and obstacles are not considered. Arrival is
   within one horizontal meter.
4. Expand the mini-map with its upper-right button; pinch to zoom and pan. The
   blue dot is your current position and its line shows camera heading. Orange
   marks the selected destination, teal marks anchors, and gray marks expired ones.
5. Close and reopen the map. At a known saved anchor, choose its menu →
   **Localize here** and scan the original surroundings. After resolution, choose
   a destination or add more anchors.
6. Menus support renaming and deleting local records. Deletion does not revoke
   hosted Cloud Anchors. Records remain after cloud expiry; expired anchors cannot
   be used to localize, but remain usable as destination coordinates after
   localization using another live anchor. If all anchors expire, create a new map.

Cloud Anchors use a one-day TTL, with expiry estimated locally from hosting
completion. Hosting/resolution have a 90-second timeout; native ARCore errors
also appear as snackbars. Retry with a better scan, working internet, and correct
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
Camera poses are sampled at most every 100 ms. Tracking loss hides the live dot
and pauses guidance. Backgrounding invalidates alignment, so resolve again after
returning; a fresh map session always requires resolution.

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

### Verified on November 14, 2026

- Pixel 6a connected over wireless ADB: the user confirmed successful anchor
  saving after rebuilding with the Android Cloud Anchor callback patch.
- The configured API key matched the installed APK. Key values remain only in
  ignored local configuration; no credential is needed in tracked source.
- All 13 Flutter tests pass, including native failure propagation and an upload
  completion arriving before the native acknowledgement. Analysis reports no
  errors or warnings, only Material import deprecation notices.
- Earlier debug builds succeeded using ARM64 Java 17. The user performed the
  native-patch rebuild and device run; no agent rebuild/launch was performed for
  that patch.

Successful hosting is now confirmed. Fresh-session resolution, navigating between
multiple anchors, adding anchors after relocalization, and measured position/
heading accuracy still need physical acceptance testing.

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
