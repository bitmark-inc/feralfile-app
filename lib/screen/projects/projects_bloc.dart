import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/project.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/widgets/nft_collection_bloc_event.dart';

class ProjectsBloc extends AuBloc<ProjectsEvent, ProjectsState> {
  final EthereumService _ethereumService;
  final ConfigurationService _configurationService;
  final AccountService _accountService;
  final RemoteConfigService _remoteConfigService;
  final FeralFileService _feralfileService;

  ProjectsBloc(this._ethereumService, this._configurationService,
      this._accountService, this._remoteConfigService, this._feralfileService)
      : super(ProjectsState()) {
    on<GetProjectsEvent>((event, emit) async {
      final List<ProjectInfo> newProjects = [];
      CompactedAssetToken? firstUserMoMAPostCard;
      Artwork? yokoOnoRecordArtwork;
      try {
        firstUserMoMAPostCard = await _getFirstUserMoMAPostCard();
        final showYokoOno = await _doUserHaveYokoOnoRecord();
        if (showYokoOno || true) {
          final config = _remoteConfigService.getConfig<Map<String, dynamic>>(
              ConfigGroup.exhibition, ConfigKey.yokoOnoPublic, {});
          yokoOnoRecordArtwork = await _feralfileService.getArtwork(
            config['public_token_id'],
          );
        }
      } catch (_) {}

      if (yokoOnoRecordArtwork != null) {
        newProjects.add(
          ProjectInfo(
            title: 'yoko_ono_project_title'.tr(),
            route: AppRouter.ffArtworkPreviewPage,
            arguments: FeralFileArtworkPreviewPagePayload(
              artwork: yokoOnoRecordArtwork,
            ),
            delegate: yokoOnoRecordArtwork,
          ),
        );
      }

      if (firstUserMoMAPostCard != null) {
        newProjects.add(
          ProjectInfo(
            title: 'moma_postcard_title'.tr(),
            route: AppRouter.momaPostcardPage,
            delegate: firstUserMoMAPostCard,
          ),
        );
      }

      emit(state.copyWith(loading: false, projects: newProjects));
    });
  }

  Future<CompactedAssetToken?> _getFirstUserMoMAPostCard() async {
    final addresses = await _accountService.getAllAddresses();
    final postCardTokens = await injector<NftCollectionDatabase>()
        .assetTokenDao
        .findAllAssetTokensByOwnersAndContractAddress(
            addresses,
            Environment.postcardContractAddress,
            1,
            DateTime.now().millisecondsSinceEpoch,
            PageKey.init().id);
    return postCardTokens.isNotEmpty
        ? CompactedAssetToken.fromAssetToken(postCardTokens[0])
        : null;
  }

  Future<bool> _doUserHaveYokoOnoRecord() async {
    final addresses = await _accountService.getAllAddresses();
    final yokoOnoRecordOwners = _configurationService.getRecordOwners();
    if (yokoOnoRecordOwners.any((element) => addresses.contains(element))) {
      return true;
    }

    final recordOwnersFromBlockchain =
        await _getRecordOwnersFromBlockchain(yokoOnoRecordOwners.length);

    await _configurationService.setRecordOwners(recordOwnersFromBlockchain);
    return recordOwnersFromBlockchain
        .any((element) => addresses.contains(element));
  }

  Future<List<String>> _getRecordOwnersFromBlockchain(int startIndex) async {
    const count = 20;
    int currentIndex = startIndex;
    final List<String> recordOwners = [];
    List<String> owners = [];
    do {
      owners = await _ethereumService.getPublicRecordOwners(
          BigInt.from(currentIndex), BigInt.from(count));
      recordOwners.addAll(owners);
      currentIndex += count;
    } while (owners.length >= count);
    return recordOwners;
  }
}
