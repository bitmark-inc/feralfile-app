//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:math';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/address_utils.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

class WalletDetailPage extends StatefulWidget {
  final WalletDetailsPayload payload;

  const WalletDetailPage({required this.payload, super.key});

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> with RouteAware {
  late ScrollController controller;
  bool hideConnection = false;
  bool hideSend = false;
  bool hideAddress = false;
  bool hideBalance = false;
  bool isHideGalleryEnabled = false;
  late String address;
  late WalletAddress walletAddress;
  bool _isRename = false;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();
  final usdcFormatter = USDCAmountFormatter();

  @override
  void initState() {
    super.initState();
    walletAddress = widget.payload.walletAddress;
    isHideGalleryEnabled = walletAddress.isHidden;
    _renameController.text = walletAddress.name ?? widget.payload.type.source;
    address = walletAddress.address;

    _callBlocWallet();
    controller = ScrollController();
    controller.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _callFetchConnections();
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
    _callBlocWallet();
    _callFetchConnections();
  }

  void _callBlocWallet() {
    final cryptoType = widget.payload.type;
    switch (cryptoType) {
      case CryptoType.ETH:
        context
            .read<WalletDetailBloc>()
            .add(WalletDetailBalanceEvent(cryptoType, address));
        context.read<USDCBloc>().add(GetUSDCBalanceWithAddressEvent(address));
        break;
      case CryptoType.XTZ:
        context
            .read<WalletDetailBloc>()
            .add(WalletDetailBalanceEvent(cryptoType, address));
        break;
      case CryptoType.USDC:
        context.read<USDCBloc>().add(GetUSDCBalanceWithAddressEvent(address));
        break;
      default:
        // do nothing
        break;
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

  void _callFetchConnections() {
    final personUUID = widget.payload.persona.uuid;
    final address = widget.payload.walletAddress.address;

    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<ConnectionsBloc>().add(GetETHConnectionsEvent(
            personUUID, widget.payload.walletAddress.index, address));
        break;
      case CryptoType.XTZ:
        context.read<ConnectionsBloc>().add(GetXTZConnectionsEvent(
            personUUID, widget.payload.walletAddress.index, address));
        break;
      default:
        // do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cryptoType = widget.payload.type;
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final showConnection = widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ;

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
                  walletAddress = walletAddress.copyWith(name: value);
                  unawaited(injector<AccountService>()
                      .updateAddressPersona(walletAddress));
                  setState(() {
                    _isRename = false;
                  });
                }
              },
            )
          : getBackAppBar(
              context,
              title: walletAddress.name ?? widget.payload.type.source,
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
              //showConnection ? _connectionIconTap : null,
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
      body: Stack(
        children: [
          BlocConsumer<WalletDetailBloc, WalletDetailState>(
              listener: (context, state) async {},
              builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hideConnection)
                        const SizedBox(height: 16)
                      else
                        addTitleSpace(),
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
                                    duration:
                                        const Duration(milliseconds: 3000),
                                    child: Column(
                                      children: [
                                        if (cryptoType == CryptoType.USDC)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 26, 0, 12),
                                            child: _erc20Tag(context),
                                          )
                                        else
                                          SizedBox(
                                              height: hideConnection ? 84 : 52),
                                        Padding(
                                          padding: padding,
                                          child: _addressSection(context),
                                        ),
                                        const SizedBox(height: 24),
                                        Padding(
                                          padding: padding,
                                          child: _sendReceiveSection(context),
                                        ),
                                        const SizedBox(height: 24),
                                        if (widget.payload.type ==
                                            CryptoType.ETH) ...[
                                          BlocBuilder<USDCBloc, USDCState>(
                                              builder: (context, state) {
                                            final address = widget
                                                .payload.walletAddress.address;
                                            final usdcBalance =
                                                state.usdcBalances[address];
                                            final balance = usdcBalance == null
                                                ? '-- USDC'
                                                : '''${usdcFormatter.format(usdcBalance)} USDC''';
                                            return Padding(
                                              padding: padding,
                                              child: _usdcBalance(balance),
                                            );
                                          })
                                        ],
                                        if (showConnection) ...[
                                          addDivider(),
                                          Padding(
                                            padding: padding,
                                            child: _connectionsSection(context),
                                          ),
                                          addDivider(),
                                          Padding(
                                            padding: padding,
                                            child: _recoverySection(context),
                                          ),
                                          addDivider(),
                                          Padding(
                                              padding: padding,
                                              child: _txSection(context)),
                                          addDivider(),
                                        ],
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
                  )),
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

    unawaited(Navigator.of(context)
        .popAndPushNamed(AppRouter.scanQRPage, arguments: scanItem));
  }

  void _onRenameTap() {
    Navigator.of(context).pop();
    setState(() {
      _isRename = true;
      _renameFocusNode.requestFocus();
    });
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
                'USDC',
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
          final payload = WalletDetailsPayload(
            type: CryptoType.USDC,
            persona: widget.payload.persona,
            walletAddress: walletAddress,
          );
          unawaited(Navigator.of(context)
              .pushNamed(AppRouter.walletDetailsPage, arguments: payload));
        });
  }

  Widget _erc20Tag(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
              balance.isNotEmpty ? balance : '-- ${widget.payload.type.name}',
              style: hideConnection
                  ? theme.textTheme.ppMori400Black14.copyWith(fontSize: 24)
                  : theme.textTheme.ppMori400Black36,
            ),
            Text(
              balanceInUSD.isNotEmpty ? balanceInUSD : '-- USD',
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
          final usdcBalance = state.usdcBalances[address];
          final balance = usdcBalance == null
              ? '-- USDC'
              : '${usdcFormatter.format(usdcBalance)} USDC';
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
            'your_address'.tr(),
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
            child: StatefulBuilder(
                builder: (context, setState) => Container(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCopied
                              ? AppColor.feralFileHighlight
                              : AppColor.auLightGrey,
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          side: BorderSide(
                            color: isCopied
                                ? Colors.transparent
                                : AppColor.greyMedium,
                          ),
                          alignment: Alignment.center,
                        ),
                        onPressed: () {
                          if (isCopied) {
                            return;
                          }
                          showInfoNotification(const Key('address'),
                              'address_copied_to_clipboard'.tr());
                          unawaited(
                              Clipboard.setData(ClipboardData(text: address)));
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
                    ))),
          ),
        ],
      ),
    );
  }

  Widget _connectionsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BlocBuilder<ConnectionsBloc, ConnectionsState>(builder: (context, state) {
        final connectionItems = state.connectionItems;
        //if (connectionItems == null) return const SizedBox();
        return TappableForwardRow(
          padding: EdgeInsets.zero,
          leftWidget: Text(
            'connections'.tr(),
            style: theme.textTheme.ppMori400Black14,
          ),
          rightWidget: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColor.auGrey),
            ),
            width: 24,
            height: 24,
            child: Text(
              '${connectionItems?.length ?? 0}',
              style: theme.textTheme.ppMori400Black14
                  .copyWith(color: AppColor.auGrey),
            ),
          ),
          onTap: () {
            final payload = PersonaConnectionsPayload(
              personaUUID: widget.payload.persona.uuid,
              index: walletAddress.index,
              address: address,
              type: widget.payload.type,
            );
            unawaited(Navigator.of(context).pushNamed(
                AppRouter.personaConnectionsPage,
                arguments: payload));
          },
        );
      }),
    ]);
  }

  Widget _txSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TappableForwardRow(
        padding: EdgeInsets.zero,
        leftWidget: Text(
          'show_history'.tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
        onTap: () {
          unawaited(Navigator.of(context).pushNamed(
            AppRouter.inappWebviewPage,
            arguments:
                InAppWebViewPayload(addressURL(address, widget.payload.type)),
          ));
        },
      ),
    ]);
  }

  Widget _recoverySection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TappableForwardRow(
        padding: EdgeInsets.zero,
        leftWidget: Text(
          'recovery_phrase'.tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
        onTap: () async {
          final words =
              await widget.payload.persona.wallet().exportMnemonicWords();
          if (!mounted) {
            return;
          }
          unawaited(Navigator.of(context).pushNamed(
              AppRouter.recoveryPhrasePage,
              arguments: words.split(' ')));
        },
      ),
    ]);
  }

  Widget _sendReceiveSection(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ ||
        widget.payload.type == CryptoType.USDC) {
      return Row(
        children: [
          Expanded(
            child: AuCustomButton(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/Send.svg',
                    width: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '${"send".tr()} ${widget.payload.type.name}',
                    style: theme.textTheme.ppMori400Black14,
                  ),
                ],
              ),
              onPressed: () async {
                final payload = await Navigator.of(context).pushNamed(
                    SendCryptoPage.tag,
                    arguments: SendData(
                        LibAukDart.getWallet(widget.payload.persona.uuid),
                        widget.payload.type,
                        null,
                        walletAddress.index)) as Map?;
                if (payload == null || !payload['isTezos']) {
                  return;
                }

                if (!mounted) {
                  return;
                }
                unawaited(UIHelper.showMessageAction(
                  context,
                  'success'.tr(),
                  'send_success_des'.tr(),
                  closeButton: 'close'.tr(),
                ));
              },
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: AuCustomButton(
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
                final account = Account(
                    key: address,
                    persona: widget.payload.persona,
                    name: walletAddress.name ?? widget.payload.type.source,
                    blockchain: widget.payload.type.source,
                    accountNumber: address,
                    createdAt: walletAddress.createdAt);
                unawaited(Navigator.of(context).pushNamed(
                    GlobalReceiveDetailPage.tag,
                    arguments: GlobalReceivePayload(
                        address: address,
                        blockchain: widget.payload.type.source,
                        account: account)));
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

  void _showOptionDialog() {
    if (!mounted) {
      return;
    }
    unawaited(UIHelper.showDrawerAction(context, options: [
      if (isHideGalleryEnabled)
        OptionItem(
          title: 'unhide_from_collection_view'.tr(),
          icon: SvgPicture.asset(
            'assets/images/unhide.svg',
            colorFilter:
                const ColorFilter.mode(AppColor.primaryBlack, BlendMode.srcIn),
          ),
          onTap: () {
            unawaited(injector<AccountService>()
                .setHideAddressInGallery([address], !isHideGalleryEnabled));
            setState(() {
              isHideGalleryEnabled = !isHideGalleryEnabled;
            });
            Navigator.of(context).pop();
          },
        )
      else
        OptionItem(
          title: 'hide_from_collection_view'.tr(),
          icon: const Icon(
            AuIcon.hidden_artwork,
            color: AppColor.primaryBlack,
          ),
          onTap: () {
            unawaited(injector<AccountService>()
                .setHideAddressInGallery([address], !isHideGalleryEnabled));
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
    ]));
  }
}

class WalletDetailsPayload {
  final CryptoType type;
  final Persona persona;
  final WalletAddress walletAddress;

  WalletDetailsPayload({
    required this.type,
    required this.persona,
    required this.walletAddress,
  });
}
