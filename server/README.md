CS Nade Guide Server (FACEIT proxy)

Quick start
- Copy `.env.example` to `.env` and set `FACEIT_API_KEY`.
- Install deps: `npm install` (from `server/`).
- Run: `npm start`.

Endpoints
- `GET /api/faceit/players/by-nickname/:nickname` → `{ player_id, raw }`
- `GET /api/faceit/players/:playerId/matches?game=cs2&limit=20` → array of `{ match_id, map, finished_at }`
- `POST /api/faceit/matches/:matchId/analyze` body: `{ map?: "mirage" }` → MatchAnalysis JSON

Notes
- `analyze` returns a deterministic mock analysis (no demo parsing).
- If `FACEIT_API_KEY` is set, the server also tries to infer the map from match details.
- In Flutter, set the API base: `--dart-define=API_BASE_URL=http://localhost:3000`.

