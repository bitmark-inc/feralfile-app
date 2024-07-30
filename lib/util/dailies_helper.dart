import 'package:autonomy_flutter/model/dailies.dart';
import 'package:collection/collection.dart';

class DailiesHelper {
  static List<DailyToken> _dailies = [];

  static DailyToken? get currentDailies {
    final now = DateTime.now().toUtc();
    return _dailies
        .lastWhereOrNull((element) => element.displayTime.isBefore(now));
  }

  static void updateDailies(List<DailyToken> dailies) {
    _dailies = dailies;
  }

  static void clearDailies() {
    _dailies.clear();
  }
}
