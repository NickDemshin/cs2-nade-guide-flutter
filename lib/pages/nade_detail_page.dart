import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/nade.dart';

class NadeDetailPage extends StatelessWidget {
  final Nade nade;
  const NadeDetailPage({super.key, required this.nade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nade.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(nadeTypeLabel(nade.type))),
              Chip(label: Text('Сторона: ${nade.side}')),
              Chip(label: Text('Техника: ${nade.technique}')),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(title: 'Откуда', value: nade.from),
          _InfoRow(title: 'Куда', value: nade.to),
          if (nade.description != null && nade.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              nade.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (nade.videoUrl != null && nade.videoUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Видео:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: SelectableText(nade.videoUrl!)),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Открыть видео'),
                  onPressed: () => _openVideo(context, nade.videoUrl!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final styleTitle = Theme.of(context).textTheme.titleSmall;
    final styleValue = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(title, style: styleTitle)),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: styleValue)),
        ],
      ),
    );
  }
}

Future<void> _openVideo(BuildContext context, String url) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) throw 'Некорректная ссылка';
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при открытии ссылки')),
      );
    }
  }
}
