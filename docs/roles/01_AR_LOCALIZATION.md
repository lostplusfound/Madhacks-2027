# Role 1: AR localization and calibration

An initial Android anchor-map prototype is implemented under
`madmaps_flutter/lib/features/localization/`. See [setup, behavior, and physical
acceptance steps](../AR_PROTOTYPE.md). Floor-1 image calibration is integrated;
shared/backend domain integration below remains future work.

The prototype now includes automatic discovery across local maps, wall/floor
placement, live reference tracking, and continuous current-map handoffs. Regular
use and navigation refresh after 20m/20s from attempt completion, including after
failures; mapping pauses refreshes only while adding an anchor. Stable matches
are accepted and blended automatically, and mapping warnings never force a refresh.

On November 14, 2026, the user reported that the updated flow works well in
hands-on use after earlier hosting confirmation on Pixel 6a. The latest recorded
combined suite has 88 passing Flutter tests and a successful Android debug build. Formal restart-and-resolve acceptance and measured navigation accuracy
remain to be recorded. The local plugin override remains pinned at 1.1.3, sourced
from the published package; no InsideOut source was copied. See the prototype
guide for current behavior, setup, patch provenance, and physical acceptance.

Current recovery also retries without a tracked camera sample, retains estimated
AR movement after cloud failures, hides the dot on tracking loss, and automatically
rediscovers the map after background/resume. Cancel search suppresses discovery
until Locate/reopening. Compact camera expansion preserves the keyed native view;
surface replacement rebinds the existing session's camera texture. These behaviors
need physical verification, especially while compact. See [navigation integration](../FLOOR_NAVIGATION.md)
and [latest test coverage](../TESTING.md). The proposed service/interface checklist
below has not been implemented as a shared backend contract.

The Swara visitor shell retains `MapSessionScreen` as the native session owner.
Its optional `NavigationSession` bridge accepts destination/cancel requests and
publishes real guidance. Tab changes must preserve the same AR owner; Back closes
the session, while Cancel only clears the trip. Native continuity across tabs is
still a physical acceptance check. Map management is now reached from Profile or
the Map toolbar. See [UI integration notes](../SWARA_UI_INTEGRATION.md).

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
