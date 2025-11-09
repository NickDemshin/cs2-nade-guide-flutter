import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/l10n/app_localizations_en.dart';
import 'package:flutter_application_1/l10n/nade_type_l10n.dart';
import 'package:flutter_application_1/models/nade.dart';

void main() {
  test('L10n type names return expected English labels', () {
    final l = AppLocalizationsEn();
    expect(l.typeName(NadeType.smoke), 'Smoke');
    expect(l.typeName(NadeType.flash), 'Flash');
    expect(l.typeName(NadeType.molotov), 'Molotov');
    expect(l.typeName(NadeType.he), 'HE');
  });
}
