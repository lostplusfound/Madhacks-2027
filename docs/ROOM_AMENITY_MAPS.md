# Rooms and amenities in destination search

Open **Profile → Upload a new floor map**. Upload a plan and detect or manually add places. Drag pins to correct their positions. Use **Save to app**, enter the building and floor names, and save after reviewing the pins.

For an existing JSON export, use **⋮ → Open saved map**, then **Save to app**. Exporting a file alone does not add it to the shared catalog.

Explore searches saved place labels, building names, and floor names alongside Morgridge Hall. Use the building filter to narrow results. Selecting a building changes the plan shown in Explore. Selecting an uploaded place opens its plan in Explore with its pin highlighted. The plan selector switches between saved floor plans, and the selected plan stays active across tab changes. Newly saved maps become the active plan. **Edit map** lets you correct pins and save the same map again. Saved-place bookmarks retain their IDs across updates.

Serverpod stores these image-and-pin maps in PostgreSQL separately from routing graphs. The catalog survives app and backend restarts; search results do not download every plan image. Local development supports reviewed map uploads. Uploaded maps provide destination browsing, not walking routes or AR localization.
