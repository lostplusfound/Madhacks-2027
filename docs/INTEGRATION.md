# Integration procedure

## Starter integration

Follow README.md to run the generated endpoint/client example. This verifies framework wiring only. Check docs/SETUP_STATUS.md for commands actually executed and local blockers.

## Future feature integration

1. Agree a revision of the proposed contracts before implementing consumers. A shared package is future work, not present scaffolding.
2. Navigation and AI owners exchange a synthetic map; backend stores/returns equivalent domain data through explicit adapters.
3. Navigation consumes a mock LocalizationService. AR later replaces that service through the same boundary; widgets must not import AR plugin internals.
4. Verify map revision, floor ID, calibration, and anchor pose agree before rendering a live position.
5. Review an actual corridor route on the physical floor, including tracking loss and recovery.

For Android emulators use the host alias 10.0.2.2 rather than localhost. For a phone use the development machine's LAN address, same network, and an appropriate local firewall rule. Supply the endpoint through the generated app's SERVER_URL configuration. A browser connection test is not evidence of Android networking or AR success.

Keep changes to shared schemas coordinated; regeneration belongs with endpoint/protocol changes. Integration owner checks a clean build and records accepted contract decisions. Never silently change pixels to meters or replace a map revision under existing anchors.
