//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LinkedWalletDetailPage extends StatefulWidget {
  final LinkedWalletDetailsPayload payload;

  const LinkedWalletDetailPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<LinkedWalletDetailPage> createState() => _LinkedWalletDetailPageState();
}

class _LinkedWalletDetailPageState extends State<LinkedWalletDetailPage>
    with RouteAware {
  late ScrollController controller;
  bool hideConnection = false;
  bool isHideGalleryEnabled = false;

  @override
  void initState() {
    super.initState();
    isHideGalleryEnabled = injector<AccountService>()
        .isLinkedAccountHiddenInGallery(widget.payload.address);

    context.read<AccountsBloc>().add(FindLinkedAccount(
        widget.payload.connectionKey,
        widget.payload.address,
        widget.payload.type));
    switch (widget.payload.type) {
      case CryptoType.ETH:
        context
            .read<EthereumBloc>()
            .add(GetEthereumBalanceWithAddressEvent([widget.payload.address]));
        context
            .read<USDCBloc>()
            .add(GetUSDCBalanceWithAddressEvent(widget.payload.address));
        break;
      case CryptoType.XTZ:
        context
            .read<TezosBloc>()
            .add(GetTezosBalanceWithAddressEvent([widget.payload.address]));
        break;
      case CryptoType.USDC:
        context
            .read<USDCBloc>()
            .add(GetUSDCBalanceWithAddressEvent(widget.payload.address));
        break;
      case CryptoType.UNKNOWN:
        // do nothing
        break;
    }
    controller = ScrollController();
    controller.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    final cryptoType = widget.payload.type;
    final address = widget.payload.address;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, address));
    if (cryptoType == CryptoType.ETH) {
      context.read<USDCBloc>().add(GetUSDCBalanceWithAddressEvent(address));
    }
  }

  void _listener() {
    if (controller.offset > 0) {
      setState(() {
        hideConnection = true;
      });
    } else {
      setState(() {
        hideConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cryptoType = widget.payload.type;
    final address = widget.payload.address;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, address));
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.payload.type.name,
        icon: SvgPicture.asset(
          'assets/images/more_circle.svg',
          width: 22,
          color: AppColor.primaryBlack,
        ),
        action: _showOptionDialog,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<WalletDetailBloc, WalletDetailState>(
          listener: (context, state) async {},
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hideConnection ? const SizedBox(height: 16) : addTitleSpace(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 3000),
                  height: hideConnection ? 60 : null,
                  child: _balanceSection(state.balance, state.balanceInUSD),
                ),
                Visibility(
                    visible: hideConnection,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        addOnlyDivider(),
                      ],
                    )),
                Expanded(
                  child: CustomScrollView(
                    controller: controller,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 3000),
                              child: Column(
                                children: [
                                  cryptoType == CryptoType.USDC
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 26, 0, 12),
                                          child: _erc20Tag(),
                                        )
                                      : SizedBox(
                                          height: hideConnection ? 48 : 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      linkedBox(context, fontSize: 14)
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: padding,
                                    child: _addressSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: padding,
                                    child: _sendReceiveSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  if (widget.payload.type ==
                                      CryptoType.ETH) ...[
                                    BlocBuilder<USDCBloc, USDCState>(
                                        builder: (context, state) {
                                      final address = widget.payload.address;
                                      final usdcBalance =
                                          state.usdcBalances[address];
                                      final balance = usdcBalance == null
                                          ? "-- USDC"
                                          : "${USDCAmountFormatter(usdcBalance).format()} USDC";
                                      return Padding(
                                        padding: padding,
                                        child: _usdcBalance(balance),
                                      );
                                    })
                                  ],
                                  addDivider(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                widget.payload.type == CryptoType.XTZ
                    ? GestureDetector(
                        onTap: () =>
                            launchUrlString(_txURL(widget.payload.address)),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.fromLTRB(0, 17, 0, 20),
                          color: AppColor.secondaryDimGreyBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("powered_by_tzkt".tr(),
                                  style: theme.textTheme.ppMori400Black14),
                              const SizedBox(
                                width: 8,
                              ),
                              SvgPicture.asset(
                                  "assets/images/external_link.svg"),
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ],
            );
          }),
    );
  }

  void _connectionIconTap() {
    late ScannerItem scanItem;

    switch (widget.payload.type) {
      case CryptoType.ETH:
        scanItem = ScannerItem.WALLET_CONNECT;
        break;
      case CryptoType.XTZ:
        scanItem = ScannerItem.BEACON_CONNECT;
        break;
      default:
        break;
    }

    Navigator.of(context)
        .popAndPushNamed(AppRouter.scanQRPage, arguments: scanItem);
  }

  Widget _usdcBalance(String balance) {
    final theme = Theme.of(context);
    final balanceStyle = theme.textTheme.ppMori400White14
        .copyWith(color: AppColor.auQuickSilver);
    return TappableForwardRow(
        padding: EdgeInsets.zero,
        leftWidget: Container(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/usdc.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 35),
              Text(
                "USDC",
                style: theme.textTheme.ppMori700Black14,
              ),
              const SizedBox(width: 10),
              _erc20Tag()
            ],
          ),
        ),
        rightWidget: Text(
          balance,
          style: balanceStyle,
        ),
        onTap: () {
          final payload = LinkedWalletDetailsPayload(
            connectionKey: widget.payload.connectionKey,
            type: CryptoType.USDC,
            address: widget.payload.address,
            personaName: widget.payload.personaName,
          );
          Navigator.of(context)
              .pushNamed(AppRouter.linkedWalletDetailsPage, arguments: payload);
        });
  }

  Widget _erc20Tag() {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          side: const BorderSide(
            color: AppColor.auQuickSilver,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15)),
      onPressed: () {},
      child: Text('ERC-20', style: theme.textTheme.ppMori400Grey14),
    );
  }

  Widget _balanceSection(String balance, String balanceInUSD) {
    final theme = Theme.of(context);
    if (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ) {
      return SizedBox(
        child: Column(
          children: [
            Text(
              balance.isNotEmpty ? balance : "-- ${widget.payload.type.name}",
              style: hideConnection
                  ? theme.textTheme.ppMori400Black14.copyWith(fontSize: 24)
                  : theme.textTheme.ppMori400Black36,
            ),
            Text(
              balanceInUSD.isNotEmpty ? balanceInUSD : "-- USD",
              style: hideConnection
                  ? theme.textTheme.ppMori400Grey14
                  : theme.textTheme.ppMori400Grey16,
            )
          ],
        ),
      );
    }

    if (widget.payload.type == CryptoType.USDC) {
      return BlocBuilder<USDCBloc, USDCState>(
        builder: (context, state) {
          final usdcBalance = state.usdcBalances[widget.payload.address];
          final balance = usdcBalance == null
              ? "-- USDC"
              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
          return SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(balance, style: theme.textTheme.ppMori400Black36),
              ],
            ),
          );
        },
      );
    }
    return Container();
  }

  Widget _addressSection() {
    var address = widget.payload.address;
    final theme = Theme.of(context);
    bool isCopied = false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColor.auLightGrey,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Row(
        children: [
          Text(
            "your_address".tr(),
            style: theme.textTheme.ppMori400Grey14,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            address.mask(4),
            style: theme.textTheme.ppMori400Black14,
          ),
          Expanded(
            child: StatefulBuilder(builder: (context, setState) {
              return Container(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    //width: double.infinity,
                    height: 28.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCopied
                            ? AppColor.auSuperTeal
                            : AppColor.auLightGrey,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        side: BorderSide(
                          color: isCopied
                              ? Colors.transparent
                              : AppColor.greyMedium,
                        ),
                        alignment: Alignment.center,
                      ),
                      onPressed: () {
                        if (isCopied) return;
                        showInfoNotification(const Key("address"),
                            "address_copied_to_clipboard".tr());
                        Clipboard.setData(ClipboardData(text: address));
                        setState(() {
                          isCopied = true;
                        });
                      },
                      child: isCopied
                          ? Text(
                              'copied'.tr(),
                              style: theme.textTheme.ppMori400Black14,
                            )
                          : Text('copy'.tr(),
                              style: theme.textTheme.ppMori400Grey14),
                    ),
                  ));
            }),
          ),
        ],
      ),
    );
  }

  String _txURL(String address) {
    return "https://tzkt.io/$address/operations";
  }

  Widget _sendReceiveSection() {
    final theme = Theme.of(context);
    if (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ ||
        widget.payload.type == CryptoType.USDC) {
      return Row(
        children: [
          Expanded(
            child: BlocConsumer<AccountsBloc, AccountsState>(
              listener: (context, accountState) async {},
              builder: (context, accountState) {
                final account = accountState.accounts?.firstWhere((element) =>
                    element.blockchain == widget.payload.type.source);
                final blockChain =
                    (widget.payload.type.source == CryptoType.USDC.source)
                        ? CryptoType.ETH.source
                        : widget.payload.type.source;
                return AuCustomButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: pi,
                        child: SvgPicture.asset(
                          'assets/images/Recieve.svg',
                          width: 18,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${"receive".tr()} ${widget.payload.type.name}',
                        style: theme.textTheme.ppMori400Black14,
                      ),
                    ],
                  ),
                  onPressed: () {
                    if (account != null && account.accountNumber.isNotEmpty) {
                      Navigator.of(context).pushNamed(
                          GlobalReceiveDetailPage.tag,
                          arguments: GlobalReceivePayload(
                              address: widget.payload.address,
                              blockchain: blockChain,
                              account: account));
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    }
    return const SizedBox(
      height: 10,
    );
  }

  _showOptionDialog() {
    if (!mounted) return;
    UIHelper.showDrawerAction(context, options: [
      isHideGalleryEnabled
          ? OptionItem(
              title: 'unhide_from_collection_view'.tr(),
              icon: SvgPicture.asset(
                'assets/images/unhide.svg',
                color: AppColor.primaryBlack,
              ),
              onTap: () {
                injector<AccountService>().setHideLinkedAccountInGallery(
                    widget.payload.address, !isHideGalleryEnabled);
                setState(() {
                  isHideGalleryEnabled = !isHideGalleryEnabled;
                });
                Navigator.of(context).pop();
              },
            )
          : OptionItem(
              title: 'hide_from_collection_view'.tr(),
              icon: const Icon(
                AuIcon.hidden_artwork,
                color: AppColor.primaryBlack,
              ),
              onTap: () {
                injector<AccountService>().setHideLinkedAccountInGallery(
                    widget.payload.address, !isHideGalleryEnabled);
                setState(() {
                  isHideGalleryEnabled = !isHideGalleryEnabled;
                });
                Navigator.of(context).pop();
              },
            ),
      OptionItem(
        title: 'scan'.tr(),
        icon: const Icon(
          AuIcon.scan,
          color: AppColor.primaryBlack,
        ),
        onTap: _connectionIconTap,
      ),
      OptionItem(),
    ]);
  }
}

class LinkedWalletDetailsPayload {
  final String connectionKey;
  final CryptoType type;
  final String address;
  final String personaName;

  LinkedWalletDetailsPayload({
    required this.connectionKey,
    required this.type,
    required this.address,
    required this.personaName,
  });
}
