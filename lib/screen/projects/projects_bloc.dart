import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/tap_navigate.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProjectsBloc extends AuBloc<ProjectsEvent, ProjectsState> {
  final EthereumService _ethereumService;
  final ConfigurationService _configurationService;
  final AccountService _accountService;
  final RemoteConfigService _remoteConfigService;

  ProjectsBloc(this._ethereumService, this._configurationService,
      this._accountService, this._remoteConfigService)
      : super(ProjectsState()) {
    on<GetProjectsEvent>((event, emit) async {
      final List<TapNavigate> newProjects = [];
      final showYokoOno = await _doUserHaveYokoOnoRecord();
      if (showYokoOno) {
        final config = _remoteConfigService.getConfig<Map<String, dynamic>>(
            ConfigGroup.exhibition, ConfigKey.yokoOnoPublic, {});
        final artwork = Artwork.createFake(config['public_version_thumbnail'],
            config['public_version_preview'], 'software');
        newProjects.add(TapNavigate(
            title: 'yoko_ono_public_version'.tr(),
            route: AppRouter.ffArtworkPreviewPage,
            arguments: FeralFileArtworkPreviewPagePayload(
              artwork: artwork,
            )));
      }

      emit(state.copyWith(loading: false, projects: newProjects));
    });
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

    do {
      final owners = await _ethereumService.getPublicRecordOwners(
          BigInt.from(currentIndex), BigInt.from(count));
      recordOwners.addAll(owners);
      currentIndex += owners.length;
    } while (recordOwners.length >= count);
    return recordOwners;
  }
}
