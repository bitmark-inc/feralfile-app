import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';

class DailiesWorkState {
  DailiesWorkState({
    required this.dailyInfos,
  });

  List<DailyInfo> dailyInfos;

  DailyInfo? get currentDailyInfo {
    final index = currentDailyIndex;
    return index < dailyInfos.length ? dailyInfos[index] : null;
  }
}

extension DailiesWorkStateExtension on DailiesWorkState {
  int get currentDailyIndex {
    // Each daily slide lasts for a fixed duration (5 minutes in this case).
    // At the start of the day (`currentDailyDay`), the index is 0.
    // As time progresses, the index increases every 5 minutes, cycling through the length of `dailyInfos`.
    const dailySlideTime = Duration(minutes: 5);
    final now = DateTime.now();
    final secondsSinceStart =
        now.difference(DailiesHelper.currentDailyDay).inSeconds;

    // Calculate the current index based on the time elapsed and the length of `dailyInfos`.
    return (secondsSinceStart / dailySlideTime.inSeconds).floor() %
        dailyInfos.length;
  }

  int get nextDailyIndex {
    return (currentDailyIndex + 1) % dailyInfos.length;
  }

  int get previousDailyIndex {
    return (currentDailyIndex - 1 + dailyInfos.length) % dailyInfos.length;
  }
}
