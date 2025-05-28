// widgetbook for accountItem
import 'package:autonomy_flutter/graphql/account_settings/account_settings_client.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/address_cloud_object.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object/playlist_cloud_object.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/address_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/nft_collection_database.dart';
import 'package:autonomy_flutter/nft_collection/services/address_service.dart'
    as nft;
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook/widgetbook.dart';

class MockNftCollectionDatabase extends NftCollectionDatabase {
  @override
  TokenDao get tokenDao => throw UnimplementedError();

  @override
  AssetTokenDao get assetTokenDao => throw UnimplementedError();

  @override
  PredefinedCollectionDao get predefinedCollectionDao =>
      throw UnimplementedError();

  @override
  AssetDao get assetDao => throw UnimplementedError();

  @override
  ProvenanceDao get provenanceDao => throw UnimplementedError();

  @override
  AddressCollectionDao get addressCollectionDao => throw UnimplementedError();
}

class MockNftAddressService extends nft.AddressService {
  MockNftAddressService() : super(MockNftCollectionDatabase());
}

class MockAccountSettingsClient extends AccountSettingsClient {
  MockAccountSettingsClient() : super('https://mock-url.com');
}

class MockCloudDB extends CloudDB {
  @override
  Future<void> download({List<String>? keys}) async {}

  @override
  Future<void> uploadCurrentCache() async {}

  @override
  List<Map<String, String>> query(List<String> keys) => [];

  @override
  Future<void> write(List<Map<String, String>> settings,
      {OnConflict onConflict = OnConflict.override}) async {}

  @override
  Future<bool> delete(List<String> keys) async => true;

  @override
  Future<bool> didMigrate() async => true;

  @override
  Future<void> setMigrated() async {}

  @override
  String getFullKey(String key) => key;

  @override
  String get migrateKey => 'migrateKey';

  @override
  String get prefix => 'prefix';

  @override
  List<String> get keys => [];

  @override
  List<String> get values => [];

  @override
  Map<String, String> get allInstance => {};

  @override
  void clearCache() {}
}

class MockCloudManager extends CloudManager {
  late final WalletAddressCloudObject _walletAddressObject;
  late final CloudDB _deviceSettingsDB;
  late final CloudDB _userSettingsDB;
  late final PlaylistCloudObject _playlistCloudObject;
  late final CloudDB _ffDeviceCloudDB;

  MockCloudManager() {
    _walletAddressObject = WalletAddressCloudObject(MockCloudDB());
    _deviceSettingsDB = MockCloudDB();
    _userSettingsDB = MockCloudDB();
    _playlistCloudObject = PlaylistCloudObject(MockCloudDB());
    _ffDeviceCloudDB = MockCloudDB();
  }

  @override
  WalletAddressCloudObject get addressObject => _walletAddressObject;

  @override
  CloudDB get deviceSettingsDB => _deviceSettingsDB;

  @override
  CloudDB get userSettingsDB => _userSettingsDB;

  @override
  PlaylistCloudObject get playlistCloudObject => _playlistCloudObject;

  @override
  CloudDB get ffDeviceDB => _ffDeviceCloudDB;
}

class MockAddressService extends AddressService {
  MockAddressService() : super(MockCloudManager(), MockNftAddressService());
}

final accountItemComponent = WidgetbookComponent(
  name: 'AccountItem',
  useCases: [
    WidgetbookUseCase(
      name: 'default',
      builder: (context) => useCaseAccountItem(context),
    ),
  ],
);

Widget useCaseAccountItem(BuildContext context) {
  final name = context.knobs.string(
    label: 'Name',
    initialValue: 'Test Account',
  );

  final isHidden = context.knobs.boolean(
    label: 'Is Hidden',
    initialValue: true,
  );

  final address = WalletAddress(
    name: name,
    address: '0x1234567890abcdef1234567890abcdef12345678', // Ethereum address
    createdAt: DateTime.now(),
    isHidden: isHidden,
  );

  // Mock AccountsBloc với state mặc định
  final mockAccountsBloc = AccountsBloc(
    MockAddressService(),
    MockCloudManager(),
  );
  mockAccountsBloc.emit(AccountsState(
    addressBalances: {
      address.address:
          Pair(BigInt.from(1000000000000000000), '1 NFT'), // 1 ETH và 1 NFT
    },
  ));

  return BlocProvider<AccountsBloc>.value(
    value: mockAccountsBloc,
    child: Center(
      child: accountItem(
        context,
        address,
      ),
    ),
  );
}
