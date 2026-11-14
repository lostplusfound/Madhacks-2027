# Role 1: AR localization and calibration

An initial Android anchor-map prototype is implemented under
`madmaps_flutter/lib/features/localization/`. See [setup, behavior, and physical
acceptance steps](../AR_PROTOTYPE.md). Image calibration and shared/backend domain
integration below remain future work.

Anchor saving was confirmed by the user on a Pixel 6a on November 14, 2026,
after fixing the published plugin's Android Cloud Anchor callback threading.
The local override remains version 1.1.3 and comes from the published package,
with fresh patches; no InsideOut source was copied. Restart-and-resolve and
measured navigation acceptance are still pending. See the prototype guide for
setup, patch provenance, and the manual Save workflow.

## Mission and current state

Deliver trustworthy floor-local poses on Android. Use the third-party package ar_flutter_plugin_plus 1.1.3 and write application AR functionality during the hackathon. Read ../CONTRACTS.md and ../COORDINATE_SYSTEMS.md: both are proposals, not frozen APIs. Confirm physical phone access immediately.

## Ownership and proposed interface

Own madmaps_flutter/lib/features/localization/ and future Android AR configuration. Coordinate changes to main.dart with navigation. Propose implementing LocalizationService (start, stop, localize, poseStream) and producing IndoorPose; shared types belong in a future shared package, not copied plugin wrappers in UI.

Inputs: selected floor, published map revision, calibrated SpatialAnchor, and native tracking/camera events. Output: building-frame pose/status events. Keep plugin matrices, sessions, and anchors internal to an AR adapter; separate calibration math from platform code.

## Task checklist

1. First task: host an anchor, persist its ID locally, terminate the app, and resolve that ID in a fresh session. Record expiry and network requirements.
2. Inspect the pinned plugin's real host/resolve and camera-pose APIs. Do not invent callbacks or assume iOS interoperability.
3. Create the service adapter and explicit tracking-state mapping. Start/stop must manage resources and subscriptions.
4. Capture two distinct calibration points and validate against a third. Store full anchor pose plus floor and map revision.
5. Compute T_BC = T_BA * inverse(T_SA) * T_SC; project X/Z for map navigation and retain camera Y separately.
6. Emit valid localization only after alignment. Agree how unlocalized events omit coordinates; lost tracking must not look like a precise live pose.
7. Integrate through dependency injection with the navigation owner's mock boundary.

## Fixtures, tests, and acceptance

Create deterministic transform fixtures: identity, translated session, rotated anchor, and differing camera heights. Run Flutter analysis/tests from README; add pure math tests for composition, heading, and horizontal distance. Follow ../TESTING.md physical checklist.

Done means restart persistence passes on a named device, a known landmark aligns on the map, movement follows a measured hallway, and tracking loss/recovery is visible. Record error measurements rather than claiming perfect accuracy.

## Debugging and integration

For failed resolution check credentials, expiry, connectivity, and feature quality; failure does not identify a floor. For rotated/mirrored map positions check matrix order, quaternion order, camera forward, and image axis conventions. For distance errors check meters versus pixels and X/Z versus XYZ.

Give navigation a sample event trace and calibrated revision; give backend the anchor metadata contract. Keep credentials outside tracked sources. Stretch goals: mapper UI, multiple anchors, drift correction, and separately verified iOS support.
