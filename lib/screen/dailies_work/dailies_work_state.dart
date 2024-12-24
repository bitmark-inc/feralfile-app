import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';

class DailiesWorkState {
  List<DailyInfo> dailyInfos;

  DailiesWorkState({
    required this.dailyInfos,
  });

  DailyInfo? get currentDailyInfo {
    return dailyInfos.firstOrNull;
  }
}
