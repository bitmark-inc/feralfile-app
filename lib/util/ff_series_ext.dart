import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';

extension FFSeriesExt on FFSeries {
  void checkAirdropStatusAndThrowIfError() {
    if (airdropInfo == null ||
        airdropInfo?.endedAt?.isBefore(DateTime.now()) == true) {
      throw AirdropExpired();
    }
    if ((airdropInfo?.remainAmount ?? 0) <= 0) {
      throw NoRemainingToken();
    }
  }
}
