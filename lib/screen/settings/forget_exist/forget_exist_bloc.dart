//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/announcement/announcement_store.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/hive_store_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nft_collection/database/nft_collection_database.dart';

class ForgetExistBloc extends AuBloc<ForgetExistEvent, ForgetExistState> {
  final AuthService _authService;
  final IAPApi _iapApi;
  final CloudDatabase _cloudDatabase;
  final AppDatabase _appDatabase;
  final NftCollectionDatabase _nftCollectionDatabase;
  final ConfigurationService _configurationService;
  final AddressService _addressService;

  ForgetExistBloc(
    this._authService,
    this._iapApi,
    this._cloudDatabase,
    this._appDatabase,
    this._nftCollectionDatabase,
    this._configurationService,
    this._addressService,
  ) : super(ForgetExistState(false, null)) {
    on<UpdateCheckEvent>((event, emit) async {
      emit(ForgetExistState(event.isChecked, state.isProcessing));
    });

    on<ConfirmForgetExistEvent>((event, emit) async {
      emit(ForgetExistState(state.isChecked, true));

      unawaited(_addressService.clearPrimaryAddress());
      unawaited(deregisterPushNotification());

      await injector<MetricClientService>().reset();
      try {
        await _iapApi.deleteUserData();
      } catch (e) {
        log.info('Error when delete all profiles: $e');
      }

      await _cloudDatabase.removeAll();
      await _appDatabase.removeAll();
      await _nftCollectionDatabase.removeAll();
      await _configurationService.removeAll();
      await injector<CacheManager>().emptyCache();
      await DefaultCacheManager().emptyCache();
      unawaited(injector<CloudManager>().deleteAll());
      injector<CloudManager>().clearCache();
      await injector<AccountService>().deleteAllKeys();
      await injector<HiveStoreObjectService<CanvasDevice>>().clear();
      await injector<AnnouncementStore>().clear();
      injector<CanvasDeviceBloc>().clear();
      injector<IAPService>().clearReceipt();
      injector<IAPService>().reset();

      await FileLogger.clear();
      await SentryBreadcrumbLogger.clear();

      _authService.reset();
      unawaited(injector<CacheManager>().emptyCache());
      unawaited(DefaultCacheManager().emptyCache());
      memoryValues = MemoryValues();

      emit(ForgetExistState(state.isChecked, false));
    });
  }
}
