import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/util/constants.dart';

extension PostcardMetadataExtension on PostcardMetadata {
  int get counter {
    return locationInformation.length;
  }

  bool get isStamped {
    return locationInformation.last.stampedLocation != null;
  }

  bool get isFinalClaimed {
    return locationInformation.length == MAX_STAMP_IN_POSTCARD - 1;
  }

  bool get isFinal {
    return locationInformation.length == MAX_STAMP_IN_POSTCARD;
  }

  bool get isCompleted {
    return isFinal && isStamped;
  }

  List<TravelInfo> get listTravelInfoWithoutLocationName {
    final stamps = locationInformation;
    final travelInfo = <TravelInfo>[];
    int lastStampLocation = 0;
    for (int i = 1; i < stamps.length; i++) {
      final stamp = stamps[i];
      if (!(stamp.claimedLocation?.isInternet ?? true)) {
        travelInfo.add(TravelInfo(stamps[lastStampLocation], stamp, i));
        lastStampLocation = i;
      } else {
        travelInfo.add(TravelInfo(stamps[i - 1], stamp, i));
      }
      if (!(stamp.stampedLocation?.isInternet ?? true)) {
        lastStampLocation = i;
      }
    }

    if (isCompleted) {
      travelInfo.add(TravelInfo(stamps.last, null, stamps.length));
    }
    return travelInfo;
  }

  int get numberOfStamp {
    return locationInformation
        .where((element) => element.stampedLocation != null)
        .toList()
        .length;
  }
}
