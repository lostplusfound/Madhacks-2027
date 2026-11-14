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

This override is required for reproducible builds; do not patch the user's Pub cache.

Verification: 13 Flutter tests pass, including fast completion and native error
regressions. On November 14, 2026, the user confirmed successful saving on a Pixel
6a after their full rebuild/run with this patch. Fresh-session resolution remains
to be physically verified.
