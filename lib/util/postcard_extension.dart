import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';

extension PostcardMetadataExtension on PostcardMetadata {
  int? get counter {
    return artworkData.locationInformation.length;
  }

  bool get isStamped {
    return artworkData.locationInformation.last.claimedLocation != null;
  }

  bool get isFinal {
    return artworkData.locationInformation.length == 15;
  }

  bool get isCompleted {
    return isFinal && isStamped;
  }

  List<TravelInfo> get listTravelInfoWithoutLocationName {
    final stamps = artworkData.locationInformation;
    final travelInfo = <TravelInfo>[];
    for (int i = 0; i < stamps.length - 1; i++) {
      travelInfo.add(TravelInfo(stamps[i], stamps[i + 1], i));
    }
    if (stamps[stamps.length - 1].stampedLocation != null) {
      travelInfo
          .add(TravelInfo(stamps[stamps.length - 1], null, stamps.length - 1));
    }

    if (travelInfo.length > 14) {
      travelInfo.removeLast();
    }
    return travelInfo;
  }

  String get lastOwner {
    return creators.last;
  }
}
