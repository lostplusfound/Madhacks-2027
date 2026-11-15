# Local fixes to published ar_flutter_plugin_plus 1.1.3

Source: pub.dev's published 1.1.3 package, copied from the Pub cache. The version
pin and upstream license are retained. `UPSTREAM_SHA256.json` records the original
file hashes. Examples are omitted. No InsideOut project source was copied.

Fresh changes for MadMaps:

- Poll pending Cloud Anchor tasks on each frame, independently of pose updates.
- Dispatch terminal cloud callbacks to Android's main looper before invoking
  Flutter platform channels. The upstream render loop swallows callback exceptions.
- Forward host/resolve error states to Dart so operations fail immediately.
- Register pending uploads before the native call, avoiding a fast-callback race.
- Return/await cloud configuration and resolution channel responses.
- Accept a per-attempt `requestId` for concurrent downloads and preserve it as the
  native anchor name for successful callbacks and resolve errors. Failed ARCore
  anchors may have no cloud ID, so errors use the request name instead.
- Add `cancelResolve(requestId)` to detach pending/resolved search anchors and
  suppress callbacks already queued on Android's main looper. Convert synchronous
  resolve exceptions to platform errors so one failed start does not crash the app.

MadMaps now requests horizontal-and-vertical plane detection through the existing
plugin API. No version upgrade or generated-code changes are required.

This override is required for reproducible builds; do not patch the user's Pub cache.

Latest recorded verification on November 14, 2026: **80 app Flutter tests pass**,
including failure propagation, callback races, cleanup, lifecycle recovery,
pending-search retention across camera expansion, and local navigation/UI tests.
Analysis reported no errors/warnings and the Android debug APK built successfully.
Earlier hosting was confirmed on Pixel 6a, and the user gave positive hands-on
feedback. These are not measurements of position/heading accuracy or proof that
the latest compact-camera localization works physically. See
[the device checklist](../../docs/TESTING.md#physical-android-checklist).

Drift-reduction additions:

- `getLocalizationFrame(names)` samples camera pose, anchor poses, tracking states,
  and frame timestamp together on the Android render thread. Dart uses this for
  live reference alignment, candidate validation, and map extension coordinates.
- App-side resolution may retain the winning native anchor; explicit release still
  uses `cancelResolve`. Unsuccessful attempts and superseded references are detached.
- App-side placement creates a local draft immediately and hosts that same native
  anchor rather than recreating it from the original hit-test matrix after scanning.

- `cancelCloudTask(name)` stops a failed/timed-out host operation without removing
  its original local draft, allowing retry without a stale completion race. Host
  error anchors are detached, and pending Dart uploads are cleared on completion.


Compact-camera additions:

- The app replaces full-screen cropping with a real compact/expanded viewport
  while preserving the keyed Android view and ARCore session.
- Native surface replacement retains the existing Session, reinitializes render
  resources, rebinds its camera texture, and updates display geometry. Rendering
  waits for a valid surface; resume/frame errors are logged rather than silently
  obscuring the compact-view failure.
- Debug diagnostics include viewport size, surface generation, session identity,
  throttled frame timestamps/tracking, and resolve completion.
- Camera permission prompts use a scrollable layout so they fit in the compact
  viewport without overflowing.

These are source changes to the vendored override, not generated code or edits to
the Pub cache. The published version remains pinned at 1.1.3. A full Android
rebuild/relaunch is required; Dart hot reload cannot apply native changes.
