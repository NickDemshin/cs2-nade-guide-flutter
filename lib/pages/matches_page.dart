import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../utils/share_code.dart';

import '../data/matches_repository.dart';
import '../models/match_entry.dart';

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить матч?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.remove(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Матч удалён')));
        _refresh();
      }
    }
  }

  void _openImport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImportSheet(onSubmit: (code) async {
        try {
          final decoded = decodeShareCode(code);
          final entry = MatchEntry(
            id: const Uuid().v4(),
            shareCode: code.trim(),
            createdAt: DateTime.now(),
            status: MatchStatus.ready,
            matchId: decoded.matchId,
            outcomeId: decoded.outcomeId,
            token: decoded.token,
          );
          await _repo.add(entry);
          if (!context.mounted) return;
          Navigator.pop(context);
          _refresh();
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Неверный share code: $e')),
          );
        }
      }),
    );
  }

  // Убраны экспорт/импорт JSON из интерфейса по запросу

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Матчи')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openImport,
        icon: const Icon(Icons.add),
        label: const Text('Импорт'),
      ),
      body: FutureBuilder<List<MatchEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data ?? const <MatchEntry>[])..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Пока нет матчей'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _openImport,
                    icon: const Icon(Icons.add),
                    label: const Text('Импорт по share code'),
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
                    _refresh();
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
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmAndDelete(m),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _MatchDetailPage(entry: m)),
                      );
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
  final ValueChanged<String> onSubmit;
  const _ImportSheet({required this.onSubmit});

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'Введите share code из CS2');
      return;
    }
    widget.onSubmit(v);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
                const Expanded(child: Text('Импорт матча')),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: 'Share code',
                hintText: 'CSGO-ABC123-... (CS2 share code)',
                errorText: _error,
                prefixIcon: const Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.download),
                    label: const Text('Импортировать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDetailPage extends StatelessWidget {
  final MatchEntry entry;
  const _MatchDetailPage({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ матча'),
        actions: [
          IconButton(
            tooltip: 'Удалить матч',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Удалить матч?'),
                  content: const Text('Действие нельзя отменить.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                  ],
                ),
              );
              if (ok == true) {
                await const MatchesRepository().remove(entry.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Матч удалён')));
                }
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
            Text('Share code:', style: Theme.of(context).textTheme.titleSmall),
            SelectableText(entry.shareCode),
            const SizedBox(height: 12),
            Text('Статус: ${entry.status.name}'),
            if (entry.note != null) ...[
              const SizedBox(height: 8),
              Text(entry.note!),
            ],
            const Spacer(),
            Text(
              'Заглушка офлайн. Для фактического анализа нужен сервер, который скачивает и парсит демо по коду.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
