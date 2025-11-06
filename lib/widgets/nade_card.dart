import 'package:flutter/material.dart';

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
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _typeColor(context, nade.type),
        child: Text(nadeTypeLabel(nade.type)[0]),
      ),
      title: Text(nade.title),
      subtitle: Text('От: ${nade.from} → К: ${nade.to}'),
      trailing: Chip(
        label: Text(nadeTypeLabel(nade.type)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

