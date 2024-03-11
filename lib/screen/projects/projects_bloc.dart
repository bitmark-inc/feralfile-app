import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';

class ProjectsBloc extends AuBloc<ProjectsEvent, ProjectsState> {
  final EthereumService _ethereumService;
  final ConfigurationService _configurationService;
  final AccountService _accountService;

  ProjectsBloc(
      this._ethereumService, this._configurationService, this._accountService)
      : super(ProjectsState()) {
    on<GetProjectsEvent>((event, emit) async {
      final showYokoOno = await _doUserHaveYokoOnoRecord();
      emit(state.copyWith(loading: false, showYokoOno: showYokoOno));
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
    const count = 50;
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
