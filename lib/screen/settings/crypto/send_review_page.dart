//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:web3dart/credentials.dart';

class SendReviewPage extends StatefulWidget {
  static const String tag = 'send_review';

  final SendCryptoPayload payload;

  const SendReviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SendReviewPage> createState() => _SendReviewPageState();
}

class _SendReviewPageState extends State<SendReviewPage> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.payload.amount + widget.payload.fee;
    final theme = Theme.of(context);

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
                Text(
                  "confirmation".tr(),
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 40.0),
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
                      "send".tr(),
                      style: theme.textTheme.headline4,
                    ),
                    Text(
                      widget.payload.type == CryptoType.ETH
                          ? "${EthAmountFormatter(widget.payload.amount).format()} ETH (${widget.payload.exchangeRate.ethToUsd(widget.payload.amount)} USD)"
                          : "${XtzAmountFormatter(widget.payload.amount.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(widget.payload.amount.toInt())} USD)",
                      style: theme.textTheme.bodyText2,
                    ),
                  ],
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
                      widget.payload.type == CryptoType.ETH
                          ? "${EthAmountFormatter(widget.payload.fee).format()} ETH (${widget.payload.exchangeRate.ethToUsd(widget.payload.fee)} USD)"
                          : "${XtzAmountFormatter(widget.payload.fee.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(widget.payload.fee.toInt())} USD)",
                      style: theme.textTheme.bodyText2,
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "total_amount".tr(),
                      style: theme.textTheme.headline4,
                    ),
                    Text(
                      widget.payload.type == CryptoType.ETH
                          ? "${EthAmountFormatter(total).format()} ETH (${widget.payload.exchangeRate.ethToUsd(total)} USD)"
                          : "${XtzAmountFormatter(total.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(total.toInt())} USD)",
                      style: theme.textTheme.headline4,
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
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

                                final configurationService =
                                    injector<ConfigurationService>();

                                if (configurationService
                                        .isDevicePasscodeEnabled() &&
                                    await authenticateIsAvailable()) {
                                  final localAuth = LocalAuthentication();
                                  final didAuthenticate =
                                      await localAuth.authenticate(
                                          localizedReason:
                                              "authen_for_autonomy".tr());
                                  if (!didAuthenticate) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                    return;
                                  }
                                }

                                switch (widget.payload.type) {
                                  case CryptoType.ETH:
                                    final address = EthereumAddress.fromHex(
                                        widget.payload.address);
                                    final txHash =
                                        await injector<EthereumService>()
                                            .sendTransaction(
                                                widget.payload.wallet,
                                                address,
                                                widget.payload.amount,
                                                null,
                                                null);

                                    if (!mounted) return;
                                    Navigator.of(context).pop(txHash);
                                    break;
                                  case CryptoType.XTZ:
                                    final opHash = await injector<TezosService>()
                                        .sendTransaction(
                                            widget.payload.wallet,
                                            widget.payload.address,
                                            widget.payload.amount.toInt());
                                    final exchangeRateXTZ = 1 /
                                        (double.tryParse(widget
                                            .payload.exchangeRate.xtz) ??
                                            0);
                                    final tx = TZKTOperation(
                                      bakerFee: widget.payload.fee.toInt(),
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
                                      target: TZKTActor(
                                        address: widget.payload.address,
                                      ),
                                      amount: widget.payload.amount.toInt(),
                                    );
                                    if (!mounted) return;
                                    final payload = {
                                      "isTezos": true,
                                      "hash": opHash,
                                      "tx": tx,
                                    };
                                    Navigator.of(context).pop(payload);
                                    break;
                                  default:
                                    break;
                                }


                                setState(() {
                                  _isSending = false;
                                });
                              },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          _isSending
              ? const Center(child: CupertinoActivityIndicator())
              : const SizedBox(),
        ],
      ),
    );
  }
}
