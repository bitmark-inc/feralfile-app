//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/util/address_utils.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/feral_file_custom_tab.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
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

class LinkedWalletDetailPage extends StatefulWidget {
  const LinkedWalletDetailPage({required this.payload, super.key});

  final LinkedWalletDetailsPayload payload;

  @override
  State<LinkedWalletDetailPage> createState() => _LinkedWalletDetailPageState();
}

class _LinkedWalletDetailPageState extends State<LinkedWalletDetailPage>
    with RouteAware {
  late ScrollController controller;
  bool hideConnection = false;
  bool _isHideGalleryEnabled = false;

  bool _isRename = false;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();
  late WalletAddress _walletAddress;
  late String _address;
  final _browser = FeralFileBrowser();

  final usdcFormatter = USDCAmountFormatter();

  final _addressService = injector<AddressService>();

  @override
  void initState() {
    super.initState();
    _walletAddress = widget.payload.address;
    _address = _walletAddress.address;
    _renameController.text = _walletAddress.name;
    _isHideGalleryEnabled = _walletAddress.isHidden;

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
    final cryptoType = widget.payload.address.cryptoType;

    switch (cryptoType) {
      case CryptoType.ETH:
        context
            .read<WalletDetailBloc>()
            .add(WalletDetailBalanceEvent(cryptoType, _address));
      case CryptoType.XTZ:
        context
            .read<WalletDetailBloc>()
            .add(WalletDetailBalanceEvent(cryptoType, _address));
      default:
      // do nothing
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
    final cryptoType = widget.payload.address.cryptoType;
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: _isRename
          ? getTitleEditAppBar(
              context,
              titleIcon: LogoCrypto(
                cryptoType: widget.payload.address.cryptoType,
                size: 24,
              ),
              icon: SvgPicture.asset(
                'assets/images/more_circle.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                  AppColor.disabledColor,
                  BlendMode.srcIn,
                ),
              ),
              controller: _renameController,
              focusNode: _renameFocusNode,
              onSubmit: (String value) {
                if (value.trim().isNotEmpty) {
                  _walletAddress = _walletAddress.copyWith(name: value);
                  _addressService.insertAddress(
                    _walletAddress,
                    checkAddressDuplicated: false,
                  );
                  setState(() {
                    _isRename = false;
                  });
                }
              },
            )
          : getBackAppBar(
              context,
              title: _walletAddress.name.maskIfNeeded(),
              titleIcon: LogoCrypto(
                cryptoType: widget.payload.address.cryptoType,
                size: 24,
              ),
              icon: SvgPicture.asset(
                'assets/images/more_circle.svg',
                width: 22,
                colorFilter: const ColorFilter.mode(
                  AppColor.primaryBlack,
                  BlendMode.srcIn,
                ),
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
                    context,
                    state.balance,
                    state.balanceInUSD,
                  ),
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
                  ),
                ),
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
                                  if (cryptoType == CryptoType.USDC)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        26,
                                        0,
                                        12,
                                      ),
                                      child: _erc20Tag(context),
                                    )
                                  else
                                    SizedBox(
                                      height: hideConnection ? 48 : 16,
                                    ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: padding,
                                    child: _addressSection(context),
                                  ),
                                  const SizedBox(height: 24),
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
            ),
          ),
          if (_isRename)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              child: Container(),
            ),
        ],
      ),
    );
  }

  void _onRenameTap() {
    Navigator.of(context).pop();
    setState(() {
      _isRename = true;
      _renameFocusNode.requestFocus();
    });
  }

  Widget _erc20Tag(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(
          color: AppColor.auQuickSilver,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      onPressed: () {},
      child: Text('ERC-20', style: theme.textTheme.ppMori400Grey14),
    );
  }

  Widget _balanceSection(
    BuildContext context,
    String balance,
    String balanceInUSD,
  ) {
    final theme = Theme.of(context);
    final cryptoType = widget.payload.address.cryptoType;
    if (cryptoType == CryptoType.ETH || cryptoType == CryptoType.XTZ) {
      return SizedBox(
        child: Column(
          children: [
            Text(
              balance.isNotEmpty
                  ? balance
                  : '-- ${widget.payload.address.cryptoType.name}',
              style: hideConnection
                  ? theme.textTheme.ppMori400Black14.copyWith(fontSize: 24)
                  : theme.textTheme.ppMori400Black36,
            ),
            Text(
              balanceInUSD.isNotEmpty ? balanceInUSD : '-- USD',
              style: hideConnection
                  ? theme.textTheme.ppMori400Grey14
                  : theme.textTheme.ppMori400Grey16,
            ),
          ],
        ),
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
            _address.mask(4),
            style: theme.textTheme.ppMori400Black14,
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setState) => Container(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  //width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCopied
                          ? AppColor.feralFileHighlight
                          : AppColor.auLightGrey,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      side: BorderSide(
                        color:
                            isCopied ? Colors.transparent : AppColor.greyMedium,
                      ),
                      alignment: Alignment.center,
                    ),
                    onPressed: () {
                      if (isCopied) {
                        return;
                      }
                      showSimpleNotificationToast(
                        key: const Key('address'),
                        content: 'address_copied_to_clipboard'.tr(),
                      );
                      unawaited(
                        Clipboard.setData(ClipboardData(text: _address)),
                      );
                      setState(() {
                        isCopied = true;
                      });
                    },
                    child: isCopied
                        ? Text(
                            'copied'.tr(),
                            style: theme.textTheme.ppMori400Black14,
                          )
                        : Text(
                            'copy'.tr(),
                            style: theme.textTheme.ppMori400Grey14,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableForwardRow(
          padding: EdgeInsets.zero,
          leftWidget: Text(
            'show_history'.tr(),
            style: theme.textTheme.ppMori400Black14,
          ),
          onTap: () async {
            await _browser.openUrl(
              addressURL(_address, widget.payload.address.cryptoType),
            );
          },
        ),
      ],
    );
  }

  void _showOptionDialog() {
    if (!mounted) {
      return;
    }
    unawaited(
      UIHelper.showDrawerAction(
        context,
        options: [
          if (_isHideGalleryEnabled)
            OptionItem(
              title: 'unhide_from_collection_view'.tr(),
              icon: SvgPicture.asset(
                'assets/images/unhide.svg',
              ),
              onTap: () {
                unawaited(
                  _addressService.setHiddenStatus(
                    addresses: [_address],
                    isHidden: !_isHideGalleryEnabled,
                  ),
                );
                setState(() {
                  _isHideGalleryEnabled = !_isHideGalleryEnabled;
                });
                Navigator.of(context).pop();
              },
            )
          else
            OptionItem(
              title: 'hide_from_collection_view'.tr(),
              icon: const Icon(
                AuIcon.hidden_artwork,
                color: AppColor.white,
              ),
              onTap: () {
                unawaited(
                  _addressService.setHiddenStatus(
                    addresses: [_address],
                    isHidden: !_isHideGalleryEnabled,
                  ),
                );
                setState(() {
                  _isHideGalleryEnabled = !_isHideGalleryEnabled;
                });
                Navigator.of(context).pop();
              },
            ),
          OptionItem(
            title: 'rename'.tr(),
            icon: SvgPicture.asset(
              'assets/images/rename_icon.svg',
            ),
            onTap: _onRenameTap,
          ),
          OptionItem(),
        ],
      ),
    );
  }
}

class LinkedWalletDetailsPayload {
  LinkedWalletDetailsPayload({
    required this.address,
  });

  final WalletAddress address;
}
