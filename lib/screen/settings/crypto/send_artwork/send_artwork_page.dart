//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';

class SendArtworkPage extends StatefulWidget {
  static const String tag = 'send_artwork';

  final SendArtworkPayload payload;

  const SendArtworkPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SendArtworkPage> createState() => _SendArtworkPageState();
}

class _SendArtworkPageState extends State<SendArtworkPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: "1");
  final feeWidgetKey = GlobalKey();
  final _reviewButtonVisible =
      ValueNotifier(!KeyboardVisibilityController().isVisible);

  bool _showAllFeeOption = false;
  bool _initialChangeAddress = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    context.read<SendArtworkBloc>().add(GetBalanceEvent(widget.payload.wallet));
    context.read<SendArtworkBloc>().add(QuantityUpdateEvent(
        quantity: 1, maxQuantity: widget.payload.ownedQuantity));
    if (widget.payload.asset.artistName != null) {
      context
          .read<IdentityBloc>()
          .add(GetIdentityEvent([widget.payload.asset.artistName!]));
    }

    KeyboardVisibilityController().onChange.listen((keyboardVisible) async {
      await Future.delayed(Duration(milliseconds: keyboardVisible ? 0 : 150),
          () => _reviewButtonVisible.value = !keyboardVisible);
    });
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _onQuantityUpdated();
      }
    });
  }

  int get _quantity {
    return int.tryParse(_quantityController.text) ?? 0;
  }

  void _updateQuantity({required bool isIncrease}) {
    FocusScope.of(context).unfocus();
    final newQuantity = _quantity + (isIncrease ? 1 : -1);
    _quantityController.text = "$newQuantity";
    _onQuantityUpdated();
  }

  void _onQuantityUpdated() {
    if (_quantity < 1) {
      _quantityController.text = "1";
    } else if (_quantity > widget.payload.ownedQuantity) {
      _quantityController.text = "${widget.payload.ownedQuantity}";
    }
    context.read<SendArtworkBloc>().add(QuantityUpdateEvent(
        quantity: _quantity, maxQuantity: widget.payload.ownedQuantity));
  }

  Widget _quantityInputField(
      {required int maxQuantity, required bool hasError}) {
    return Row(
      children: [
        IconButton(
            onPressed: () => _updateQuantity(isIncrease: false),
            icon: const Icon(
              Icons.remove,
              color: Colors.black,
            )),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 30, maxWidth: 90),
          child: IntrinsicWidth(
            child: TextField(
              focusNode: _focusNode,
              controller: _quantityController,
              decoration: const InputDecoration(border: InputBorder.none),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: "IBMPlexMono",
                  color: hasError ? const Color(0xFFa1200a) : Colors.black),
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              onSubmitted: (value) => _onQuantityUpdated(),
            ),
          ),
        ),
        IconButton(
            onPressed: () => _updateQuantity(isIncrease: true),
            icon: const Icon(
              Icons.add,
              color: Colors.black,
            )),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = widget.payload.asset;
    final maxQuantity = widget.payload.ownedQuantity;

    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        asset.artistName?.toIdentityOrMask(identityState.identityMap);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          BlocConsumer<SendArtworkBloc, SendArtworkState>(
              listener: (context, state) {
            if (state.fee != null && feeWidgetKey.currentContext != null) {
              Scrollable.ensureVisible(feeWidgetKey.currentContext!);
            }
            if (state.fee != null &&
                state.balance != null &&
                state.fee! > state.balance! + BigInt.from(10)) {
              UIHelper.showMessageAction(
                context,
                'transaction_failed'.tr(),
                'dont_enough_money'.tr(),
              );
            }
          }, builder: (context, state) {
            return Container(
              margin: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "send_artwork".tr(),
                            style: theme.textTheme.headline1,
                          ),
                          const SizedBox(height: 40.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "title".tr(),
                                style: theme.textTheme.headline4,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Text(
                                  asset.title,
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyText2,
                                ),
                              ),
                            ],
                          ),
                          if (artistName?.isNotEmpty == true) ...[
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "artist".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  artistName ?? "",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 32),
                          if (widget.payload.asset.fungible == true) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "owned_tokens".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  "$maxQuantity",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "quantity_to_send".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                Transform.translate(
                                  offset: const Offset(16, 0),
                                  child: _quantityInputField(
                                      maxQuantity: maxQuantity,
                                      hasError: state.isQuantityError),
                                )
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "edition".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  asset.editionSlashMax,
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16.0),
                          AuTextField(
                            title: "to".tr(),
                            placeholder: "paste_or_scan_address".tr(),
                            controller: _addressController,
                            isError: state.isAddressError,
                            suffix: IconButton(
                              icon: SvgPicture.asset(state.isScanQR
                                  ? "assets/images/iconQr.svg"
                                  : "assets/images/iconClose.svg"),
                              onPressed: () async {
                                if (_addressController.text.isNotEmpty) {
                                  _addressController.text = "";
                                  context
                                      .read<SendArtworkBloc>()
                                      .add(AddressChangedEvent(""));
                                  _initialChangeAddress = true;
                                } else {
                                  dynamic address = await Navigator.of(context)
                                      .pushNamed(ScanQRPage.tag,
                                          arguments:
                                              asset.blockchain == "ethereum"
                                                  ? ScannerItem.ETH_ADDRESS
                                                  : ScannerItem.XTZ_ADDRESS);
                                  if (address != null && address is String) {
                                    address =
                                        address.replacePrefix("ethereum:", "");
                                    _addressController.text = address;
                                    if (!mounted) return;
                                    context
                                        .read<SendArtworkBloc>()
                                        .add(AddressChangedEvent(address));
                                    _initialChangeAddress = true;
                                  }
                                }
                              },
                            ),
                            onSubmit: (value) {
                              if (value != state.address) {
                                context.read<SendArtworkBloc>().add(
                                      AddressChangedEvent(
                                        _addressController.text,
                                      ),
                                    );
                                _initialChangeAddress = true;
                              }
                            },
                          ),
                          const SizedBox(height: 16.0),
                          gasFeeStatus(state, theme),
                          const SizedBox(height: 8.0),
                          if (state.feeOptionValue != null)
                            feeTable(state, context),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                      valueListenable: _reviewButtonVisible,
                      builder: (context, visible, child) {
                        return Visibility(
                          visible: visible,
                          child: _reviewButton(asset, state),
                        );
                      }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _reviewButton(AssetToken asset, SendArtworkState state) {
    return Row(
      children: [
        Expanded(
          child: AuFilledButton(
            text: "review".tr(),
            onPress: state.isValid
                ? () async {
                    final payload = await Navigator.of(context).pushNamed(
                        AppRouter.sendArtworkReviewPage,
                        arguments: SendArtworkReviewPayload(
                            asset,
                            widget.payload.wallet,
                            state.address!,
                            state.fee!,
                            state.exchangeRate,
                            widget.payload.ownedQuantity,
                            state.quantity,
                            state.feeOption,
                            state.feeOptionValue!)) as Map?;
                    if (payload != null &&
                        payload["hash"] != null &&
                        payload["hash"] is String) {
                      if (!mounted) return;
                      Navigator.of(context).pop(payload);
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget gasFeeStatus(SendArtworkState state, ThemeData theme) {
    if (_initialChangeAddress && state.feeOptionValue == null) {
      return Text("gas_fee_calculating".tr(), style: theme.textTheme.headline5);
    }
    if (state.feeOptionValue != null && state.balance != null) {
      bool isValid = state.balance! >
          state.feeOptionValue!.getFee(state.feeOption) + BigInt.from(10);
      if (isValid) {
        return Text("gas_fee".tr(), style: theme.textTheme.headline5);
      } else {
        return Text("gas_fee_insufficient".tr(),
            style: theme.textTheme.headline5?.copyWith(
              color: AppColor.red,
            ));
      }
    }
    return const SizedBox();
  }

  Widget feeTable(SendArtworkState state, BuildContext context) {
    final theme = Theme.of(context);
    final feeOption = state.feeOption;
    if (!_showAllFeeOption) {
      return Row(
        children: [
          Text(feeOption.name, style: theme.textTheme.atlasBlackBold12),
          const Spacer(),
          Text(_gasFee(state), style: theme.textTheme.atlasBlackBold12),
          const SizedBox(
            width: 56,
            height: 24,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllFeeOption = true;
              });
            },
            child: Text("edit_priority".tr(),
                style: theme.textTheme.linkStyle
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 12)),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          getFeeRow(FeeOption.LOW, state, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.MEDIUM, state, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.HIGH, state, theme),
        ],
      );
    }
  }

  Widget getFeeRow(
      FeeOption feeOption, SendArtworkState state, ThemeData theme) {
    final isSelected = feeOption == state.feeOption;
    final textStyle = isSelected
        ? theme.textTheme.atlasBlackBold12
        : theme.textTheme.atlasBlackNormal12;
    return Row(
      children: [
        Text(feeOption.name, style: textStyle),
        const Spacer(),
        Text(_gasFee(state, feeOption: feeOption), style: textStyle),
        const SizedBox(width: 56),
        GestureDetector(
          onTap: () {
            context.read<SendArtworkBloc>().add(FeeOptionChangedEvent(
                feeOption, state.address ?? "", state.quantity));
          },
          child: SvgPicture.asset(isSelected
              ? "assets/images/radio_btn_selected.svg"
              : "assets/images/radio_btn_not_selected.svg"),
        ),
      ],
    );
  }

  String _gasFee(SendArtworkState state, {FeeOption? feeOption}) {
    final type = widget.payload.asset.blockchain == "ethereum"
        ? CryptoType.ETH
        : CryptoType.XTZ;
    if (state.feeOptionValue == null) return type.code;
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    switch (type) {
      case CryptoType.ETH:
        return "${EthAmountFormatter(fee, digit: 7).format()} ETH (${state.exchangeRate.ethToUsd(fee)} USD)";
      case CryptoType.XTZ:
        return "${XtzAmountFormatter(fee.toInt()).format()} XTZ (${state.exchangeRate.xtzToUsd(fee.toInt())} USD)";
      default:
        return "";
    }
  }
}

class SendArtworkPayload {
  final AssetToken asset;
  final WalletStorage wallet;
  final int ownedQuantity;

  SendArtworkPayload(this.asset, this.wallet, this.ownedQuantity);
}
