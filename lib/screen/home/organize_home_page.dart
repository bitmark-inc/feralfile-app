//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_screen.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/locale_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<HomePage>,
        AutomaticKeepAliveClientMixin {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  late MetricClientService _metricClient;

  final collectionProKey = GlobalKey<CollectionProState>();

  Future<List<AddressIndex>> getAddressIndexes() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddressIndexes();
  }

  Future<List<String>> getAddresses() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddresses();
  }

  final _clientTokenService = injector<ClientTokenService>();
  final _configurationService = injector<ConfigurationService>();

  final nftBloc = injector<ClientTokenService>().nftBloc;

  @override
  void initState() {
    super.initState();
    _metricClient = injector.get<MetricClientService>();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    NftCollectionBloc.eventController.stream.listen((event) async {
      switch (event.runtimeType) {
        case ReloadEvent:
        case GetTokensByOwnerEvent:
        case UpdateTokensEvent:
        case GetTokensBeforeByOwnerEvent:
          nftBloc.add(event);
          break;
        default:
      }
    });
    unawaited(
        _clientTokenService.refreshTokens(syncAddresses: true).then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    }));

    context.read<HomeBloc>().add(CheckReviewAppEvent());

    unawaited(injector<IAPService>().setup());
    memoryValues.inGalleryView = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(_handleForeground());
    unawaited(injector<AutonomyService>().postLinkedAddresses());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    unawaited(_fgbgSubscription?.cancel());
    _controller.dispose();
    super.dispose();
  }

  @override
  Future<void> didPopNext() async {
    super.didPopNext();
    final connectivityResult = await Connectivity().checkConnectivity();
    unawaited(_clientTokenService.refreshTokens());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!mounted) {
          return;
        }
        nftBloc
            .add(RequestIndexEvent(await _clientTokenService.getAddresses()));
      });
    }
    memoryValues.inGalleryView = true;
  }

  @override
  void didPushNext() {
    memoryValues.inGalleryView = false;
    super.didPushNext();
  }

  Future<void> _onTokensUpdate(List<CompactedAssetToken> tokens) async {
    //check minted postcard and navigator to artwork detail
    final config = injector.get<ConfigurationService>();
    final listTokenMints = config.getListPostcardMint();
    if (tokens.any((element) =>
        listTokenMints.contains(element.id) && element.pending != true)) {
      final tokenMints = tokens
          .where(
            (element) =>
                listTokenMints.contains(element.id) && element.pending != true,
          )
          .map((e) => e.identity)
          .toList();
      if (config.isAutoShowPostcard()) {
        log.info('Auto show minted postcard');
        final payload = PostcardDetailPagePayload(tokenMints, 0);
        unawaited(Navigator.of(context).pushNamed(
          AppRouter.claimedPostcardDetailsPage,
          arguments: payload,
        ));
      }

      unawaited(config.setListPostcardMint(
        tokenMints.map((e) => e.id).toList(),
        isRemoved: true,
      ));
    }

    // Check if there is any Tezos token in the list
    List<String> allAccountNumbers = await injector<AccountService>()
        .getAllAddresses(logHiddenAddress: true);
    final hashedAddresses = allAccountNumbers.fold(
        0, (int previousValue, element) => previousValue + element.hashCode);

    if (_configurationService.sentTezosArtworkMetricValue() !=
            hashedAddresses &&
        tokens.any((asset) =>
            asset.blockchain == Blockchain.TEZOS.name.toLowerCase())) {
      unawaited(_metricClient.addEvent('collection_has_tezos'));
      unawaited(
          _configurationService.setSentTezosArtworkMetric(hashedAddresses));
    }
  }

  List<CompactedAssetToken> _updateTokens(List<CompactedAssetToken> tokens) {
    tokens = tokens.filterAssetToken();
    final nextKey = nftBloc.state.nextKey;
    if (nextKey != null &&
        !nextKey.isLoaded &&
        tokens.length < COLLECTION_INITIAL_MIN_SIZE) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
    }
    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final contentWidget =
        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
      bloc: nftBloc,
      builder: (context, state) => CollectionPro(
        key: collectionProKey,
        tokens: _updateTokens(state.tokens.items),
        scrollController: _controller,
      ),
      listener: (context, state) async {
        log.info('[NftCollectionBloc] State update $state');
        collectionProKey.currentState?.loadCollection();
        if (state.state == NftLoadingState.done) {
          unawaited(_onTokensUpdate(state.tokens.items));
        }
      },
    );

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
        appBar: getDarkEmptyAppBar(),
        backgroundColor: AppColor.primaryBlack,
        body: contentWidget,
      ),
    );
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
  }

  Future<void> _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        unawaited(_handleForeground());
        break;
      case FGBGType.background:
        break;
    }
  }

  Future _checkTipCardShowTime() async {
    final metricClient = injector<MetricClientService>();
    log.info('_checkTipCardShowTime');
    final configurationService = injector<ConfigurationService>();

    final doneOnboardingTime = configurationService.getDoneOnboardingTime();

    final now = DateTime.now();

    final remindTime = configurationService.getShowBackupSettingTip();
    final shouldRemindNow = remindTime == null || now.isAfter(remindTime);
    if (shouldRemindNow) {
      unawaited(configurationService
          .setShowBackupSettingTip(now.add(const Duration(days: 7))));
      bool showTip = false;
      if (Platform.isAndroid) {
        final isAndroidEndToEndEncryptionAvailable =
            await injector<AccountService>()
                .isAndroidEndToEndEncryptionAvailable();
        showTip = isAndroidEndToEndEncryptionAvailable != true;
      } else {
        final iCloudAvailable = injector<CloudService>().isAvailableNotifier;
        showTip = !iCloudAvailable.value;
      }
      if (showTip && !configurationService.showBackupSettingTip.value) {
        configurationService.showBackupSettingTip.value = true;
        unawaited(metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {'title': 'backup_failed'.tr()}));
      }
    }
    if (doneOnboardingTime != null) {
      if (now.isAfter(doneOnboardingTime.add(const Duration(hours: 24))) &&
          !configurationService.getAlreadyShowLinkOrImportTip()) {
        configurationService.showLinkOrImportTip.value = true;
        unawaited(configurationService.setAlreadyShowLinkOrImportTip(true));
        unawaited(metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {'title': 'do_you_have_NFTs_in_other_wallets'.tr()}));
      }
    }
  }

  Future<void> _handleForeground() async {
    final locale = Localizations.localeOf(context);
    unawaited(LocaleService.refresh(locale));
    memoryValues.inForegroundAt = DateTime.now();
    await injector<ConfigurationService>().reload();
    await _checkTipCardShowTime();
    try {
      await injector<SettingsDataService>().restoreSettingsData();
    } catch (exception) {
      if (exception is DioException && exception.response?.statusCode == 404) {
        // if there is no backup, upload one.
        await injector<SettingsDataService>().backup();
      } else {
        unawaited(Sentry.captureException(exception));
      }
    }

    unawaited(_clientTokenService.refreshTokens(checkPendingToken: true));
    unawaited(_metricClient.addEvent('device_foreground'));
    unawaited(injector<VersionService>().checkForUpdate());
    // Reload token in Isolate
  }

  @override
  bool get wantKeepAlive => true;
}
