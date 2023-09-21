import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';

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
      if (!(stamp.stampedLocation?.isInternet ?? true)) {
        final from = GeoLocation(
            position: stamps[lastStampLocation].stampedLocation!,
            address: null);
        final to = GeoLocation(position: stamp.stampedLocation!, address: null);
        travelInfo.add(
          TravelInfo(from, to, i),
        );
        lastStampLocation = i;
      } else {
        final from = GeoLocation(
            position: stamps[i - 1].stampedLocation!, address: null);
        final to = GeoLocation(position: stamp.stampedLocation!, address: null);
        travelInfo.add(TravelInfo(from, to, i));
      }
      if (!(stamp.stampedLocation?.isInternet ?? true)) {
        lastStampLocation = i;
      }
    }

    if (isCompleted) {
      final from =
          GeoLocation(position: stamps.last.stampedLocation!, address: null);
      final to = completeGeoLocation;
      travelInfo.add(TravelInfo(from, to, stamps.length));
    }
    return travelInfo;
  }
}
