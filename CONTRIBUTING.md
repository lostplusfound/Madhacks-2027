# Contributing

Start with README.md and your role document in docs/roles/. This repository is a fresh hackathon scaffold. Write application features during the event.

Use feature/ar-localization, feature/ai-mapping, feature/serverpod, and feature/navigation branches. Keep changes within your assigned module; nominate one integration owner to keep main buildable. Merge small working increments at hours 1, 5, 7, 12, and 18.

## Proposed contracts, not a frozen API

Every domain model and interface in docs/CONTRACTS.md is a proposal. No shared domain package or domain implementation exists yet. Discuss changes with affected teammates, update the proposal and all consumers in the same integration change, and record the decision in that document. Do not build incompatible independent schemas. Generated Serverpod transport classes are not automatically the canonical domain schema.

Run dart format on changed Dart sources, package analysis, and relevant tests before opening a PR. Never hand-edit generated protocol/client files; regenerate them. PRs should state behavior, contract decisions, validation actually executed, and remaining blockers. Never commit credentials, local password files, or signing keys.

Physical AR changes require a compatible Android phone and a recorded manual test result. Web smoke tests cannot validate AR. See docs/TESTING.md for required future feature tests.
