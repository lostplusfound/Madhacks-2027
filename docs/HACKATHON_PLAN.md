# Proposed 24-hour team plan

Times are relative to team kickoff, not a claim about the event schedule. Adjust together. Contracts remain negotiable; resolve disagreements before dependent work lands.

| Hours | AR lead | AI maps | Backend | Navigation | Integration gate |
| --- | --- | --- | --- | --- | --- |
| 0–1 | Confirm physical phone and plugin | Choose source floor plan | Run starter server | Run starter app | Assign integration owner; agree first contract revision |
| 1–5 | Host, save ID, resolve after restart | Export manual draft; investigate vision access | Models, migration, map read endpoint | Shared models, fixture, mock, renderer and route | Exchange real outputs early |
| 5–7 | Expose localization boundary | Validate graph IDs | Return published sample | Show mock position and route | One compatible map and revision across modules |
| 7–12 | Calibrate landmarks and live pose | Correct hallway geometry | Store calibrated anchor metadata | Connect real localization | Walk one actual hallway route |
| 12–18 | Test relocalization and tracking loss | Review optional AI draft | Reject invalid submissions | Handle unreachable/offline states | Human-verified connections; no false precision |
| 18–24 | Rehearse physical setup | Freeze demo map | Stabilize local services | Polish reliable demo | Record backup video and judges' explanation |

If AR persistence is unreliable, show mock navigation explicitly labeled as simulated and explain the limitation. If Databricks access fails, use manual JSON. Prioritize a verified route over optional infrastructure. Integrate at each gate rather than waiting until the final hour.
