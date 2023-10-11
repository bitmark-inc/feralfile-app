import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/medium_category_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/predefined_collection_model.dart';
import 'package:nft_collection/utils/medium_category.dart';

class CollectionProBloc extends Bloc<CollectionProEvent, CollectionProState> {
  final _predefinedCollectionDao = injector.get<PredefinedCollectionDao>();
  final _configurationService = injector.get<ConfigurationService>();
  final _assetTokenDao = injector.get<AssetTokenDao>();

  CollectionProBloc() : super(CollectionInitState()) {
    on<LoadCollectionEvent>((event, emit) async {
      final List<PredefinedCollectionModel>
          listPredefinedCollectionModelByMedium =
          await _getAllPredefinedCollectionByMedium(filterStr: event.filterStr);
      final listPredefinedCollectionModelByArtist =
          await _predefinedCollectionDao.getPredefinedCollectionsByArtist();

      final hiddenTokenIDs = _configurationService.getHiddenOrSentTokenIDs();
      final hiddenTokens =
          await _assetTokenDao.findAllAssetTokensByTokenIDs(hiddenTokenIDs);
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
      listPredefinedCollectionModelByMedium
          .removeWhere((element) => element.total <= 0);
      List<CompactedAssetToken> works =
          await _getAllTokenFilterByTitleOrArtist(filterStr: event.filterStr);
      emit(
        CollectionLoadedState(
          listPredefinedCollectionByMedium:
              listPredefinedCollectionModelByMedium,
          listPredefinedCollectionByArtist:
              listPredefinedCollectionModelByArtist,
          works: works,
        ),
      );
    });
  }

  Future<List<PredefinedCollectionModel>> _getAllPredefinedCollectionByMedium(
      {String filterStr = ""}) async {
    final List<PredefinedCollectionModel> listPredefinedCollectionByMedium = [];
    final listMedium = MediumCategoryExt.getAllCategories();
    for (final mediumCatelog in listMedium) {
      final predefinedCollections =
          await _predefinedCollectionDao.getPredefinedCollectionsByMedium(
        title: filterStr,
        mimeTypes: MediumCategory.mineTypes(mediumCatelog),
        mediums: MediumCategoryExt.mediums(mediumCatelog),
      );
      if (predefinedCollections.isNotEmpty &&
          predefinedCollections.first.total > 0) {
        final predefinedCollection = predefinedCollections.first;
        predefinedCollection.name = MediumCategoryExt.getName(mediumCatelog);
        predefinedCollection.id = mediumCatelog;
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
      final predefinedCollection = predefinedCollections.first;
      predefinedCollection.name =
          MediumCategoryExt.getName(MediumCategory.other);
      predefinedCollection.id = MediumCategory.other;
      listPredefinedCollectionByMedium.add(predefinedCollection);
    }
    return listPredefinedCollectionByMedium;
  }

  Future<List<CompactedAssetToken>> _getAllTokenFilterByTitleOrArtist(
      {String filterStr = ""}) async {
    List<CompactedAssetToken> works = [];
    final hiddenTokenIDs = _configurationService.getHiddenOrSentTokenIDs();
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
