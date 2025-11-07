import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/nade_type_l10n.dart';

import '../models/nade.dart';

class NadeCard extends StatelessWidget {
  final Nade nade;
  final VoidCallback? onTap;
  const NadeCard({super.key, required this.nade, this.onTap});

  Color _typeColor(BuildContext context, NadeType t) {
    switch (t) {
      case NadeType.smoke:
        return Colors.grey;
      case NadeType.flash:
        return Colors.lightBlue;
      case NadeType.molotov:
        return Colors.deepOrange;
      case NadeType.he:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _typeColor(context, nade.type),
        child: Text(AppLocalizations.of(context).typeName(nade.type)[0]),
      ),
      title: Text(nade.title),
      subtitle: Text(l.fromTo(nade.from, nade.to)),
      trailing: Chip(
        label: Text(AppLocalizations.of(context).typeName(nade.type)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
// Removed duplicate _typeLabel; use AppLocalizations.typeName extension instead.
