import '../models/nade.dart';
import 'app_localizations.dart';

extension NadeTypeL10n on AppLocalizations {
  String typeName(NadeType t) {
    switch (t) {
      case NadeType.smoke:
        return typeSmoke;
      case NadeType.flash:
        return typeFlash;
      case NadeType.molotov:
        return typeMolotov;
      case NadeType.he:
        return typeHE;
    }
  }
}

