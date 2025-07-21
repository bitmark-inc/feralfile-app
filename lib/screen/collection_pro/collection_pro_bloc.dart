import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/predefined_collection_model.dart';
import 'package:autonomy_flutter/nft_collection/services/address_service.dart';
import 'package:autonomy_flutter/nft_collection/utils/medium_category.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CollectionProBloc
    extends Bloc<CollectionProEvent, CollectionLoadedState> {
  final _predefinedCollectionDao = injector.get<PredefinedCollectionDao>();
  final _configurationService = injector.get<ConfigurationService>();
  final _assetTokenDao = injector.get<AssetTokenDao>();

  CollectionProBloc() : super(CollectionLoadedState()) {
    on<LoadCollectionEvent>((event, emit) async {
      final hiddenTokenIDs = _configurationService.getHiddenTokenIDs();
      final hiddenAddresses =
          await injector<NftAddressService>().getHiddenAddresses();
      final hiddenTokens =
          await _assetTokenDao.findAllAssetTokensByTokenIDs(hiddenTokenIDs);
      hiddenTokens.removeWhere((element) =>
          hiddenAddresses.contains(element.owner) ||
          (element.balance ?? 0) <= 0);

      if (event.filterStr.isEmpty) {
        List<PredefinedCollectionModel> listPredefinedCollectionModelByMedium =
            await _getAllPredefinedCollectionByMedium(
                filterStr: event.filterStr);
        for (final predefinedCollection
            in listPredefinedCollectionModelByMedium) {
          final ignoreTokens = hiddenTokens.where((element) {
            if (predefinedCollection.id == MediumCategory.other) {
              return !MediumCategoryExt.getAllMimeType()
                  .contains(element.mimeType);
            }
            return MediumCategory.mineTypes(predefinedCollection.id)
                .contains(element.mimeType);
          }).toList();
          predefinedCollection.total =
              predefinedCollection.total - ignoreTokens.length;
        }
        listPredefinedCollectionModelByMedium
            .removeWhere((element) => element.total <= 0);
        emit(state.copyWith(
          listPredefinedCollectionByMedium:
              listPredefinedCollectionModelByMedium,
        ));
      } else {
        List<CompactedAssetToken> works =
            await _getAllTokenFilterByTitleOrArtist(filterStr: event.filterStr);
        emit(
          state.copyWith(
            works: works,
          ),
        );
      }
      final listPredefinedCollectionModelByArtist =
          await _predefinedCollectionDao.getPredefinedCollectionsByArtist();

      for (final predefinedCollection
          in listPredefinedCollectionModelByArtist) {
        final ignoreTokens = hiddenTokens
            .where((element) => element.artistID == predefinedCollection.id)
            .toList();
        predefinedCollection.total =
            predefinedCollection.total - ignoreTokens.length;
      }
      listPredefinedCollectionModelByArtist
          .removeWhere((element) => element.total <= 0);

      emit(
        state.copyWith(
          listPredefinedCollectionByArtist:
              listPredefinedCollectionModelByArtist,
        ),
      );
    });
  }

  Future<List<PredefinedCollectionModel>> _getAllPredefinedCollectionByMedium(
      {String filterStr = ''}) async {
    final List<PredefinedCollectionModel> listPredefinedCollectionByMedium = [];
    final listMedium = MediumCategoryExt.getAllCategories();
    for (final mediumCatalog in listMedium) {
      final predefinedCollections =
          await _predefinedCollectionDao.getPredefinedCollectionsByMedium(
        title: filterStr,
        mimeTypes: MediumCategory.mineTypes(mediumCatalog),
        mediums: MediumCategoryExt.mediums(mediumCatalog),
      );
      if (predefinedCollections.isNotEmpty &&
          predefinedCollections.first.total > 0) {
        final predefinedCollection = predefinedCollections.first
          ..name = MediumCategoryExt.getName(mediumCatalog)
          ..id = mediumCatalog;
        listPredefinedCollectionByMedium.add(predefinedCollection);
      }
    }
    final predefinedCollections =
        await _predefinedCollectionDao.getPredefinedCollectionsByMedium(
            title: filterStr,
            mimeTypes: MediumCategoryExt.getAllMimeType(),
            mediums: MediumCategoryExt.getAllMediums(),
            isInMimeTypes: false);

    if (predefinedCollections.isNotEmpty &&
        predefinedCollections.first.total > 0) {
      final predefinedCollection = predefinedCollections.first
        ..name = MediumCategoryExt.getName(MediumCategory.other)
        ..id = MediumCategory.other;
      listPredefinedCollectionByMedium.add(predefinedCollection);
    }
    return listPredefinedCollectionByMedium;
  }

  Future<List<CompactedAssetToken>> _getAllTokenFilterByTitleOrArtist(
      {String filterStr = ''}) async {
    List<CompactedAssetToken> works = [];
    final hiddenTokenIDs = _configurationService.getHiddenTokenIDs();
    if (filterStr.isNotEmpty) {
      final assetTokens =
          await _assetTokenDao.findAllAssetTokensByFilter(filter: filterStr);
      assetTokens.removeWhere((element) =>
          hiddenTokenIDs.contains(element.id) || (element.balance ?? 0) <= 0);
      works = assetTokens
          .map((e) => CompactedAssetToken.fromAssetToken(e))
          .toList();
    }
    return works;
  }
}
