import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/nade.dart';

void main() {
  test('Nade.fromJson maps fields and types', () {
    final j = {
      'id': 'n1',
      'title': 'Test',
      'type': 'flash',
      'side': 'CT',
      'from': 'Spawn',
      'to': 'Site',
      'technique': 'stand',
      'toX': 0.1,
      'toY': 0.2,
      'fromX': 0.3,
      'fromY': 0.4,
      'videoUrl': '',
      'description': 'desc',
    };
    final n = Nade.fromJson(j, mapId: 'm1');
    expect(n.id, 'n1');
    expect(n.mapId, 'm1');
    expect(n.type, NadeType.flash);
    expect(n.side, 'CT');
    expect(n.toX, closeTo(0.1, 1e-9));
    expect(n.fromY, closeTo(0.4, 1e-9));
  });
}

