//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  bool _isRename = false;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();
  late Connection _connection;
  late String _address;

  @override
  void initState() {
    super.initState();
    _connection = widget.payload.connection;
    _address = _connection.accountNumber;
    _renameController.text = _connection.name;
    isHideGalleryEnabled =
        injector<AccountService>().isLinkedAccountHiddenInGallery(_address);

    _callBloc();
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
    _callBloc();
  }

  void _callBloc() {
    final cryptoType = widget.payload.type;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, _address));
    if (cryptoType == CryptoType.ETH) {
      context.read<USDCBloc>().add(GetUSDCBalanceWithAddressEvent(_address));
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
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: _isRename
          ? getTitleEditAppBar(
              context,
              titleIcon: LogoCrypto(
                cryptoType: widget.payload.type,
                size: 24,
              ),
              icon: SvgPicture.asset(
                'assets/images/more_circle.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                    AppColor.disabledColor, BlendMode.srcIn),
              ),
              controller: _renameController,
              focusNode: _renameFocusNode,
              onSubmit: (String value) {
                if (value.trim().isNotEmpty) {
                  _connection = _connection.copyWith(name: value);
                  injector<CloudDatabase>()
                      .connectionDao
                      .updateConnection(_connection);
                  setState(() {
                    _isRename = false;
                  });
                }
              },
            )
          : getBackAppBar(
              context,
              title: _connection.name.maskIfNeeded(),
              titleIcon: LogoCrypto(
                cryptoType: widget.payload.type,
                size: 24,
              ),
              icon: SvgPicture.asset(
                'assets/images/more_circle.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                    AppColor.primaryBlack, BlendMode.srcIn),
              ),
              action: _showOptionDialog,
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
      body: Stack(
        children: [
          BlocConsumer<WalletDetailBloc, WalletDetailState>(
              listener: (context, state) async {},
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hideConnection
                        ? const SizedBox(height: 16)
                        : addTitleSpace(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 3000),
                      height: hideConnection ? 60 : null,
                      child: _balanceSection(
                          context, state.balance, state.balanceInUSD),
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
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 26, 0, 12),
                                              child: _erc20Tag(context),
                                            )
                                          : SizedBox(
                                              height: hideConnection ? 48 : 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          linkedBox(context, fontSize: 14)
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: padding,
                                        child: _addressSection(context),
                                      ),
                                      const SizedBox(height: 24),
                                      if (widget.payload.type ==
                                          CryptoType.ETH) ...[
                                        BlocBuilder<USDCBloc, USDCState>(
                                            builder: (context, state) {
                                          final usdcBalance =
                                              state.usdcBalances[_address];
                                          final balance = usdcBalance == null
                                              ? "-- USDC"
                                              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
                                          return Padding(
                                            padding: padding,
                                            child:
                                                _usdcBalance(context, balance),
                                          );
                                        })
                                      ],
                                      addDivider(),
                                      Padding(
                                        padding: padding,
                                        child: _txSection(context),
                                      ),
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
                  ],
                );
              }),
          if (_isRename)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              child: Container(),
            ),
        ],
      ),
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

  void _onRenameTap() {
    Navigator.of(context).pop();
    setState(() {
      _isRename = true;
      _renameFocusNode.requestFocus();
    });
  }

  Widget _usdcBalance(BuildContext context, String balance) {
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
              const SizedBox(width: 15),
              Text(
                "USDC",
                style: theme.textTheme.ppMori700Black14,
              ),
              const SizedBox(width: 10),
              _erc20Tag(context)
            ],
          ),
        ),
        rightWidget: Text(
          balance,
          style: balanceStyle,
        ),
        onTap: () {
          final payload = LinkedWalletDetailsPayload(
            connection: _connection,
            type: CryptoType.USDC,
            personaName: widget.payload.personaName,
          );
          Navigator.of(context)
              .pushNamed(AppRouter.linkedWalletDetailsPage, arguments: payload);
        });
  }

  Widget _erc20Tag(BuildContext context) {
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

  Widget _balanceSection(
      BuildContext context, String balance, String balanceInUSD) {
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
          final usdcBalance = state.usdcBalances[_address];
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

  Widget _addressSection(BuildContext context) {
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
            _address.mask(4),
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
                        Clipboard.setData(ClipboardData(text: _address));
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

  Widget _txSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TappableForwardRow(
        padding: EdgeInsets.zero,
        leftWidget: Text(
          "show_history".tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.inappWebviewPage,
            arguments:
                InAppWebViewPayload(_txURL(_address, widget.payload.type)),
          );
        },
      ),
    ]);
  }

  String _txURL(String address, CryptoType cryptoType) {
    switch (cryptoType) {
      case CryptoType.ETH:
        return "$etherScanUrl/address/$address";
      case CryptoType.XTZ:
        return "https://tzkt.io/$address/operations";
      case CryptoType.USDC:
        return "$etherScanUrl/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48?a=$address";
      default:
        return "";
    }
  }

  _showOptionDialog() {
    if (!mounted) return;
    UIHelper.showDrawerAction(context, options: [
      isHideGalleryEnabled
          ? OptionItem(
              title: 'unhide_from_collection_view'.tr(),
              icon: SvgPicture.asset(
                'assets/images/unhide.svg',
                colorFilter: const ColorFilter.mode(
                    AppColor.primaryBlack, BlendMode.srcIn),
              ),
              onTap: () {
                injector<AccountService>().setHideLinkedAccountInGallery(
                    _address, !isHideGalleryEnabled);
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
                    _address, !isHideGalleryEnabled);
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
      OptionItem(
        title: 'rename'.tr(),
        icon: SvgPicture.asset(
          'assets/images/rename_icon.svg',
          colorFilter:
              const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
        ),
        onTap: _onRenameTap,
      ),
      OptionItem(),
    ]);
  }
}

class LinkedWalletDetailsPayload {
  final Connection connection;
  final CryptoType type;
  final String personaName;

  LinkedWalletDetailsPayload({
    required this.connection,
    required this.type,
    required this.personaName,
  });
}
