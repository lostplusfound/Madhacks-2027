import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import 'package:madmaps/features/localization/map_data.dart';
import 'package:madmaps/features/localization/prototype_screen.dart';
import 'package:madmaps/features/navigation/floor_data.dart';
import 'package:madmaps/features/navigation/building_routing.dart';
import 'package:madmaps/features/shell/navigation_session.dart';
import 'localization_controller_test.dart' show WalkingAr, saved;

void main() {
  final connector = api.FloorConnector(
    connectorId: 'up',
    buildingId: 'building',
    label: 'University stairs',
    fromGraphId: 'basement',
    fromFloor: 0,
    fromNodeId: 'lower',
    toGraphId: 'first',
    toFloor: 1,
    toNodeId: 'upper',
    type: api.EdgeType.stairs,
    seconds: 18,
    bidirectional: true,
    active: true,
  );
  Future<dynamic> mount(
    WidgetTester tester,
    WalkingAr ar,
    NavigationSession session, {
    bool upstairsPoints = true,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final lower = AnchorMap('lower', 'Basement', [saved('lower', 0)])
      ..floor.floorNumber = 0;
    final upper = AnchorMap('upper', 'Floor 1', [
      if (upstairsPoints) saved('b', 10),
    ])..floor.floorNumber = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MapSessionScreen(
          map: lower,
          maps: [lower, upper],
          adapter: ar,
          session: session,
          floors: {0: FloorGraph({}, [], []), 1: FloorGraph({}, [], [])},
          save: () async {},
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(MapSessionScreen));
    state.ready = true;
    return state;
  }

  NavigationSession trip() => NavigationSession()
    ..currentFloor = 0
    ..choose(
      FloorLocation('destination', 'Floor 1 destination', '', null, floor: 1),
    );

  testWidgets(
    'handoff searches upstairs only and adopts a stable upstairs fix',
    (tester) async {
      final ar = WalkingAr();
      final session = trip();
      final dynamic state = await mount(tester, ar, session);
      await state.beginTransition(connector);
      expect(state.camera, isNull);
      expect(session.currentFloor, 0);
      expect((state.catalog as List<AnchorMap>).single.floor.floorNumber, 1);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ar.batches.first, ['b']);
      expect(session.currentFloor, 1);
      expect(state.transition, isNull);
      expect(session.destination?.id, 'destination');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'missing upstairs points keeps location unconfirmed with a specific message',
    (tester) async {
      final session = trip();
      final dynamic state = await mount(
        tester,
        WalkingAr(),
        session,
        upstairsPoints: false,
      );
      await state.beginTransition(connector);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        state.discoveryMessage,
        contains('No usable saved anchors on Floor 1'),
      );
      expect(session.currentFloor, 0);
      expect(state.camera, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('cancellation rejects a late upstairs resolve', (tester) async {
    final ar = WalkingAr()..pending = Completer<ARAnchor>();
    final session = trip();
    final dynamic state = await mount(tester, ar, session);
    await state.beginTransition(connector);
    await tester.pump(const Duration(milliseconds: 100));
    session.cancel();
    ar.pending!.complete(
      ARPlaneAnchor(
        name: 'late',
        transformation: ar.candidatePose(),
        cloudanchorid: 'b',
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(session.currentFloor, 0);
    expect(state.transition, isNull);
    expect(ar.released, contains('late'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed upstairs discovery retries after two seconds', (
    tester,
  ) async {
    final ar = WalkingAr()..error = TimeoutException('not found');
    final session = trip();
    final dynamic state = await mount(tester, ar, session);
    await state.beginTransition(connector);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ar.batches.length, 1);
    await tester.pump(const Duration(milliseconds: 1899));
    expect(ar.batches.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(ar.batches.length, 2);
    expect(
      ar.batches.every((batch) => batch.length == 1 && batch.single == 'b'),
      isTrue,
    );
    expect(session.currentFloor, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'recovery control starts discovery without claiming the next floor',
    (tester) async {
      final session = trip();
      final dynamic state = await mount(
        tester,
        WalkingAr(),
        session,
        upstairsPoints: false,
      );
      state.buildingRoute = BuildingRoute([
        BuildingLeg(0, const [Offset.zero], 'lower', 0, connector),
      ], 18);
      state.refresh();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('scan-next-floor')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.transition.connectorId, 'up');
      expect(session.currentFloor, 0);
      expect(state.camera, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
