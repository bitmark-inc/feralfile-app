//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/web3dart.dart';

class SendArtworkReviewPage extends StatefulWidget {
  final SendArtworkReviewPayload payload;

  const SendArtworkReviewPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<SendArtworkReviewPage> createState() => _SendArtworkReviewPageState();
}

class _SendArtworkReviewPageState extends State<SendArtworkReviewPage> {
  bool _isSending = false;

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
          Container(
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
                          "Confirmation",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 40.0),
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
                        Divider(height: 32),
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
                        Divider(height: 32),
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
                        SizedBox(height: 32.0),
                        Text(
                          "To",
                          style: appTextTheme.headline4,
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          widget.payload.address,
                          style: appTextTheme.bodyText2,
                        ),
                        Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Gas fee",
                              style: appTextTheme.headline4,
                            ),
                            Text(
                              widget.payload.asset.blockchain == "ethereum"
                                  ? "${EthAmountFormatter(widget.payload.fee).format()} ETH (${widget.payload.exchangeRate.ethToUsd(widget.payload.fee)} USD)"
                                  : "${XtzAmountFormatter(widget.payload.fee.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(widget.payload.fee.toInt())} USD)",
                              style: appTextTheme.bodyText2,
                            ),
                          ],
                        ),
                        SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "SEND",
                        onPress: _isSending
                            ? null
                            : () async {
                                setState(() {
                                  _isSending = true;
                                });

                                final asset = widget.payload.asset;
                                if (widget.payload.asset.blockchain ==
                                    "ethereum") {
                                  final ethereumService =
                                      injector<NetworkConfigInjector>()
                                          .I<EthereumService>();

                                  final contractAddress =
                                      EthereumAddress.fromHex(
                                          asset.contractAddress!);
                                  final to = EthereumAddress.fromHex(
                                      widget.payload.address);
                                  final from = EthereumAddress.fromHex(
                                      await widget.payload.wallet
                                          .getETHAddress());
                                  final tokenId = asset.tokenId!;

                                  final data = await ethereumService
                                      .getERC721TransferTransactionData(
                                          contractAddress, from, to, tokenId);

                                  final txHash =
                                      await ethereumService.sendTransaction(
                                          widget.payload.wallet,
                                          contractAddress,
                                          BigInt.zero,
                                          null,
                                          data);
                                  Navigator.of(context).pop(txHash);
                                } else {
                                  final tezosService =
                                      injector<NetworkConfigInjector>()
                                          .I<TezosService>();
                                  final tokenId = asset.tokenId!;

                                  final tezosWallet = await widget
                                      .payload.wallet
                                      .getTezosWallet();
                                  final operation = await tezosService
                                      .getFa2TransferOperation(
                                          widget.payload.asset.contractAddress!,
                                          tezosWallet.address,
                                          widget.payload.address,
                                          int.parse(tokenId));
                                  final opHash = await tezosService
                                      .sendOperationTransaction(
                                          tezosWallet, [operation]);
                                  Navigator.of(context).pop(opHash);
                                }

                                setState(() {
                                  _isSending = false;
                                });
                              },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ),
          _isSending ? Center(child: CupertinoActivityIndicator()) : SizedBox(),
        ],
      ),
    );
  }
}

class SendArtworkReviewPayload {
  final AssetToken asset;
  final WalletStorage wallet;
  final String address;
  final BigInt fee;
  final CurrencyExchangeRate exchangeRate;

  SendArtworkReviewPayload(
      this.asset, this.wallet, this.address, this.fee, this.exchangeRate);
}
