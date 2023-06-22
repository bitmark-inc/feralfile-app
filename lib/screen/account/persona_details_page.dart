//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PersonaDetailsPage extends StatefulWidget {
  final Persona persona;

  const PersonaDetailsPage({Key? key, required this.persona}) : super(key: key);

  @override
  State<PersonaDetailsPage> createState() => _PersonaDetailsPageState();
}

class _PersonaDetailsPageState extends State<PersonaDetailsPage>
    with RouteAware {
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
  WalletType _walletTypeSelecting = WalletType.Ethereum;
  String? title;
  late Persona persona;
  late bool isDefaultWallet;

  @override
  void initState() {
    super.initState();
    persona = widget.persona;
    isDefaultWallet = persona.defaultAccount == 1;
    _callBloc(persona);

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
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: title?.replaceFirst('did:key:', '') ?? '',
        action: _showOptionDialog,
        icon: SvgPicture.asset(
          'assets/images/more_circle.svg',
          width: 22,
          color: AppColor.primaryBlack,
        ),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDefaultWallet
                ? Column(
                    children: [
                      const SizedBox(height: 30),
                      Padding(
                        padding: padding.copyWith(top: 0, bottom: 0),
                        child: _defaultAccount(context),
                      ),
                    ],
                  )
                : const SizedBox(
                    height: 16,
                  ),
            const SizedBox(height: 32),
            _addressesSection(context, uuid),
            const SizedBox(height: 16),
            _backupSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  _showOptionDialog() async {
    final theme = Theme.of(context);
    final walletAddresses =
        await injector<CloudDatabase>().addressDao.findByWalletID(persona.uuid);
    final isAllHidden =
        walletAddresses.every((element) => element.isHidden == true);
    if (!mounted) return;
    UIHelper.showDrawerAction(context, options: [
      isAllHidden
          ? OptionItem(
              title: 'unhide_all_from_collection_view'.tr(),
              icon: SvgPicture.asset(
                'assets/images/unhide.svg',
                color: AppColor.primaryBlack,
              ),
              onTap: () {
                Navigator.of(context).pop();
                setIsHiddenAll(walletAddresses, false);
              },
            )
          : OptionItem(
              title: 'hide_all_from_collection_view'.tr(),
              icon: const Icon(
                AuIcon.hidden_artwork,
                color: AppColor.primaryBlack,
              ),
              onTap: () {
                Navigator.of(context).pop();
                setIsHiddenAll(walletAddresses, true);
              },
            ),
      OptionItem(
        title: "add_address_to_wallet".tr(),
        icon: SvgPicture.asset("assets/images/joinFile.svg",
            color: AppColor.primaryBlack),
        onTap: () {
          Navigator.of(context).pop();
          UIHelper.showDialog(context, "add_address_to_wallet".tr(),
              StatefulBuilder(builder: (
            BuildContext dialogContext,
            StateSetter dialogState,
          ) {
            return Column(
              children: [
                _walletTypeOption(theme, WalletType.Ethereum, dialogState),
                addDivider(height: 40, color: AppColor.white),
                _walletTypeOption(theme, WalletType.Tezos, dialogState),
                const SizedBox(height: 40),
                Padding(
                  padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                  child: Column(
                    children: [
                      PrimaryButton(
                        text: "add_address".tr(),
                        onTap: () async {
                          Navigator.of(context).pop();
                          UIHelper.showScrollableDialog(
                            context,
                            BlocProvider.value(
                              value: context.read<ScanWalletBloc>(),
                              child: AddAddressToWallet(
                                addresses: const [],
                                importedAddress: await persona.getAddresses(),
                                walletType: _walletTypeSelecting,
                                wallet: persona.wallet(),
                                onImport: (addresses) async {
                                  Persona newPersona =
                                      await injector<AccountService>()
                                          .addAddressPersona(
                                              persona, addresses);
                                  setState(() {
                                    persona = newPersona;
                                    _callBloc(newPersona);
                                  });
                                },
                              ),
                            ),
                            isDismissible: true,
                          );
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
              paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets);
        },
      ),
      OptionItem(),
    ]);
  }

  Widget _addressesSection(BuildContext context, String uuid) {
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
        const SizedBox(height: 30),
        BlocBuilder<EthereumBloc, EthereumState>(builder: (context, state) {
          final ethAddresses = state.personaAddresses?[uuid];
          if (ethAddresses == null || ethAddresses.isEmpty) {
            return const SizedBox();
          }
          return Column(
              children: ethAddresses
                  .map((addressIndex) => [
                        _addressRow(context,
                            walletAddress: addressIndex,
                            balance: state.ethBalances[addressIndex.address] ==
                                    null
                                ? "-- ETH"
                                : "${EthAmountFormatter(state.ethBalances[addressIndex.address]!.getInWei).format()} ETH"),
                        addOnlyDivider(),
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
                .map((addressIndex) => [
                      _addressRow(
                        context,
                        walletAddress: addressIndex,
                        balance: state.balances[addressIndex.address] == null
                            ? "-- XTZ"
                            : "${XtzAmountFormatter(state.balances[addressIndex.address]!).format()} XTZ",
                      ),
                      addOnlyDivider(),
                    ])
                .flattened
                .toList(),
          );
        }),
      ],
    );
  }

  Future<void> setIsHiddenAll(
      List<WalletAddress> walletAddresses, bool isHide) async {
    final addresses = walletAddresses
        .where((element) => element.isHidden == !isHide)
        .toList()
        .map((e) => e.address)
        .toList();
    await injector<AccountService>().setHideAddressInGallery(addresses, isHide);
    _callBloc(persona);
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

  Widget _addressRow(BuildContext context,
      {required WalletAddress walletAddress, String balance = ""}) {
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.ppMori400Black14;
    final isHideGalleryEnabled = walletAddress.isHidden;
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dragDismissible: false,
        children: slidableActions(context, walletAddress),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: padding.copyWith(bottom: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(walletAddress.cryptoType,
                            style: theme.textTheme.ppMori700Black16),
                        const Expanded(child: SizedBox()),
                        if (isHideGalleryEnabled) ...[
                          SvgPicture.asset(
                            'assets/images/hide.svg',
                            color: theme.colorScheme.surface,
                          ),
                          const SizedBox(width: 10),
                        ],
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
                      walletAddress.address,
                      style: addressStyle,
                      key: const Key("fullAccount_address"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _backupSection(BuildContext context) {
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
              final didAuthenticate =
                  await LocalAuthenticationService.checkLocalAuth();

              if (!didAuthenticate) {
                return;
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

  List<CustomSlidableAction> slidableActions(
      BuildContext context, WalletAddress walletAddress) {
    final theme = Theme.of(context);
    final isHidden = walletAddress.isHidden;
    return [
      CustomSlidableAction(
        backgroundColor: AppColor.secondarySpanishGrey,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
          label: "${walletAddress.address}_hide",
          child: SvgPicture.asset(
              isHidden ? 'assets/images/unhide.svg' : 'assets/images/hide.svg'),
        ),
        onPressed: (_) {
          injector<AccountService>()
              .setHideAddressInGallery([walletAddress.address], !isHidden);
          _callBloc(persona);
        },
      ),
      if (!isDefaultWallet || walletAddress.index != 0) ...[
        CustomSlidableAction(
          backgroundColor: Colors.red,
          foregroundColor: theme.colorScheme.secondary,
          child: Semantics(
              label: "${walletAddress.address}_delete",
              child: SvgPicture.asset('assets/images/trash.svg')),
          onPressed: (_) async {
            await injector<AccountService>()
                .deleteAddressPersona(persona, walletAddress);
            _callBloc(persona);
            setState(() {});
          },
        )
      ]
    ];
  }
}
