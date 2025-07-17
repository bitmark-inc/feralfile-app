import 'package:autonomy_flutter/nft_collection/graphql/clients/artblocks_client.dart';
import 'package:autonomy_flutter/nft_collection/services/artblocks_service.dart';
import 'package:get_it/get_it.dart';

final ncInjector = GetIt.instance;

void setupNftCollectionDependencies() {
  ncInjector.registerLazySingleton<ArtblocksClient>(
    () => ArtblocksClient(),
  );

  ncInjector.registerLazySingleton<ArtBlockService>(
    () => ArtBlockService(ncInjector<ArtblocksClient>()),
  );
}
