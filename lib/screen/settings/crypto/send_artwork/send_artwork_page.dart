//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

class SendArtworkPage extends StatefulWidget {
  static const String tag = 'send_artwork';

  final SendArtworkPayload payload;

  const SendArtworkPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SendArtworkPage> createState() => _SendArtworkPageState();
}

class _SendArtworkPageState extends State<SendArtworkPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final feeWidgetKey = GlobalKey();

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
              enabled: maxQuantity > 1,
              onChanged: (_) => _onQuantityUpdated(),
            ),
          ),
        ),
        IconButton(
            onPressed: () =>
                maxQuantity > 1 ? _updateQuantity(isIncrease: true) : null,
            icon: const Icon(
              Icons.add,
              color: Colors.black,
            )),
      ],
    );
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
            if (state.fee != null) {
              Scrollable.ensureVisible(feeWidgetKey.currentContext!);
            }
          }, builder: (context, state) {
            return Container(
              margin: EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.of(context).padding.bottom),
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
                            children: [
                              Text(
                                "title".tr(),
                                style: theme.textTheme.headline4,
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
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "quantity_to_send".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                if (maxQuantity > 1) ...[
                                  _quantityInputField(maxQuantity: maxQuantity,
                                      hasError: state.isQuantityError)
                                ] else ...[
                                  const Text("1")
                                ],
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
                                  "${asset.edition}/${asset.maxEdition}",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32.0),
                          AuTextField(
                            title: "to".tr(),
                            placeholder: "paste_or_scan_address".tr(),
                            controller: _addressController,
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
                                } else {
                                  dynamic address = await Navigator.of(context)
                                      .pushNamed(ScanQRPage.tag,
                                          arguments:
                                              asset.blockchain == "ethereum"
                                                  ? ScannerItem.ETH_ADDRESS
                                                  : ScannerItem.XTZ_ADDRESS);
                                  if (address != null && address is String) {
                                    _addressController.text = address;
                                    if (!mounted) return;
                                    context
                                        .read<SendArtworkBloc>()
                                        .add(AddressChangedEvent(address));
                                  }
                                }
                              },
                            ),
                            onChanged: (value) {
                              context.read<SendArtworkBloc>().add(
                                  AddressChangedEvent(_addressController.text));
                            },
                          ),
                          const SizedBox(height: 8.0),
                          Text(_gasFee(state),
                              key: feeWidgetKey,
                              style: theme.textTheme.headline5),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "review".tr(),
                          onPress: state.isValid
                              ? () async {
                                  final txHash = await Navigator.of(context)
                                      .pushNamed(
                                          AppRouter.sendArtworkReviewPage,
                                          arguments: SendArtworkReviewPayload(
                                              asset,
                                              widget.payload.wallet,
                                              state.address!,
                                              state.fee!,
                                              state.exchangeRate,
                                              widget.payload.ownedQuantity,
                                              state.quantity));
                                  if (txHash != null && txHash is String) {
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _gasFee(SendArtworkState state) {
    if (state.fee == null) return "";
    final fee = state.fee!;

    String text = "gas_fee".tr();

    switch (widget.payload.asset.blockchain) {
      case "ethereum":
        text +=
            "${EthAmountFormatter(fee).format()} ETH (${state.exchangeRate.ethToUsd(fee)} USD)";
        break;
      case "tezos":
        text +=
            "${XtzAmountFormatter(fee.toInt()).format()} XTZ (${state.exchangeRate.xtzToUsd(fee.toInt())} USD)";
        break;
      default:
        break;
    }
    return text;
  }
}

class SendArtworkPayload {
  final AssetToken asset;
  final WalletStorage wallet;
  final int ownedQuantity;

  SendArtworkPayload(this.asset, this.wallet, this.ownedQuantity);
}
