import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';
import 'package:autonomy_flutter/util/log.dart';

class DailiesWorkState {
  DailiesWorkState({
    required this.dailyInfos,
  });

  List<DailyInfo> dailyInfos;

  DailyInfo? get currentDailyInfo {
    if (dailyInfos.isEmpty) {
      return null;
    }
    final index = currentDailySlideIndex;
    return index < dailyInfos.length ? dailyInfos[index] : null;
  }

  // copyWith method
  DailiesWorkState copyWith({
    List<DailyInfo>? dailyInfos,
  }) {
    return DailiesWorkState(
      dailyInfos: dailyInfos ?? this.dailyInfos,
    );
  }
}

const dailySlideTime = Duration(seconds: 20);

extension DailiesWorkStateExtension on DailiesWorkState {
  int get currentDailySlideIndex {
    assert(dailyInfos.isNotEmpty);
    // Each daily slide lasts for a fixed duration (5 minutes in this case).
    // At the start of the day (`currentDailyDay`), the index is 0.
    // As time progresses, the index increases every 5 minutes, cycling through the length of `dailyInfos`.
    final now = DateTime.now();
    final secondsSinceStart =
        now.difference(DailiesHelper.currentDailyDay).inSeconds;

    // Calculate the current index based on the time elapsed and the length of `dailyInfos`.
    final index = (secondsSinceStart / dailySlideTime.inSeconds).floor() %
        dailyInfos.length;
    log.info('now: $now');
    log.info('secondsSinceStart: $secondsSinceStart');
    log.info('currentDailySlideIndex: $index');
    return index;
  }

  int get nextDailySlideIndex {
    return (currentDailySlideIndex + 1) % dailyInfos.length;
  }

  int get previousDailySlideIndex {
    return (currentDailySlideIndex - 1 + dailyInfos.length) % dailyInfos.length;
  }

  Duration get timeUntilNextSlide {
    final now = DateTime.now();
    final secondsSinceStart =
        now.difference(DailiesHelper.currentDailyDay).inSeconds;

    // Calculate the time until the next daily slide.
    final secondsUntilNextDaily = dailySlideTime.inSeconds -
        (secondsSinceStart % dailySlideTime.inSeconds);
    return Duration(seconds: secondsUntilNextDaily);
  }
}
