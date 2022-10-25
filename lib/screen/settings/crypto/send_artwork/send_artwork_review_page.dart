//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
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
    final theme = Theme.of(context);
    final asset = widget.payload.asset;

    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        asset.artistName?.toIdentityOrMask(identityState.identityMap);

    return AbsorbPointer(
      absorbing: _isSending,
      child: Scaffold(
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
                            "confirmation".tr(),
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
                                  "${widget.payload.ownedTokens}",
                                  style: theme.textTheme.bodyText2,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "quantity_sent".tr(),
                                  style: theme.textTheme.headline4,
                                ),
                                Text(
                                  "${widget.payload.quantity}",
                                  style: theme.textTheme.bodyText2,
                                ),
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
                          Text(
                            "to".tr(),
                            style: theme.textTheme.headline4,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            widget.payload.address,
                            style: theme.textTheme.bodyText2,
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "gas_fee2".tr(),
                                style: theme.textTheme.headline4,
                              ),
                              Text(
                                widget.payload.asset.blockchain == "ethereum"
                                    ? "${EthAmountFormatter(widget.payload.fee).format()} ETH (${widget.payload.exchangeRate.ethToUsd(widget.payload.fee)} USD)"
                                    : "${XtzAmountFormatter(widget.payload.fee.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(widget.payload.fee.toInt())} USD)",
                                style: theme.textTheme.bodyText2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: _isSending
                              ? "sending".tr().toUpperCase()
                              : "sendH".tr(),
                          isProcessing: _isSending,
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
                                        injector<EthereumService>();

                                    final contractAddress =
                                        EthereumAddress.fromHex(
                                            asset.contractAddress!);
                                    final to = EthereumAddress.fromHex(
                                        widget.payload.address);
                                    final from = EthereumAddress.fromHex(
                                        await widget.payload.wallet
                                            .getETHAddress());
                                    final tokenId = asset.tokenId!;

                                    final data = widget
                                                .payload.asset.contractType ==
                                            "erc1155"
                                        ? await ethereumService
                                            .getERC1155TransferTransactionData(
                                                contractAddress,
                                                from,
                                                to,
                                                tokenId,
                                                widget.payload.quantity)
                                        : await ethereumService
                                            .getERC721TransferTransactionData(
                                                contractAddress,
                                                from,
                                                to,
                                                tokenId);

                                    final txHash =
                                        await ethereumService.sendTransaction(
                                            widget.payload.wallet,
                                            contractAddress,
                                            BigInt.zero,
                                            null,
                                            data);
                                    if (!mounted) return;
                                    final payload = {
                                      "isTezos": false,
                                      "hash": txHash
                                    };
                                    Navigator.of(context).pop(payload);
                                  } else {
                                    final tezosService =
                                        injector<TezosService>();
                                    final tokenId = asset.tokenId!;

                                    final wallet = widget.payload.wallet;
                                    final address =
                                        await wallet.getTezosAddress();
                                    final operation = await tezosService
                                        .getFa2TransferOperation(
                                            widget
                                                .payload.asset.contractAddress!,
                                            address,
                                            widget.payload.address,
                                            tokenId,
                                            widget.payload.quantity);
                                    final opHash = await tezosService
                                        .sendOperationTransaction(
                                            wallet, [operation]);
                                    final exchangeRateXTZ = 1 /
                                        (double.tryParse(widget
                                                .payload.exchangeRate.xtz) ??
                                            1);
                                    final tx = TZKTOperation(
                                      bakerFee: 0,
                                      block: '',
                                      counter: 0,
                                      gasLimit: 0,
                                      hash: opHash ?? '',
                                      gasUsed: 0,
                                      id: 0,
                                      level: 0,
                                      quote: TZKTQuote(
                                        usd: exchangeRateXTZ,
                                      ),
                                      timestamp: DateTime.now(),
                                      type: 'transaction',
                                      sender: TZKTActor(
                                        address: address,
                                      ),
                                      target: TZKTActor(
                                        address: widget.payload.address,
                                      ),
                                      amount: widget.payload.fee.toInt(),
                                    )..tokenTransfer = TZKTTokenTransfer(
                                        id: 0,
                                        level: 0,
                                        from: TZKTActor(
                                          address: address,
                                        ),
                                        to: TZKTActor(
                                          address: widget.payload.address,
                                        ),
                                        timestamp: DateTime.now(),
                                        amount:
                                            widget.payload.quantity.toString(),
                                        token: TZKTToken(
                                          tokenId: tokenId,
                                          id: 0,
                                          contract: TZKTActor(
                                              address: widget.payload.asset
                                                      .contractAddress ??
                                                  ''),
                                        ),
                                        status: 'pending');
                                    if (!mounted) return;
                                    final payload = {
                                      "isTezos": true,
                                      "hash": opHash,
                                      "tx": tx,
                                    };
                                    Navigator.of(context).pop(payload);
                                  }

                                  setState(() {
                                    _isSending = false;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ],
        ),
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
  final int ownedTokens;
  final int quantity;

  SendArtworkReviewPayload(this.asset, this.wallet, this.address, this.fee,
      this.exchangeRate, this.ownedTokens, this.quantity);
}
