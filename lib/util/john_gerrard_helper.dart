import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/series_ext.dart';

class JohnGerrardHelper {
  static int _johnGerrardLatestRevealIndex = 0;

  static int get johnGerrardLatestRevealIndex => _johnGerrardLatestRevealIndex;

  static String? get contractAddress {
    final config =
        injector<RemoteConfigService>().getConfig<Map<String, dynamic>>(
      ConfigGroup.exhibition,
      ConfigKey.johnGerrard,
      {},
    );
    return config['contract_address'] as String?;
  }

  static String? get exhibitionID {
    final config =
        injector<RemoteConfigService>().getConfig<Map<String, dynamic>>(
      ConfigGroup.exhibition,
      ConfigKey.johnGerrard,
      {},
    );
    return config['exhibition_id'] as String?;
  }

  static List<dynamic> get seriesIDs {
    final listSeriesIds =
        injector<RemoteConfigService>().getConfig<List<dynamic>?>(
      ConfigGroup.johnGerrard,
      ConfigKey.seriesIds,
      [],
    );
    return listSeriesIds ?? [];
  }

  static List<dynamic> get assetIDs {
    final listAssetIds =
        injector<RemoteConfigService>().getConfig<List<dynamic>?>(
      ConfigGroup.johnGerrard,
      ConfigKey.assetIds,
      [],
    );
    return listAssetIds ?? [];
  }

  static String getIndexID(String tokenId) {
    final contractAddress = JohnGerrardHelper.contractAddress;
    return 'eth-$contractAddress-$tokenId';
  }

  static List<CustomExhibitionNote> get customNote {
    final listCustomNote =
        injector<RemoteConfigService>().getConfig<List<dynamic>?>(
      ConfigGroup.johnGerrard,
      ConfigKey.customNote,
      [],
    );
    return listCustomNote
            ?.map((e) => CustomExhibitionNote.fromJson(e))
            .toList() ??
        [];
  }

  static Future<void> updateJohnGerrardLatestRevealIndex() async {
    log.info('updateJohnGerrardLatestRevealIndex');
    try {
      final exhibitionId = JohnGerrardHelper.exhibitionID!;
      final exhibition =
          await injector<FeralFileService>().getExhibition(exhibitionId);
      final series = exhibition.series!.first;
      final latestRevealedArtworkIndex = series.latestRevealedArtworkIndex;

      if (latestRevealedArtworkIndex != null) {
        log.info('update latestRevealedIndex: $latestRevealedArtworkIndex');
        _johnGerrardLatestRevealIndex = latestRevealedArtworkIndex;
      }
    } catch (e) {
      log.info('updateJohnGerrardLatestRevealIndex error: $e');
    }
  }

  static List<String> disableKeys = ['i', 'g', 'm'];
}
