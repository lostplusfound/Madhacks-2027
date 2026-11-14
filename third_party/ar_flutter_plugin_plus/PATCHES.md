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

Verification: all 36 app Flutter tests pass, including native failure propagation,
fast callback delivery, retained-anchor cleanup, draft-host retry, discovery,
and handoff lifecycle tests. The Android debug build succeeded. On November 14,
2026, the user reported that the updated flow works well in hands-on use, after
earlier hosting confirmation on Pixel 6a. Measured AR accuracy and the formal
physical acceptance checklist remain outstanding.

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
