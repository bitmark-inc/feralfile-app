import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/travel_infor.dart';
import 'package:autonomy_flutter/util/geolocation.dart';

extension PostcardMetadataExtension on PostcardMetadata {
  List<TravelInfo> get listTravelInfoWithoutLocationName {
    final stamps = locationInformation;
    final travelInfo = <TravelInfo>[];
    int lastStampLocation = 0;
    for (int i = 1; i < stamps.length; i++) {
      final stamp = stamps[i];
      if (!stamp.isInternet) {
        final from =
            GeoLocation(position: stamps[lastStampLocation], address: null);
        final to = GeoLocation(position: stamp, address: null);
        travelInfo.add(
          TravelInfo(from, to, i),
        );
        lastStampLocation = i;
      } else {
        final from = GeoLocation(position: stamps[i - 1], address: null);
        final to = GeoLocation(position: stamp, address: null);
        travelInfo.add(TravelInfo(from, to, i));
      }
      if (!stamp.isInternet) {
        lastStampLocation = i;
      }
    }
    return travelInfo;
  }
}
