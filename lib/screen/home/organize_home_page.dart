//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_screen.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';

class OrganizeHomePage extends StatefulWidget {
  const OrganizeHomePage({super.key});

  @override
  State<OrganizeHomePage> createState() => OrganizeHomePageState();
}

class OrganizeHomePageState extends State<OrganizeHomePage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<OrganizeHomePage>,
        AutomaticKeepAliveClientMixin {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;

  final collectionProKey = GlobalKey<CollectionProState>();

  final _clientTokenService = injector<ClientTokenService>();
  final _configurationService = injector<ConfigurationService>();

  final nftBloc = injector<ClientTokenService>().nftBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    unawaited(injector<IAPService>().setup());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    unawaited(_fgbgSubscription?.cancel());
    _controller.dispose();
    super.dispose();
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
        final payload = PostcardDetailPagePayload(tokenMints.first);
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

    return Scaffold(
      appBar: getDarkEmptyAppBar(Colors.transparent),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColor.primaryBlack,
      body: contentWidget,
    );
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
  }

  @override
  bool get wantKeepAlive => true;
}
