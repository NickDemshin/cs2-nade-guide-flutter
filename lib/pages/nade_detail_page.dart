import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

import '../models/nade.dart';

class NadeDetailPage extends StatelessWidget {
  final Nade nade;
  const NadeDetailPage({super.key, required this.nade});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final desc = _localizedDescription(context, nade);
    return Scaffold(
      appBar: AppBar(title: Text(nade.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_typeLabel(context, nade.type))),
              Chip(label: Text(l.sideLabel(nade.side))),
              Chip(label: Text(l.techniqueLabel(nade.technique))),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(title: 'Откуда', value: nade.from),
          _InfoRow(title: 'Куда', value: nade.to),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              desc,
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
                  label: Text(l.openVideo),
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
        SnackBar(content: Text(AppLocalizations.of(context).openVideoFailed)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).openVideoError)),
      );
    }
  }
}

String _typeLabel(BuildContext context, NadeType t) {
  final l = AppLocalizations.of(context);
  switch (t) {
    case NadeType.smoke:
      return l.typeSmoke;
    case NadeType.flash:
      return l.typeFlash;
    case NadeType.molotov:
      return l.typeMolotov;
    case NadeType.he:
      return l.typeHE;
  }
}

String? _localizedDescription(BuildContext context, Nade n) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'en') {
    if (n.descriptionEn != null && n.descriptionEn!.isNotEmpty) return n.descriptionEn;
  } else if (locale.languageCode == 'ru') {
    if (n.descriptionRu != null && n.descriptionRu!.isNotEmpty) return n.descriptionRu;
  }
  return n.description;
}
