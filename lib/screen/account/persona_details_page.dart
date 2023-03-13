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
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';

class PersonaDetailsPage extends StatefulWidget {
  final Persona persona;

  const PersonaDetailsPage({Key? key, required this.persona}) : super(key: key);

  @override
  State<PersonaDetailsPage> createState() => _PersonaDetailsPageState();
}

class _PersonaDetailsPageState extends State<PersonaDetailsPage>
    with RouteAware {
  bool isHideGalleryEnabled = false;
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
  WalletType _walletTypeSelecting = WalletType.Ethereum;
  String? title;
  late Persona persona;

  @override
  void initState() {
    super.initState();
    persona = widget.persona;
    _callBloc(persona);

    isHideGalleryEnabled =
        injector<AccountService>().isPersonaHiddenInGallery(persona.uuid);

    if (persona.name.isNotEmpty) {
      title = persona.name;
    } else {
      _getDidKey();
    }
  }

  _callBloc(Persona persona) {
    context
        .read<EthereumBloc>()
        .add(GetEthereumBalanceWithUUIDEvent(persona.uuid));

    context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(persona.uuid));
  }

  _getDidKey() async {
    final didKey = await persona.wallet().getAccountDID();
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
    final uuid = persona.uuid;
    context.read<EthereumBloc>().add(GetEthereumBalanceWithUUIDEvent(uuid));
    context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(uuid));
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    final uuid = persona.uuid;
    final isDefaultAccount = persona.defaultAccount == 1;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: title?.replaceFirst('did:key:', '') ?? '',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDefaultAccount
                ? Column(
                    children: [
                      const SizedBox(height: 30),
                      Padding(
                        padding: padding.copyWith(top: 0, bottom: 0),
                        child: _defaultAccount(context),
                      ),
                      if (injector<ConfigurationService>()
                          .getShowAuChainInfo()) ...[
                        const SizedBox(height: 30),
                        _importInfo(context),
                      ],
                    ],
                  )
                : const SizedBox(
                    height: 48,
                  ),
            const SizedBox(height: 32),
            _addressesSection(uuid),
            const SizedBox(height: 16),
            _preferencesSection(),
            addDivider(),
            const SizedBox(height: 16),
            _backupSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _importInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: ResponsiveLayout.pageHorizontalEdgeInsets,
      padding: const EdgeInsets.all(15.0),
      decoration: const BoxDecoration(
        color: AppColor.auSuperTeal,
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "info".tr(),
                style: theme.textTheme.ppMori700Black14,
              ),
              const Spacer(),
              GestureDetector(
                child: closeIcon(),
                onTap: () async {
                  await injector<ConfigurationService>()
                      .setShowAuChainInfo(false);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "generate_support_au".tr(),
            style: theme.textTheme.ppMori400Black14,
          ),
        ],
      ),
    );
  }

  Widget _addressesSection(String uuid) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Text(
            "addresses".tr(),
            style: theme.textTheme.ppMori400Black16,
          ),
        ),
        const SizedBox(height: 40),
        BlocBuilder<EthereumBloc, EthereumState>(builder: (context, state) {
          final ethAddresses = state.personaAddresses?[uuid];
          if (ethAddresses == null || ethAddresses.isEmpty) {
            return const SizedBox();
          }
          return Column(
              children: ethAddresses
                  .map((address) => [
                        _addressRow(
                            address: address,
                            index: ethAddresses.indexOf(address),
                            type: CryptoType.ETH,
                            balance: state.ethBalances[address] == null
                                ? "-- ETH"
                                : "${EthAmountFormatter(state.ethBalances[address]!.getInWei).format()} ETH"),
                        addDivider(),
                      ])
                  .flattened
                  .toList());
        }),
        BlocBuilder<TezosBloc, TezosState>(builder: (context, state) {
          final tezosAddress = state.personaAddresses?[uuid];
          if (tezosAddress == null || tezosAddress.isEmpty) {
            return const SizedBox();
          }
          return Column(
              children: tezosAddress
                  .map((address) => [
                        _addressRow(
                          address: address,
                          index: tezosAddress.indexOf(address),
                          type: CryptoType.XTZ,
                          balance: state.balances[address] == null
                              ? "-- XTZ"
                              : "${XtzAmountFormatter(state.balances[address]!).format()} XTZ",
                        ),
                        if (address != tezosAddress.last) addDivider(),
                      ])
                  .flattened
                  .toList());
        }),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: padding,
                child: PrimaryButton(
                  text: "add_address_to_wallet".tr(),
                  onTap: () {
                    UIHelper.showDialog(context, "add_address_to_wallet".tr(),
                        StatefulBuilder(builder: (
                      BuildContext context,
                      StateSetter dialogState,
                    ) {
                      return Column(
                        children: [
                          _walletTypeOption(
                              theme, WalletType.Ethereum, dialogState),
                          addDivider(height: 40, color: AppColor.white),
                          _walletTypeOption(
                              theme, WalletType.Tezos, dialogState),
                          const SizedBox(height: 40),
                          Padding(
                            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                            child: Column(
                              children: [
                                PrimaryButton(
                                  text: "add_address".tr(),
                                  onTap: () async {
                                    final newPersona =
                                        await injector<AccountService>()
                                            .addAddressPersona(
                                                persona, _walletTypeSelecting);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    setState(() {
                                      persona = newPersona;
                                      _callBloc(newPersona);
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                OutlineButton(
                                  onTap: () => Navigator.of(context).pop(),
                                  text: "cancel".tr(),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    }),
                        isDismissible: true,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        paddingTitle:
                            ResponsiveLayout.pageHorizontalEdgeInsets);
                  },
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 14),
        addDivider(),
      ],
    );
  }

  Widget _walletTypeOption(
      ThemeData theme, WalletType walletType, StateSetter dialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _walletTypeSelecting = walletType;
          });
          dialogState(() {});
        },
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              Text(
                walletType.getString(),
                style: theme.textTheme.ppMori400White14,
              ),
              const Spacer(),
              AuRadio<WalletType>(
                onTap: (value) {
                  setState(() {
                    _walletTypeSelecting = walletType;
                  });
                  dialogState(() {});
                },
                value: _walletTypeSelecting,
                groupValue: walletType,
                color: AppColor.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressRow(
      {required String address,
      required CryptoType type,
      required int index,
      String balance = ""}) {
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.ppMori400Black14;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(type.source,
                          style: theme.textTheme.ppMori700Black16),
                      const Expanded(child: SizedBox()),
                      Text(balance,
                          style: addressStyle.copyWith(
                              color: AppColor.auQuickSilver)),
                      const SizedBox(
                        width: 20,
                      ),
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
      ),
      onTap: () {
        final payload = WalletDetailsPayload(
          personaUUID: persona.uuid,
          address: address,
          type: type,
          wallet: LibAukDart.getWallet(persona.uuid),
          personaName: persona.name,
          index: index,
          //personaName: widget.persona.name,
        );
        Navigator.of(context)
            .pushNamed(AppRouter.walletDetailsPage, arguments: payload);
      },
    );
  }

  Widget _preferencesSection() {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "preferences".tr(),
          style: theme.textTheme.ppMori400Black16,
        ),
        const SizedBox(
          height: 24,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('hide_from_collection'.tr(),
                    style: theme.textTheme.ppMori400Black16),
                AuToggle(
                  value: isHideGalleryEnabled,
                  onToggle: (value) async {
                    await injector<AccountService>()
                        .setHidePersonaInGallery(persona.uuid, value);
                    if (!mounted) return;
                    setState(() {
                      isHideGalleryEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "do_not_show_nft".tr(),
              //"Do not show this account's NFTs in the collection view.",
              style: theme.textTheme.ppMori400Black14,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _backupSection() {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "backup".tr(),
            style: theme.textTheme.ppMori400Black16,
          ),
          const SizedBox(
            height: 14,
          ),
          TappableForwardRow(
            leftWidget: Text(
              'recovery_phrase'.tr(),
              style: theme.textTheme.ppMori400Black14,
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

              final words = await persona.wallet().exportMnemonicWords();

              if (!mounted) return;

              Navigator.of(context).pushNamed(AppRouter.recoveryPhrasePage,
                  arguments: words.split(" "));
            },
          ),
        ],
      ),
    );
  }

  Widget _defaultAccount(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColor.secondaryDimGreyBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AutoSizeText(
              "this_is_base_account".tr(),
              style: theme.textTheme.ppMori400Black14,
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
