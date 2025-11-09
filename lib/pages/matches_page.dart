import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../utils/color_compat.dart'; // ignore: unused_import
import '../l10n/app_localizations.dart';
import '../utils/share_code.dart';
import '../data/analysis_repository.dart';
import '../models/match_analysis.dart';
import '../data/nades_repository.dart';
import '../models/cs_map.dart';

import '../data/matches_repository.dart';
import '../models/match_entry.dart';
import '../data/faceit_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final _repo = const MatchesRepository();
  late Future<List<MatchEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.getAll());
    await _future;
  }

  Future<void> _confirmAndDelete(MatchEntry m) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteMatchQuestion),
        content: Text(l.irreversible),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) {
      await _repo.remove(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.matchDeleted)));
        _refresh();
      }
    }
  }

  void _openImport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ImportSheet(onSubmit: (code, mapId) async {
        // Используем контекст листа для закрытия/диалога, а контекст State — для навигации и snackbar
        final navSheet = Navigator.of(sheetContext);
        try {
          final decoded = decodeShareCode(code);
          final entry = MatchEntry(
            id: Uuid().v4(),
            shareCode: code.trim(),
            createdAt: DateTime.now(),
            status: MatchStatus.ready,
            map: mapId,
            matchId: decoded.matchId,
            outcomeId: decoded.outcomeId,
            token: decoded.token,
          );
          await _repo.add(entry);
          if (!sheetContext.mounted) return;
          navSheet.pop(); // закрыть bottom sheet
          // Показать индикатор прогресса анализа
          if (!sheetContext.mounted) return;
          showDialog(
            context: sheetContext,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              content: Row(
                children: const [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Идёт анализ…')),
                ],
              ),
            ),
          );
          // Выполнить локальный мок-анализ
          await const AnalysisRepository().generateAndStore(entry);
          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext); // закрыть диалог прогресса
          // Обновить список и перейти на экран деталей
          if (!mounted) return;
          await _refresh();
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _MatchDetailPage(entry: entry)),
          );
        } catch (e) {
          if (!mounted) return;
          final l = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.invalidShareCode(e))),
          );
        }
      }),
    );
  }

  // Убраны экспорт/импорт JSON из интерфейса по запросу

  void _openFaceit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FaceitSheet(onDone: () async {
        if (!mounted) return;
        await _refresh();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.matchesTitle),
        actions: [
          IconButton(
            tooltip: 'FACEIT',
            icon: const Icon(Icons.cloud_download),
            onPressed: _openFaceit,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openImport,
        icon: const Icon(Icons.add),
        label: Text(l.importAction),
      ),
      body: FutureBuilder<List<MatchEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = List<MatchEntry>.from(snap.data ?? const <MatchEntry>[]);
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.noMaps),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _openImport,
                    icon: const Icon(Icons.add),
                    label: Text(l.importAction),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = items[i];
                return Dismissible(
                  key: ValueKey(m.id),
                  background: Container(color: Colors.redAccent),
                  confirmDismiss: (_) async {
                    await _repo.remove(m.id);
                    // Оптимистично обновим список без выхода со страницы
                    setState(() {
                      _future = _future.then((list) =>
                          list.where((e) => e.id != m.id).toList());
                    });
                    return true;
                  },
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Theme.of(context).cardTheme.color,
                    title: Text(m.map ?? 'Матч'),
                    subtitle: () {
                      final lc = Localizations.localeOf(context).languageCode;
                      final fmt = DateFormat.yMMMd(lc).add_Hm();
                      final dt = fmt.format(m.createdAt.toLocal());
                      final ids = (m.matchId != null && m.outcomeId != null && m.token != null)
                          ? 'match=${m.matchId} • outcome=${m.outcomeId} • token=${m.token}'
                          : (m.note ?? '');
                      return Text('${m.status.name} • $dt\n$ids');
                    }(),
                    isThreeLine: true,
                    leading: const Icon(Icons.sports_esports),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmAndDelete(m),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _MatchDetailPage(entry: m)),
                      );
                      if (!mounted) return;
                      _refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ImportSheet extends StatefulWidget {
  final Future<void> Function(String code, String? mapId) onSubmit;
  const _ImportSheet({required this.onSubmit});

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

// FACEIT импорт: поиск по нику, список матчей и анализ выбранного
class _FaceitSheet extends StatefulWidget {
  final VoidCallback? onDone;
  const _FaceitSheet({this.onDone});

  @override
  State<_FaceitSheet> createState() => _FaceitSheetState();
}

class _FaceitSheetState extends State<_FaceitSheet> {
  final _nick = TextEditingController();
  final _svc = FaceitService();
  final _uuid = Uuid();
  List<FaceitMatchSummary> _matches = const <FaceitMatchSummary>[];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  String? _mapFromFaceitId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var m = raw.toLowerCase();
    if (m.startsWith('de_')) m = m.substring(3);
    // Поддерживаемые ассеты в проекте
    const known = {
      'mirage', 'inferno', 'dust2', 'anubis', 'ancient', 'nuke', 'overpass', 'train', 'vertigo'
    };
    return known.contains(m) ? m : null;
  }

  Future<void> _search() async {
    final nick = _nick.text.trim();
    if (nick.isEmpty) {
      setState(() => _error = 'Введите ник FACEIT');
      return;
    }
    setState(() { _loading = true; _error = null; _matches = const []; });
    try {
      final pid = await _svc.getPlayerIdByNickname(nick);
      final items = await _svc.getRecentMatches(pid, limit: 20);
      if (!mounted) return;
      setState(() => _matches = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _analyze(FaceitMatchSummary m) async {
    final l = AppLocalizations.of(context);
    final mapId = _mapFromFaceitId(m.map);
    final entry = MatchEntry(
      id: _uuid.v4(),
      shareCode: 'faceit:${m.id}',
      createdAt: DateTime.now(),
      status: MatchStatus.ready,
      map: mapId,
      note: 'faceit',
      matchId: null,
      outcomeId: null,
      token: null,
    );
    await const MatchesRepository().add(entry);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(children: [
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Expanded(child: Text('Идёт анализ…')),
        ]),
      ),
    );
    try {
      final a = await _svc.analyzeMatch(m.id, mapId: mapId);
      final fixed = MatchAnalysis(
        entryId: entry.id,
        map: a.map ?? mapId,
        player: a.player,
        utility: a.utility,
        rounds: a.rounds,
        throws: a.throws,
        insights: a.insights,
      );
      await const AnalysisRepository().write(fixed);
      if (!mounted) return;
      Navigator.pop(context); // close progress
      Navigator.pop(context); // close sheet
      if (!mounted) return;
      widget.onDone?.call();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _MatchDetailPage(entry: entry)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.invalidShareCode(msg))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('FACEIT импорт')),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _nick,
                decoration: InputDecoration(
                  labelText: 'Ник на FACEIT',
                  hintText: 'e.g. s1mple',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.person_search),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Найти матчи'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_matches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Нет данных. Укажите ник и выполните поиск.'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, i) {
                    final m = _matches[i];
                    final map = _mapFromFaceitId(m.map) ?? (m.map ?? '—');
                    final ts = m.finishedAt?.toLocal();
                    final when = ts == null ? '' : DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_Hm().format(ts);
                    return ListTile(
                      leading: const Icon(Icons.cloud_download),
                      title: Text('Матч ${m.id.substring(0, m.id.length.clamp(0, 8))}…'),
                      subtitle: Text('Карта: $map${when.isNotEmpty ? ' • $when' : ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _analyze(m),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _matches.length,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ImportSheetState extends State<_ImportSheet> {
  final _ctrl = TextEditingController();
  String? _error;
  Future<List<CsMap>>? _mapsFuture;
  String? _selectedMapId;

  @override
  void initState() {
    super.initState();
    _mapsFuture = const NadesRepository().getMaps();
  }

  void _submit() {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Введите share code из CS2');
      return;
    }
    // Локальная валидация, чтобы показать ошибку сразу под полем
    try {
      decodeShareCode(code);
    } catch (e) {
      setState(() => _error = 'Некорректный share code');
      return;
    }
    widget.onSubmit(code, _selectedMapId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Expanded(child: Text(l.matchAnalysisTitle)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: l.shareCode,
                hintText: 'CS2 share code (CSGO-....)',
                errorText: _error,
                prefixIcon: const Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<CsMap>>(
              future: _mapsFuture,
              builder: (context, snap) {
                final maps = snap.data ?? const <CsMap>[];
                return DropdownButtonFormField<String?>(
                  value: _selectedMapId,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Без карты')),
                    ...maps.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedMapId = v),
                  decoration: const InputDecoration(labelText: 'Карта (для тепловой карты)'),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.download),
                    label: Text(l.importAction),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _MatchDetailPage extends StatefulWidget {
  final MatchEntry entry;
  const _MatchDetailPage({required this.entry});

  @override
  State<_MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<_MatchDetailPage> {
  final _repo = const AnalysisRepository();
  late Future<MatchAnalysis?> _future;
  String? _mapId;

  @override
  void initState() {
    super.initState();
    _mapId = widget.entry.map;
    _future = _repo.read(widget.entry.id);
  }

  Future<void> _analyze() async {
    setState(() {
      _future = _repo.generateAndStore(widget.entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.matchAnalysisTitle),
        actions: [
          IconButton(
            tooltip: 'Выбрать карту',
            icon: const Icon(Icons.map_outlined),
            onPressed: _pickMap,
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.deleteMatchQuestion),
                  content: Text(l.irreversible),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                  ],
                ),
              );
              if (ok == true) {
                await const MatchesRepository().remove(widget.entry.id);
                if (!mounted) return;
                Navigator.pop(this.context);
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(l.matchDeleted)));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.shareCode}:', style: Theme.of(context).textTheme.titleSmall),
            SelectableText(widget.entry.shareCode),
            const SizedBox(height: 12),
            Text('${l.status}: ${widget.entry.status.name}'),
            const SizedBox(height: 8),
            Text('Карта: ${_mapId ?? '—'}'),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<MatchAnalysis?>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data;
                  if (data == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No analysis yet'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _analyze,
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Analyze (mock)'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _AnalysisView(analysis: data);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<MatchAnalysis?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
          if (snap.data != null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _analyze,
            icon: const Icon(Icons.analytics),
            label: const Text('Analyze'),
          );
        },
      ),
    );
  }

  Future<void> _pickMap() async {
    final maps = await const NadesRepository().getMaps();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Выберите карту')),
            for (final m in maps)
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(m.name),
                subtitle: Text(m.id),
                onTap: () => Navigator.pop(ctx, m.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    // Update entry
    final updatedEntry = widget.entry.copyWith(map: selected);
    await const MatchesRepository().update(updatedEntry);
    // If there is existing analysis, update its map and write back
    final analysis = await _repo.read(widget.entry.id);
    if (analysis != null) {
      final updated = MatchAnalysis(
        entryId: analysis.entryId,
        map: selected,
        player: analysis.player,
        utility: analysis.utility,
        rounds: analysis.rounds,
        throws: analysis.throws,
        insights: analysis.insights,
      );
      await _repo.write(updated);
    }
    if (!mounted) return;
    setState(() {
      _mapId = selected;
      // refresh analysis future to reflect map change on UI that reads file
      _future = _repo.read(updatedEntry.id);
    });
  }
}

class _AnalysisView extends StatefulWidget {
  final MatchAnalysis analysis;
  const _AnalysisView({required this.analysis});

  @override
  State<_AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<_AnalysisView> {
  String? _type;
  int? _round;
  bool _onlyIneff = false;
  int? _sortIndex;
  bool _asc = false;
  bool _showCharts = false;

  List<Insight> _autoInsights(MatchAnalysis a, AppLocalizations l) {
    final t = a.throws;
    if (t.isEmpty) return const <Insight>[];

    final insights = <Insight>[];

    // Team-flash ratio
    final totalBlind = t.fold<int>(0, (s, e) => s + e.blindMs);
    final totalTeamBlind = t.fold<int>(0, (s, e) => s + e.teamBlindMs);
    final blindDen = totalBlind + totalTeamBlind;
    if (blindDen > 0) {
      final ratio = totalTeamBlind / blindDen;
      if (ratio >= 0.5) {
        insights.add(Insight(type: 'flash', severity: 'error', message: l.insightsHighTeamFlashError(50)));
      } else if (ratio >= 0.3) {
        insights.add(Insight(type: 'flash', severity: 'warn', message: l.insightsHighTeamFlashWarn(30)));
      }
    }

    // Smokes: LOS effectiveness
    final smokes = t.where((e) => e.type == 'smoke').toList();
    if (smokes.length >= 2) {
      final avgLos = smokes.fold<int>(0, (s, e) => s + e.losBlockMs) / smokes.length;
      if (avgLos < 800) {
        insights.add(Insight(type: 'smoke', severity: 'warn', message: l.insightsSmokesLowLOSWarn(0.8)));
      } else if (avgLos < 1200) {
        insights.add(Insight(type: 'smoke', severity: 'info', message: l.insightsSmokesShortLOSInfo(1.2)));
      }
    }

    // Molotovs: area/damage
    final molotovs = t.where((e) => e.type == 'molotov').toList();
    if (molotovs.isNotEmpty) {
      final areaAvg = molotovs.fold<int>(0, (s, e) => s + e.areaMs) / molotovs.length;
      final dmgSum = molotovs.fold<int>(0, (s, e) => s + e.damage);
      if (dmgSum == 0 || areaAvg < 1000) {
        insights.add(Insight(type: 'molotov', severity: 'warn', message: l.insightsMolotovLowImpactWarn));
      }
    }

    // HE damage
    final he = t.where((e) => e.type == 'he').toList();
    if (he.isNotEmpty) {
      final heAvg = he.fold<int>(0, (s, e) => s + e.damage) / he.length;
      if (heAvg < 10) {
        insights.add(Insight(type: 'he', severity: 'info', message: l.insightsHeLowAvgInfo(10)));
      }
    }

    // Ineffective per type
    for (final type in ['flash', 'smoke', 'molotov', 'he']) {
      final all = t.where((e) => e.type == type).toList();
      if (all.length >= 3) {
        final bad = all.where((e) => e.ineffective).length;
        final pct = bad / all.length;
        if (pct >= 0.5) {
          insights.add(Insight(type: type, severity: 'warn', message: l.insightsIneffectiveTypeWarn(type.toUpperCase(), 50)));
        }
      }
    }

    // Critical rounds by team-flash per round
    final Map<int, int> teamBlindByRound = {};
    for (final e in t) {
      if (e.round <= 0) continue;
      teamBlindByRound[e.round] = (teamBlindByRound[e.round] ?? 0) + e.teamBlindMs;
    }
    final criticalRounds = teamBlindByRound.entries.where((e) => e.value >= 800).map((e) => e.key).toList();
    if (criticalRounds.length >= 2) {
      insights.add(Insight(type: 'rounds', severity: 'warn', message: l.insightsCriticalRoundsWarn(criticalRounds.take(5).join(', '))));
    }

    // Deduplicate by message (avoid duplicates with backend/mock)
    final seen = <String>{};
    final unique = <Insight>[];
    for (final i in insights) {
      if (seen.add(i.message)) unique.add(i);
    }
    return unique;
  }

  List<ThrowRecord> _filteredSorted() {
    var list = widget.analysis.throws;
    if (_type != null) list = list.where((e) => e.type == _type).toList();
    if (_round != null) list = list.where((e) => e.round == _round).toList();
    if (_onlyIneff) list = list.where((e) => e.ineffective).toList();
    int idx = _sortIndex ?? 9;
    int Function(ThrowRecord a, ThrowRecord b) cmp;
    switch (idx) {
      case 0:
        cmp = (a, b) => a.type.compareTo(b.type); break;
      case 1:
        cmp = (a, b) => a.round.compareTo(b.round); break;
      case 2:
        cmp = (a, b) => a.timeSec.compareTo(b.timeSec); break;
      case 3:
        cmp = (a, b) => a.damage.compareTo(b.damage); break;
      case 4:
        cmp = (a, b) => a.blindMs.compareTo(b.blindMs); break;
      case 5:
        cmp = (a, b) => a.teamBlindMs.compareTo(b.teamBlindMs); break;
      case 6:
        cmp = (a, b) => a.losBlockMs.compareTo(b.losBlockMs); break;
      case 7:
        cmp = (a, b) => a.areaMs.compareTo(b.areaMs); break;
      case 8:
        cmp = (a, b) => a.score.compareTo(b.score); break;
      default:
        cmp = (a, b) => a.ineffective == b.ineffective ? a.score.compareTo(b.score) : (a.ineffective ? -1 : 1);
    }
    list = list.toList()..sort(cmp);
    if (!_asc) list = list.reversed.toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = widget.analysis;
    final p = a.player;
    final u = a.utility;
    final types = <String?>[null, 'flash', 'smoke', 'molotov', 'he'];
    final roundSet = {for (final t in a.throws) t.round}..remove(0);
    final rounds = <int?>[null, ...roundSet.toList()..sort()];
    final ineffPct = a.throws.isEmpty ? 0 : ((a.throws.where((e) => e.ineffective).length * 100) / a.throws.length).round();

    final auto = _autoInsights(a, l);
    final allInsights = () {
      if (a.insights.isEmpty && auto.isEmpty) return const <Insight>[];
      final seen = <String>{};
      final list = <Insight>[];
      for (final i in [...a.insights, ...auto]) {
        if (seen.add(i.message)) list.add(i);
      }
      return list;
    }();

    return ListView(
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge(text: l.badgeIneffective(ineffPct), color: ineffPct >= 30 ? Colors.orangeAccent : Colors.tealAccent),
          for (final i in allInsights)
            _Badge(text: i.message, color: i.severity == 'error' ? Colors.redAccent : i.severity == 'warn' ? Colors.orangeAccent : Colors.blueGrey),
        ]),
        const SizedBox(height: 12),

        if (allInsights.isNotEmpty) ...[
          Text(l.analysisInsights, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...allInsights.map((i) => ListTile(
                dense: true,
                leading: Icon(i.severity == 'error' ? Icons.error_outline : i.severity == 'warn' ? Icons.warning_amber : Icons.info_outline,
                    color: i.severity == 'error' ? Colors.redAccent : i.severity == 'warn' ? Colors.orangeAccent : Colors.blueGrey),
                title: Text(i.message),
                subtitle: Text(i.type),
              )),
          const SizedBox(height: 16),
        ],

        Text(l.analysisSummary, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _StatTile(label: 'K', value: p.kills.toString()),
          _StatTile(label: 'D', value: p.deaths.toString()),
          _StatTile(label: 'A', value: p.assists.toString()),
          _StatTile(label: 'ADR', value: p.adr.toStringAsFixed(1)),
          _StatTile(label: 'Rating', value: p.rating.toStringAsFixed(2)),
        ]),
        const SizedBox(height: 16),

        if (a.throws.isNotEmpty) ...[
          Text(l.analysisThrows, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            DropdownButton<String?>(
              value: _type,
              hint: Text(l.filterType),
              items: types.map((v) => DropdownMenuItem<String?>(value: v, child: Text(v ?? l.filterAll))).toList(),
              onChanged: (v) => setState(() => _type = v),
            ),
            DropdownButton<int?>(
              value: _round,
              hint: Text(l.filterRound),
              items: rounds.map((v) => DropdownMenuItem<int?>(value: v, child: Text(v?.toString() ?? l.filterAll))).toList(),
              onChanged: (v) => setState(() => _round = v),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: _onlyIneff, onChanged: (v) => setState(() => _onlyIneff = v ?? false)),
              Text(l.filterOnlyIneffective),
            ]),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            ChoiceChip(
              label: Text(l.chartsTable),
              selected: !_showCharts,
              onSelected: (v) => setState(() => _showCharts = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l.chartsGraphs),
              selected: _showCharts,
              onSelected: (v) => setState(() => _showCharts = true),
            ),
          ]),
          const SizedBox(height: 8),
          if (_showCharts) ...[
            _ThrowsCharts(analysis: a),
          ] else ...[
            _ThrowsTable(
              throws: _filteredSorted(),
              sortColumnIndex: _sortIndex,
              sortAscending: _asc,
              onSort: (i, asc) => setState(() { _sortIndex = i; _asc = asc; }),
            ),
          ],
          const SizedBox(height: 16),
        ],

        Text(l.analysisUtility, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _StatTile(label: 'Flashes', value: u.flashes.toString()),
          _StatTile(label: 'Flash assists', value: u.flashAssists.toString()),
          _StatTile(label: 'Smokes', value: u.smokes.toString()),
          _StatTile(label: 'Molotovs', value: u.molotovs.toString()),
          _StatTile(label: 'HE', value: u.he.toString()),
        ]),
        const SizedBox(height: 16),

        Text(l.analysisRounds, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...a.rounds.map((r) => ListTile(
              dense: true,
              leading: Icon(r.won ? Icons.check_circle : Icons.cancel, color: r.won ? Colors.teal : Colors.redAccent),
              title: Text('Round ${r.round} • ${r.side}'),
              subtitle: Text('kills=${r.kills}, survived=${r.survived}, entry=${r.entry}'),
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ThrowsTable extends StatelessWidget {
  final List<ThrowRecord> throws;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  const _ThrowsTable({required this.throws, this.sortColumnIndex, this.sortAscending = false, this.onSort});

  Color _scoreColor(double s) {
    if (s >= 0.6) return Colors.tealAccent;
    if (s >= 0.35) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 36,
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        columns: [
          DataColumn(label: const Text('Type'), onSort: onSort),
          DataColumn(label: const Text('Rnd'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('t(s)'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Dmg'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Blind'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Team'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('LOS'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Area'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Score'), numeric: true, onSort: onSort),
          DataColumn(label: const Text('Ineff.'), onSort: onSort),
        ],
        rows: throws.map((e) => DataRow(cells: [
              DataCell(Text(e.type)),
              DataCell(Text(e.round.toString())),
              DataCell(Text(e.timeSec.toString())),
              DataCell(Text(e.damage.toString())),
              DataCell(Text(e.blindMs.toString())),
              DataCell(Text(e.teamBlindMs.toString())),
              DataCell(Text(e.losBlockMs.toString())),
              DataCell(Text(e.areaMs.toString())),
              DataCell(Text(e.score.toStringAsFixed(2), style: TextStyle(color: _scoreColor(e.score)))),
              DataCell(Tooltip(message: e.ineffective ? (e.note ?? 'Low score') : 'OK', child: Icon(e.ineffective ? Icons.close : Icons.check, color: e.ineffective ? Colors.redAccent : Colors.teal))),
            ])).toList(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _ThrowsCharts extends StatelessWidget {
  final MatchAnalysis analysis;
  const _ThrowsCharts({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final t = analysis.throws;
    if (t.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(child: Text(l.noResults));
    }

    // Группировка по раундам
    final Map<int, List<ThrowRecord>> byRound = {};
    for (final e in t) {
      if (e.round <= 0) continue;
      (byRound[e.round] ??= []).add(e);
    }
    final keys = byRound.keys.toList()..sort();
    final damageSeries = keys
        .map((r) => byRound[r]!.fold<double>(0, (s, e) => s + (e.damage.toDouble())))
        .toList();
    final blindSeries = keys
        .map((r) => byRound[r]!.fold<double>(0, (s, e) => s + (e.blindMs.toDouble())))
        .toList();
    final impactSeries = keys.map((r) {
      final list = byRound[r]!;
      double dmg = 0, blind = 0, los = 0, area = 0, score = 0;
      for (final e in list) {
        dmg += e.damage.toDouble();
        blind += e.blindMs.toDouble();
        los += e.losBlockMs.toDouble();
        area += e.areaMs.toDouble();
        score += e.score;
      }
      // Простая комбинированная метрика (подобрана эвристически)
      return dmg + blind * 0.02 + los * 0.01 + area * 0.005 + score * 10.0;
    }).toList();

    // Столбики по типу гранат
    final Map<String, int> byType = {
      'flash': 0,
      'smoke': 0,
      'molotov': 0,
      'he': 0,
    };
    for (final e in t) {
      if (byType.containsKey(e.type)) byType[e.type] = byType[e.type]! + 1;
    }
    final labels = byType.keys.toList();
    final values = labels.map((k) => byType[k]!.toDouble()).toList();

    // KPI
    final totalBlind = t.fold<int>(0, (s, e) => s + e.blindMs);
    final totalTeamBlind = t.fold<int>(0, (s, e) => s + e.teamBlindMs);
    final blindRatio = totalBlind + totalTeamBlind == 0
        ? 0.0
        : totalTeamBlind / (totalBlind + totalTeamBlind);

    Color ratioColor;
    if (blindRatio >= 0.5) {
      ratioColor = Colors.redAccent;
    } else if (blindRatio >= 0.3) {
      ratioColor = Colors.orangeAccent;
    } else {
      ratioColor = Colors.tealAccent;
    }

    final totalSmokeLos = t.where((e) => e.type == 'smoke').fold<int>(0, (s, e) => s + e.losBlockMs);
    final totalHeDmg = t.where((e) => e.type == 'he').fold<int>(0, (s, e) => s + e.damage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge(text: AppLocalizations.of(context).kpiTeamFlashRatio((blindRatio * 100).round()), color: ratioColor),
          _Badge(text: AppLocalizations.of(context).kpiSmokeLOS((totalSmokeLos / 1000).toStringAsFixed(1)), color: Colors.blueGrey),
          _Badge(text: AppLocalizations.of(context).kpiHeDmg(totalHeDmg), color: Colors.amber),
        ]),
        const SizedBox(height: 12),

        // Sparklines
        _ChartCard(title: AppLocalizations.of(context).chartDamageByRound, child: _Sparkline(values: damageSeries, color: Colors.redAccent)),
        const SizedBox(height: 8),
        _ChartCard(title: AppLocalizations.of(context).chartBlindByRound, child: _Sparkline(values: blindSeries, color: Colors.amber)),
        const SizedBox(height: 8),
        _ChartCard(title: AppLocalizations.of(context).chartImpactByRound, child: _Sparkline(values: impactSeries, color: Colors.tealAccent)),
        const SizedBox(height: 12),

        // Bars by type
        _ChartCard(title: AppLocalizations.of(context).chartThrowsByType, height: 96, child: _SimpleBarChart(labels: labels, values: values)),
        const SizedBox(height: 12),

        // Heatmap
        _ChartCard(
          title: AppLocalizations.of(context).chartHeatmap,
          height: 220,
          child: _ThrowsHeatmap(analysis: analysis),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  const _ChartCard({required this.title, required this.child, this.height = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparklinePainter(values: values, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final dx = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = (values[i] - minV) / range;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  const _SimpleBarChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || values.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxV = values.reduce((a, b) => a > b ? a : b);
        const labelSpace = 24.0; // фиксированное место под подпись
        final avail = (constraints.maxHeight.isFinite ? constraints.maxHeight : 64) - labelSpace;
        final availClamped = avail.clamp(8.0, 200.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < values.length; i++) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maxV <= 0 ? 2 : (values[i] / maxV) * availClamped,
                      width: double.infinity,
                      color: _barColor(labels[i]),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: labelSpace - 4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(labels[i], style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != values.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  Color _barColor(String label) {
    switch (label) {
      case 'flash':
        return Colors.amber;
      case 'smoke':
        return Colors.blueGrey;
      case 'molotov':
        return Colors.deepOrange;
      case 'he':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

class _ThrowsHeatmap extends StatelessWidget {
  final MatchAnalysis analysis;
  const _ThrowsHeatmap({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final mapId = analysis.map;
    final points = analysis.throws
        .where((e) => (e.x != null && e.y != null))
        .map((e) => Offset(e.x!.clamp(0.0, 1.0), e.y!.clamp(0.0, 1.0)))
        .toList();
    if (points.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(child: Text(l.heatmapNoPoints));
    }
    if (mapId == null || mapId.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(child: Text(l.heatmapNoMap));
    }
    return FutureBuilder<List<CsMap>>(
      future: const NadesRepository().getMaps(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final list = snap.data ?? const <CsMap>[];
        final cm = list.firstWhere(
          (m) => m.id == mapId,
          orElse: () => CsMap(id: mapId, name: mapId, image: null),
        );
        if (cm.image == null) {
          final l = AppLocalizations.of(context);
          return Center(child: Text(l.heatmapNoImage));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(cm.image!, fit: BoxFit.cover),
                CustomPaint(painter: _HeatmapPainter(points: points)),
              ],
            );
          },
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<Offset> points; // нормированные 0..1
  _HeatmapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final grid = 20; // 20x20 клеток
    final Map<int, int> counts = {};
    for (final p in points) {
      final ix = (p.dx * grid).clamp(0, grid - 1).floor();
      final iy = (p.dy * grid).clamp(0, grid - 1).floor();
      final key = (iy << 8) | ix; // компактный ключ
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return;
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b).toDouble();

    for (final entry in counts.entries) {
      final ix = entry.key & 0xFF;
      final iy = (entry.key >> 8) & 0xFF;
      final cx = ((ix + 0.5) / grid) * size.width;
      final cy = ((iy + 0.5) / grid) * size.height;
      final t = (entry.value / maxCount).clamp(0.0, 1.0);
      final color = _colorFor(t).withValues(alpha: (0.35 + 0.35 * t));
      final radius = 10.0 + 22.0 * t;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  Color _colorFor(double t) {
    if (t < 0.33) return Colors.blueAccent;
    if (t < 0.66) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
