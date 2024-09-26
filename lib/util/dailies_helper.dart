import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:collection/collection.dart';

class DailiesHelper {
  static List<DailyToken> _dailies = [];

  static DailyToken? get currentDailies {
    const defaultScheduleTime = 6;
    final configScheduleTime = injector<RemoteConfigService>()
        .getConfig<String>(ConfigGroup.daily, ConfigKey.scheduleTime,
            defaultScheduleTime.toString());
    final now = DateTime.now();
    final todayDisplayTime = now
        .add(now.timeZoneOffset)
        .subtract(Duration(hours: int.parse(configScheduleTime)));
    return _dailies.lastWhereOrNull(
        (element) => element.displayTime.isBefore(todayDisplayTime));
  }

  static void updateDailies(List<DailyToken> dailies) {
    _dailies = dailies;
  }

  static void clearDailies() {
    _dailies.clear();
  }
}
