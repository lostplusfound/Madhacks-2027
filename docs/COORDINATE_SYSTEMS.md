# Proposed coordinate conventions

**Proposal, not a frozen contract.** Confirm these conventions with AR and navigation owners and encode them in tests before integrating features.

Image coordinates (u,v) use original pixels, top-left origin, right/down positive. Building coordinates (X,Y,Z) use meters with Y up and X/Z horizontal. Each floor may have its own local building frame. AR session coordinates are meters with Y vertical; their origin and orientation do not imply map alignment.

Use column vectors and T_AB for a transform from B into A. Quaternion storage is (x,y,z,w); compose matrices right-to-left. With session S, anchor A, building B, camera C:

```
T_BC = T_BA * inverse(T_SA) * T_SC
```

Proposed heading is atan2(forwardX, -forwardZ), where the camera's local forward vector is (0,0,-1) transformed into the building frame. Heading zero faces -Z; positive angles turn toward +X. Verify plugin camera conventions before adopting this rule.

Proposed calibration uses a 2D similarity transform: [u,v] = translation + pixelsPerMeter * R(theta) * [X,Z]. Pixel Y is down; choose/verify landmark correspondence accordingly. Preserve the inverse for image-to-meter conversion. Use at least two distinct calibration points and a third validation point; reject coincident points or zero scale.

Horizontal navigation distance is sqrt(dx*dx + dz*dz), not camera 3D distance. Keep camera height Y separate from map display. No map position should be presented until anchor-to-building alignment is valid.

Future tests: identity and rotated anchors, translated sessions, transform multiplication order, inverse round trips, pixel calibration round trips, known heading directions, and invariance to camera height.
