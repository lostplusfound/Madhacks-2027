# Proposed contracts — discussion draft

**These contracts are proposed, not implemented, approved, or set in stone.** They are a starting point for four teammates. Change names, fields, signatures, serialization, and boundaries when implementation evidence warrants it. Coordinate revisions with consumers and update this document. No domain package, fixture validator, or domain endpoints exist in this scaffold.

## Proposed domain data

Use one future canonical domain schema, with adapters for Serverpod transport types where needed. Decide JSON/nullability details together before producing data.

| Type | Proposed fields |
| --- | --- |
| IndoorMap | mapId, revision, buildingId, floorId, imageWidth, imageHeight, imageUrl, calibration, nodes, edges, rooms |
| MapNode | id, u, v, type (junction, door, destination, stairs, elevator, entrance, landmark) |
| MapEdge | id, fromNodeId, toNodeId, bidirectional, verificationStatus, accessibilityStatus |
| Room | id, label, entranceNodeId |
| SpatialAnchor | id, cloudAnchorId, buildingId, floorId, mapRevision, poseInBuilding, expiresAt, status |
| IndoorPose | buildingId, floorId, xMeters, yMeters, zMeters, headingRadians, timestamp, localizationStatus, sourceAnchorId |
| NavigationRoute | mapId, mapRevision, destinationRoomId, orderedRoutePoints, instructions, totalDistanceMeters |
| BuildingSummary / FloorSummary | stable ID and display label; floor also identifies its building |
| MapDraft | proposed IndoorMap plus review/provenance information; details to agree before implementation |

Each route point identifies its floor. Anchor pose is full translation and quaternion, not just pixels. Proposed localization states: unlocalized, tracking, limited, lost. Agree nullable pose fields or a separate status event before implementation: never represent unlocalized state as precise zero coordinates.

## Proposed service interfaces

```dart
abstract class LocalizationService {
  Stream<IndoorPose> get poseStream;
  Future<void> start();
  Future<void> stop();
  Future<void> localize();
}

abstract class MapRepository {
  Future<List<BuildingSummary>> getBuildings();
  Future<List<FloorSummary>> getFloors(String buildingId);
  Future<IndoorMap> getPublishedMap(String floorId);
  Future<List<SpatialAnchor>> getAnchors(String floorId);
  Future<String> submitMapDraft(MapDraft draft);
  Future<String> submitAnchor(SpatialAnchor anchor);
}
```

These snippets illustrate intent; they are not compilable APIs in the repository. A future routing service accepts map, localized start, destination room ID, and returns a route or an explicit unreachable result. Agree error types and async behavior when implementing it.

## Proposed invariants to confirm

IDs are unique and references resolve; calibration is invertible; distances use meters; map and anchor revisions match. Accessibility defaults to unknown, not accessible. Draft and verified graph connections remain distinguishable. Publication requires review, and routing must exclude unsafe/unverified connections under the agreed publication policy.

## Decisions still open

Integration owner and teammates should agree schema ownership, enum wire values, calibration representation, heading extraction, submission authorization, publication workflow, and missing-data/error representation before their first dependent implementation. This is deliberate future feature design, not a blocker for the starter projects.
