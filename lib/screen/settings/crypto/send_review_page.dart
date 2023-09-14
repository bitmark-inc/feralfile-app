//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

class SendReviewPage extends StatefulWidget {
  static const String tag = 'send_review';

  final SendCryptoPayload payload;

  const SendReviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SendReviewPage> createState() => _SendReviewPageState();
}

class _SendReviewPageState extends State<SendReviewPage> {
  bool _isSending = false;

  void _send() async {
    setState(() {
      _isSending = true;
    });

    try {
      final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
      if (!didAuthenticate) {
        setState(() {
          _isSending = false;
        });
        return;
      }

      switch (widget.payload.type) {
        case CryptoType.ETH:
          final address = EthereumAddress.fromHex(widget.payload.address);
          final txHash = await injector<EthereumService>().sendTransaction(
              widget.payload.wallet,
              widget.payload.index,
              address,
              widget.payload.amount,
              null,
              feeOption: widget.payload.feeOption);

          if (!mounted) return;
          final payload = {
            "isTezos": false,
            "hash": txHash,
          };
          Navigator.of(context).pop(payload);
          break;
        case CryptoType.XTZ:
          final opHash = await injector<TezosService>().sendTransaction(
              widget.payload.wallet,
              widget.payload.index,
              widget.payload.address,
              widget.payload.amount.toInt(),
              baseOperationCustomFee:
                  widget.payload.feeOption.tezosBaseOperationCustomFee);
          if (!mounted) return;
          final payload = {
            "isTezos": true,
            "hash": opHash,
          };
          Navigator.of(context).pop(payload);
          break;
        case CryptoType.USDC:
          final address = await widget.payload.wallet
              .getETHEip55Address(index: widget.payload.index);
          final ownerAddress = EthereumAddress.fromHex(address);
          final toAddress = EthereumAddress.fromHex(widget.payload.address);
          final contractAddress = EthereumAddress.fromHex(usdcContractAddress);

          final data = await injector<EthereumService>()
              .getERC20TransferTransactionData(contractAddress, ownerAddress,
                  toAddress, widget.payload.amount,
                  feeOption: widget.payload.feeOption);

          final txHash = await injector<EthereumService>().sendTransaction(
              widget.payload.wallet,
              widget.payload.index,
              contractAddress,
              BigInt.zero,
              data,
              feeOption: widget.payload.feeOption);

          if (!mounted) return;
          final payload = {
            "isTezos": false,
            "hash": txHash,
          };
          Navigator.of(context).pop(payload);
          break;
        default:
          break;
      }
    } catch (e) {
      if (!mounted) return;
      UIHelper.showMessageAction(
        context,
        'transaction_failed'.tr(),
        'try_later'.tr(),
      );
    }

    setState(() {
      _isSending = false;
    });
  }

  String _titleText() {
    switch (widget.payload.type) {
      case CryptoType.ETH:
        return "send_eth".tr();
      case CryptoType.XTZ:
        return "send_xtz".tr();
      case CryptoType.USDC:
        return "send_usdc".tr();
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.payload.type == CryptoType.USDC
        ? widget.payload.amount
        : widget.payload.amount + widget.payload.fee;
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "confirmation".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          Container(
            margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
                .copyWith(left: 0, right: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                addTitleSpace(),
                Padding(
                  padding: padding,
                  child: Text(
                    _titleText(),
                    style: theme.textTheme.ppMori400Black16,
                  ),
                ),
                const SizedBox(height: 40),
                addDivider(),
                Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              "amount".tr(),
                              style: theme.textTheme.ppMori400Grey14,
                            ),
                          ),
                          Text(
                            _amountFormat(widget.payload.amount),
                            style: theme.textTheme.ppMori400Black14,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              "total_amount".tr(),
                              style: theme.textTheme.ppMori400Grey14,
                            ),
                          ),
                          Text(
                            _amountFormat(total),
                            style: theme.textTheme.ppMori400Black14,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.primaryBlack),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "to".tr(),
                              style: theme.textTheme.ppMori400Grey14,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              widget.payload.address,
                              style: theme.textTheme.ppMori400White14,
                            ),
                            addDivider(color: AppColor.white),
                            Text(
                              "gas_fee2".tr(),
                              style: theme.textTheme.ppMori400Grey14,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _amountFormat(widget.payload.fee, isETH: true),
                              style: theme.textTheme.ppMori400White14,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Expanded(child: SizedBox()),
                Padding(
                  padding: padding,
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: _isSending ? "sending".tr() : "send".tr(),
                          isProcessing: _isSending,
                          onTap: _isSending ? null : _send,
                        ),
                      ),
                    ],
                  ),
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

  String _amountFormat(BigInt amount, {bool isETH = false}) {
    switch (widget.payload.type) {
      case CryptoType.ETH:
        return "${EthAmountFormatter(amount).format()} ETH (${widget.payload.exchangeRate.ethToUsd(amount)} USD)";
      case CryptoType.XTZ:
        return "${XtzAmountFormatter(amount.toInt()).format()} XTZ (${widget.payload.exchangeRate.xtzToUsd(amount.toInt())} USD)";
      case CryptoType.USDC:
        if (isETH) {
          return "${EthAmountFormatter(amount).format()} ETH (${widget.payload.exchangeRate.ethToUsd(amount)} USD)";
        } else {
          return "${USDCAmountFormatter(amount).format()} USDC";
        }
      default:
        return "";
    }
  }
}
