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
    for (int i = 0; i < stamps.length - 1; i++) {
      travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i + 1));
    }
    if (travelInfo.isNotEmpty && travelInfo[0].from.stampedLocation != null) {
      travelInfo[0] = travelInfo[0]
          .copyWith(from: stamps[0].copyWith(stampedLocation: moMALocation));
    }

    if (isCompleted) {
      travelInfo.add(TravelInfo(stamps.last, null, stamps.length));
    }
    return travelInfo;
  }

  List<String> get listOwner {
    return List.generate(12, (index) => "Owner $index");
  }
}
