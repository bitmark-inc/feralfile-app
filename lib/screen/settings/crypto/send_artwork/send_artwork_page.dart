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
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
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

  @override
  void initState() {
    super.initState();

    context.read<SendArtworkBloc>().add(GetBalanceEvent(widget.payload.wallet));
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.payload.asset;

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
          BlocBuilder<SendArtworkBloc, SendArtworkState>(
              builder: (context, state) {
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
                            "Send artwork",
                            style: appTextTheme.headline1,
                          ),
                          const SizedBox(height: 40.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Title",
                                style: appTextTheme.headline4,
                              ),
                              Expanded(
                                child: Text(
                                  asset.title,
                                  textAlign: TextAlign.right,
                                  style: appTextTheme.bodyText2,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Artist",
                                style: appTextTheme.headline4,
                              ),
                              Text(
                                artistName ?? "",
                                style: appTextTheme.bodyText2,
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Edition",
                                style: appTextTheme.headline4,
                              ),
                              Text(
                                "${asset.edition}/${asset.maxEdition}",
                                style: appTextTheme.bodyText2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32.0),
                          AuTextField(
                            title: "To",
                            placeholder: "Paste or scan address",
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
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontFamily: "AtlasGrotesk")),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "REVIEW",
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
                                              state.exchangeRate));
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

    String text = "Gas fee: ";

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

  SendArtworkPayload(this.asset, this.wallet);
}
