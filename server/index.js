import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import axios from 'axios';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const FACEIT_API_KEY = process.env.FACEIT_API_KEY || '';

const faceit = axios.create({
  baseURL: 'https://open.faceit.com/data/v4',
  headers: FACEIT_API_KEY
    ? { Authorization: `Bearer ${FACEIT_API_KEY}` }
    : undefined,
  timeout: 15000,
});

function httpError(res, code, message, extra) {
  return res.status(code).json({ error: message, ...extra });
}

// --- FACEIT proxy endpoints ---

app.get('/api/faceit/players/by-nickname/:nickname', async (req, res) => {
  if (!FACEIT_API_KEY) return httpError(res, 500, 'FACEIT_API_KEY not configured');
  try {
    const nickname = req.params.nickname;
    const r = await faceit.get('/players', { params: { nickname } });
    const data = r.data || {};
    const player_id = data.player_id || data.playerId || data.id;
    if (!player_id) return httpError(res, 404, 'Player not found');
    res.json({ player_id, raw: data });
  } catch (e) {
    const status = e.response?.status || 500;
    res.status(status).json({ error: 'FACEIT players lookup failed', detail: e.message });
  }
});

app.get('/api/faceit/players/:playerId/matches', async (req, res) => {
  if (!FACEIT_API_KEY) return httpError(res, 500, 'FACEIT_API_KEY not configured');
  try {
    const { playerId } = req.params;
    const { game = 'cs2', limit = 20, offset = 0 } = req.query;
    const r = await faceit.get(`/players/${playerId}/history`, {
      params: { game, limit, offset },
    });
    const body = r.data || {};
    const items = Array.isArray(body.items) ? body.items : [];
    // Normalize a short summary for the client
    const mapped = items.map((it) => ({
      match_id: it.match_id || it.matchId || it.id,
      map: it.game || it.map || it?.voting?.map?.pick || it?.stats?.map,
      finished_at: it.finished_at || it.date || it.started_at,
    }));
    res.json(mapped);
  } catch (e) {
    const status = e.response?.status || 500;
    res.status(status).json({ error: 'FACEIT history failed', detail: e.message });
  }
});

// --- Mock analyze: returns MatchAnalysis-compatible JSON ---

function hash32(str) {
  // xfnv1a 32-bit
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

function mulberry32(seed) {
  let t = seed >>> 0;
  return function () {
    t |= 0;
    t = (t + 0x6D2B79F5) | 0;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

function randint(rnd, a, b) { return a + Math.floor(rnd() * (b - a + 1)); }

function buildMockAnalysis(matchId, mapId) {
  const seed = hash32(matchId);
  const rnd = mulberry32(seed);

  const kills = randint(rnd, 10, 35);
  const deaths = randint(rnd, 8, 28);
  const assists = randint(rnd, 0, 10);
  const adr = +(60 + rnd() * 60).toFixed(1);
  const rating = +(0.8 + rnd() * 0.8).toFixed(2);

  const player = { kills, deaths, assists, adr, rating };
  const utility = {
    flashes: randint(rnd, 5, 16),
    flashAssists: randint(rnd, 0, 5),
    smokes: randint(rnd, 4, 14),
    molotovs: randint(rnd, 2, 10),
    he: randint(rnd, 2, 10),
  };

  const totalRounds = randint(rnd, 24, 31);
  const rounds = Array.from({ length: totalRounds }, (_, i) => {
    const r = i + 1;
    const side = r <= totalRounds / 2 ? 'T' : 'CT';
    return {
      round: r,
      side,
      won: rnd() < 0.5,
      kills: randint(rnd, 0, 3),
      survived: rnd() < 0.5,
      entry: rnd() < 0.1,
    };
  });

  const types = ['flash', 'smoke', 'molotov', 'he'];
  const throwCount = randint(rnd, 12, 22);
  const thr = [];
  let ineffectiveCount = 0;
  for (let i = 0; i < throwCount; i++) {
    const t = types[randint(rnd, 0, types.length - 1)];
    const time = randint(rnd, 10, 200);
    const round = randint(rnd, 1, totalRounds);
    const dmg = t === 'he' ? randint(rnd, 0, 60) : randint(rnd, 0, 10);
    const blind = t === 'flash' ? randint(rnd, 0, 2500) : 0;
    const teamBlind = t === 'flash' ? randint(rnd, 0, 600) : 0;
    const los = t === 'smoke' ? randint(rnd, 500, 3500) : 0;
    const area = t === 'molotov' ? randint(rnd, 800, 4300) : 0;
    let score = 0.0;
    score += dmg / 100.0;
    score += blind / 3000.0;
    score += (los + area) / 7000.0;
    score -= teamBlind / 1200.0;
    score = Math.max(0, Math.min(1, score));
    const ineffective = score < 0.25 || (t === 'flash' && teamBlind > blind / 2);
    if (ineffective) ineffectiveCount++;
    thr.push({
      id: `tr_${matchId}_${i}`,
      type: t,
      timeSec: time,
      round,
      damage: dmg,
      blindMs: blind,
      teamBlindMs: teamBlind,
      losBlockMs: los,
      areaMs: area,
      score: +score.toFixed(2),
      ineffective,
      note: ineffective && t === 'flash' && teamBlind > 0 ? 'team-flash' : null,
      x: +(0.08 + rnd() * 0.84).toFixed(3),
      y: +(0.08 + rnd() * 0.84).toFixed(3),
    });
  }

  const insights = [];
  const ineffectivePct = Math.round((ineffectiveCount * 100) / throwCount);
  if (ineffectivePct >= 30) insights.push({ type: 'general', severity: 'warn', message: `Ineffective utility ~${ineffectivePct}%` });
  if (thr.some((e) => e.type === 'flash' && e.teamBlindMs > 500)) insights.push({ type: 'flash', severity: 'warn', message: 'High team-flash incidents' });
  if (thr.filter((e) => e.type === 'smoke' && e.losBlockMs < 1200).length >= 2) insights.push({ type: 'smoke', severity: 'info', message: 'Some smokes with short LOS block' });

  return {
    entryId: `srv_${matchId}`,
    map: mapId || null,
    player,
    utility,
    rounds,
    throws: thr,
    insights,
  };
}

app.post('/api/faceit/matches/:matchId/analyze', async (req, res) => {
  try {
    const { matchId } = req.params;
    // Optionally fetch details to infer map if API key is present; otherwise rely on client-provided map
    let mapId = req.body?.map || null;
    if (!mapId && FACEIT_API_KEY) {
      try {
        const r = await faceit.get(`/matches/${matchId}`);
        let rawMap = r.data?.voting?.map?.pick || r.data?.rounds?.[0]?.round_stats?.Map || r.data?.map;
        if (typeof rawMap === 'string') {
          rawMap = rawMap.toLowerCase();
          if (rawMap.startsWith('de_')) rawMap = rawMap.slice(3);
          mapId = rawMap;
        }
      } catch {
        // ignore, fallback to null
      }
    }
    const analysis = buildMockAnalysis(matchId, mapId);
    res.json(analysis);
  } catch (e) {
    const status = e.response?.status || 500;
    res.status(status).json({ error: 'Analyze failed', detail: e.message });
  }
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});

