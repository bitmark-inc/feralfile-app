//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nft_collection/nft_collection.dart';

class PersonaDetailsPage extends StatefulWidget {
  final Persona persona;

  const PersonaDetailsPage({Key? key, required this.persona}) : super(key: key);

  @override
  State<PersonaDetailsPage> createState() => _PersonaDetailsPageState();
}

class _PersonaDetailsPageState extends State<PersonaDetailsPage>
    with RouteAware {
  bool isHideGalleryEnabled = false;

  String? title;

  @override
  void initState() {
    super.initState();

    context
        .read<EthereumBloc>()
        .add(GetEthereumAddressEvent(widget.persona.uuid));

    context.read<TezosBloc>().add(GetTezosAddressEvent(widget.persona.uuid));

    context.read<USDCBloc>().add(GetAddressEvent(widget.persona.uuid));

    context
        .read<EthereumBloc>()
        .add(GetEthereumBalanceWithUUIDEvent(widget.persona.uuid));

    context
        .read<TezosBloc>()
        .add(GetTezosBalanceWithUUIDEvent(widget.persona.uuid));

    context
        .read<USDCBloc>()
        .add(GetUSDCBalanceWithUUIDEvent(widget.persona.uuid));

    isHideGalleryEnabled = injector<AccountService>()
        .isPersonaHiddenInGallery(widget.persona.uuid);

    if (widget.persona.name.isNotEmpty) {
      title = widget.persona.name;
    } else {
      _getDidKey();
    }
  }

  _getDidKey() async {
    final didKey = await widget.persona.wallet().getAccountDID();
    setState(() {
      title = didKey;
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final uuid = widget.persona.uuid;
    context.read<EthereumBloc>().add(GetEthereumBalanceWithUUIDEvent(uuid));
    context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(uuid));
    context.read<USDCBloc>().add(GetUSDCBalanceWithUUIDEvent(uuid));
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final uuid = widget.persona.uuid;
    final isDefaultAccount = widget.persona.defaultAccount == 1;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: title?.replaceFirst('did:key:', '') ?? '',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDefaultAccount
                ? Column(
                    children: [
                      const SizedBox(height: 30),
                      _defaultAccount(context),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox(),
            _addressesSection(uuid),
            const SizedBox(height: 40),
            _preferencesSection(),
            const SizedBox(height: 40),
            _backupSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _addressesSection(String uuid) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "addresses".tr(),
          style: theme.textTheme.headline1,
        ),
        const SizedBox(height: 24),
        BlocBuilder<EthereumBloc, EthereumState>(builder: (context, state) {
          final ethAddress = state.personaAddresses?[uuid];
          final ethBalance = state.ethBalances[ethAddress];
          final balance = ethBalance == null
              ? "-- ETH"
              : "${EthAmountFormatter(ethBalance.getInWei).format()} ETH";
          return _addressRow(
              address: state.personaAddresses?[uuid] ?? "",
              type: CryptoType.ETH,
              balance: balance);
        }),
        addDivider(),
        BlocBuilder<USDCBloc, USDCState>(builder: (context, state) {
          final usdcAddress = state.personaAddresses?[uuid];
          final usdcBalance = state.usdcBalances[usdcAddress];
          final balance = usdcBalance == null
              ? "-- USDC"
              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
          return _addressRow(
              address: state.personaAddresses?[uuid] ?? "",
              type: CryptoType.USDC,
              balance: balance);
        }),
        addDivider(),
        BlocBuilder<TezosBloc, TezosState>(builder: (context, state) {
          final tezosAddress = state.personaAddresses?[uuid];
          final xtzBalance = state.balances[tezosAddress];
          final balance = xtzBalance == null
              ? "-- XTZ"
              : "${XtzAmountFormatter(xtzBalance).format()} XTZ";
          return _addressRow(
            address: state.personaAddresses?[uuid] ?? "",
            type: CryptoType.XTZ,
            balance: balance,
          );
        }),
      ],
    );
  }

  Widget _addressRow(
      {required String address,
      required CryptoType type,
      String balance = ""}) {
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.subtitle1;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(type.source, style: theme.textTheme.headline4),
                    const Expanded(child: SizedBox()),
                    Text(balance, style: addressStyle),
                  ],
                ),
              ),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  style: addressStyle,
                  key: const Key("fullAccount_address"),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        final payload = PersonaConnectionsPayload(
          personaUUID: widget.persona.uuid,
          address: address,
          type: type,
          personaName: widget.persona.name,
        );
        Navigator.of(context)
            .pushNamed(AppRouter.personaConnectionsPage, arguments: payload);
      },
    );
  }

  Widget _preferencesSection() {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "preferences".tr(),
        style: theme.textTheme.headline1,
      ),
      const SizedBox(
        height: 14,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('hide_from_collection'.tr(),
                  style: theme.textTheme.headline4),
              CupertinoSwitch(
                value: isHideGalleryEnabled,
                onChanged: (value) async {
                  await injector<AccountService>()
                      .setHidePersonaInGallery(widget.persona.uuid, value);
                  final hiddenAddress =
                      await injector<AccountService>().getHiddenAddresses();
                  setState(() {
                    context
                        .read<NftCollectionBloc>()
                        .add(UpdateHiddenTokens(ownerAddresses: hiddenAddress));
                    isHideGalleryEnabled = value;
                  });
                },
                activeColor: theme.colorScheme.primary,
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "do_not_show_nft".tr(),
            //"Do not show this account's NFTs in the collection view.",
            style: theme.textTheme.bodyText1,
          ),
        ],
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _backupSection() {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "backup".tr(),
        style: theme.textTheme.headline1,
      ),
      const SizedBox(
        height: 8,
      ),
      TappableForwardRow(
          leftWidget: Text(
            'recovery_phrase'.tr(),
            style: theme.textTheme.headline4,
          ),
          onTap: () async {
            final configurationService = injector<ConfigurationService>();

            if (configurationService.isDevicePasscodeEnabled() &&
                await authenticateIsAvailable()) {
              final localAuth = LocalAuthentication();
              final didAuthenticate = await localAuth.authenticate(
                  localizedReason: "authen_for_autonomy".tr());
              if (!didAuthenticate) {
                return;
              }
            }

            final words = await widget.persona.wallet().exportMnemonicWords();

            if (!mounted) return;

            Navigator.of(context).pushNamed(AppRouter.recoveryPhrasePage,
                arguments: words.split(" "));
          }),
    ]);
  }

  Widget _defaultAccount(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: AppColor.secondaryDimGreyBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/iconInfo.svg",
            color: Colors.black,
            width: 16,
          ),
          const SizedBox(
            width: 6.5,
          ),
          Expanded(
            child: AutoSizeText(
              "this_is_base_account".tr(),
              style: theme.textTheme.headline5?.copyWith(fontSize: 14),
              maxFontSize: 14,
              minFontSize: 1,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
