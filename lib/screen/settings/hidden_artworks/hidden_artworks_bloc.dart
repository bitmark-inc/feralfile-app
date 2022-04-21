import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HiddenArtworksBloc extends Bloc<HiddenArtworksEvent, List<AssetToken>> {
  AppDatabase _appDatabase;

  HiddenArtworksBloc(this._appDatabase) : super([]) {
    on<HiddenArtworksEvent>((event, emit) async {
      final assets = await _appDatabase.assetDao.findAllHiddenAssets();
      emit(assets);
    });
  }
}

class HiddenArtworksEvent {}
