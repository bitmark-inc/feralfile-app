import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/dailies.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

class DailiesHelper {
  static final List<DailyToken> _dailies = [];

  static DateTime get currentDailyDay {
    final now = DateTime.now();
    const defaultScheduleTime = 6;
    final configScheduleTime =
        injector<RemoteConfigService>().getConfig<String>(
      ConfigGroup.daily,
      ConfigKey.scheduleTime,
      defaultScheduleTime.toString(),
    );
    final todayDisplayTime = now
        .add(now.timeZoneOffset)
        .subtract(Duration(hours: int.parse(configScheduleTime)));
    return DateTime(
      todayDisplayTime.year,
      todayDisplayTime.month,
      todayDisplayTime.day,
    );
  }

  static DateTime get nextDailyDateTime {
    const defaultScheduleTime = 6;
    final configScheduleTime =
        injector<RemoteConfigService>().getConfig<String>(
      ConfigGroup.daily,
      ConfigKey.scheduleTime,
      defaultScheduleTime.toString(),
    );
    final now =
        DateTime.now().subtract(Duration(hours: int.parse(configScheduleTime)));
    final startNextDay = DateTime(now.year, now.month, now.day + 1).add(
      Duration(hours: int.parse(configScheduleTime), seconds: 3),
      // add 3 seconds to avoid the same artwork
    );
    return startNextDay;
  }

  static List<DailyToken> get currentDailies {
    final currentDay = DailiesHelper.currentDailyDay;
    return _dailies
        .where(
          (element) =>
              element.displayTime.isAfter(currentDay) &&
              element.displayTime
                  .isBefore(currentDay.add(const Duration(days: 1))),
        )
        .toList();
  }

  static void updateDailies(List<DailyToken> dailies) {
    _dailies
      ..clear()
      ..addAll(dailies);
  }

  static void clearDailies() {
    _dailies.clear();
  }
}
