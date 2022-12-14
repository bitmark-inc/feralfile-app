//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_connect/models/ethereum/wc_ethereum_transaction.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/web3dart.dart';

class WCSendTransactionPage extends StatefulWidget {
  static const String tag = 'wc_send_transaction';

  final WCSendTransactionPageArgs args;

  const WCSendTransactionPage({Key? key, required this.args}) : super(key: key);

  @override
  State<WCSendTransactionPage> createState() => _WCSendTransactionPageState();
}

class _WCSendTransactionPageState extends State<WCSendTransactionPage> {
  bool _showAllFeeOption = false;
  final mixPanelClient = injector.get<MixPanelClientService>();

  @override
  void initState() {
    super.initState();

    final to = EthereumAddress.fromHex(widget.args.transaction.to);
    final EtherAmount amount = EtherAmount.fromUnitAndValue(
        EtherUnit.wei, widget.args.transaction.value ?? 0);

    context.read<WCSendTransactionBloc>().add(WCSendTransactionEstimateEvent(
        to, amount, widget.args.transaction.data, widget.args.uuid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        mixPanelClient.trackEvent(MixpanelEvent.backConfirmTransaction);

        context.read<WCSendTransactionBloc>().add(
              WCSendTransactionRejectEvent(
                widget.args.peerMeta,
                widget.args.id,
                isWalletConnect2: widget.args.isWalletConnect2,
                topic: widget.args.topic,
              ),
            );
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            mixPanelClient.trackEvent(MixpanelEvent.backConfirmTransaction);
            context.read<WCSendTransactionBloc>().add(
                  WCSendTransactionRejectEvent(
                    widget.args.peerMeta,
                    widget.args.id,
                    isWalletConnect2: widget.args.isWalletConnect2,
                    topic: widget.args.topic,
                  ),
                );
          },
        ),
        body: BlocConsumer<WCSendTransactionBloc, WCSendTransactionState>(
          listener: (context, state) {
            final EtherAmount amount = EtherAmount.fromUnitAndValue(
                EtherUnit.wei, widget.args.transaction.value ?? 0);
            final total =
                state.fee != null ? state.fee! + amount.getInWei : null;
            if (total != null &&
                state.balance != null &&
                total > state.balance!) {
              UIHelper.showMessageAction(
                context,
                'transaction_failed'.tr(),
                'dont_enough_money'.tr(),
              );
              return;
            }
            if (state.isError) {
              UIHelper.showMessageAction(
                context,
                'transaction_failed'.tr(),
                'try_later'.tr(),
              );
            }
          },
          builder: (context, state) {
            final EtherAmount amount = EtherAmount.fromUnitAndValue(
                EtherUnit.wei, widget.args.transaction.value ?? 0);
            final total =
                state.fee != null ? state.fee! + amount.getInWei : null;
            return Stack(
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
                              const SizedBox(height: 8.0),
                              Text(
                                "h_confirm".tr(),
                                style: theme.textTheme.headline1,
                              ),
                              const SizedBox(height: 40.0),
                              Text(
                                "asset".tr(),
                                style: theme.textTheme.headline4,
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                "ethereum_eth".tr(),
                                style: theme.textTheme.bodyText2,
                              ),
                              const Divider(height: 32),
                              Text(
                                "from".tr(),
                                style: theme.textTheme.headline4,
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                widget.args.transaction.from,
                                style: theme.textTheme.bodyText2,
                              ),
                              const Divider(height: 32),
                              Text(
                                "connection".tr(),
                                style: theme.textTheme.headline4,
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                widget.args.peerMeta.name,
                                style: theme.textTheme.bodyText2,
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "send".tr(),
                                    style: theme.textTheme.headline4,
                                  ),
                                  Text(
                                    "${EthAmountFormatter(amount.getInWei).format()} ETH",
                                    style: theme.textTheme.bodyText2,
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "gas_fee2".tr(),
                                    style: theme.textTheme.headline4,
                                  ),
                                  Text(
                                    "${state.fee != null ? EthAmountFormatter(state.fee!, digit: 8).format() : "-"} ETH",
                                    style: theme.textTheme.bodyText2,
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "total_amount".tr(),
                                    style: theme.textTheme.headline4,
                                  ),
                                  Text(
                                    "${total != null ? EthAmountFormatter(total).format() : "-"} ETH",
                                    style: theme.textTheme.headline4,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              gasFeeStatus(state, theme),
                              const SizedBox(height: 10.0),
                              if (state.feeOptionValue != null)
                                feeTable(state, context),
                              const SizedBox(height: 24.0),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AuFilledButton(
                              text: "send".tr().toUpperCase(),
                              onPress: (state.fee != null && !state.isSending)
                                  ? () async {
                                      mixPanelClient.trackEvent(
                                          MixpanelEvent.confirmTransaction);

                                      final to = EthereumAddress.fromHex(
                                          widget.args.transaction.to);

                                      context.read<WCSendTransactionBloc>().add(
                                            WCSendTransactionSendEvent(
                                              widget.args.peerMeta,
                                              widget.args.id,
                                              to,
                                              amount.getInWei,
                                              state.fee!,
                                              widget.args.transaction.data,
                                              widget.args.uuid,
                                              isWalletConnect2:
                                                  widget.args.isWalletConnect2,
                                              topic: widget.args
                                                  .topic, // Used for wallet Connect 2.0 only
                                            ),
                                          );
                                    }
                                  : null,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                state.isSending
                    ? const Center(child: CupertinoActivityIndicator())
                    : const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget gasFeeStatus(WCSendTransactionState state, ThemeData theme) {
    if (state.feeOptionValue == null) {
      return Text("gas_fee_calculating".tr(), style: theme.textTheme.headline5);
    }
    if (state.feeOptionValue != null) {
      if (state.balance == null) {
        return Text("gas_fee".tr(), style: theme.textTheme.headline5);
      }
      bool isValid = state.balance! >
          ((BigInt.parse(widget.args.transaction.value ?? "0")) +
              (state.fee ?? BigInt.zero) +
              BigInt.from(10));
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

  Widget feeTable(WCSendTransactionState state, BuildContext context) {
    final theme = Theme.of(context);
    final feeOption = state.feeOption;
    if (!_showAllFeeOption) {
      return Row(
        children: [
          Text(feeOption.name, style: theme.textTheme.atlasBlackBold12),
          const Spacer(),
          Text(_gasFee(state), style: theme.textTheme.atlasBlackBold12),
          const SizedBox(width: 56),
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
      FeeOption feeOption, WCSendTransactionState state, ThemeData theme) {
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
            context
                .read<WCSendTransactionBloc>()
                .add(FeeOptionChangedEvent(feeOption));
          },
          child: SvgPicture.asset(isSelected
              ? "assets/images/radio_btn_selected.svg"
              : "assets/images/radio_btn_not_selected.svg"),
        ),
      ],
    );
  }

  String _gasFee(WCSendTransactionState state, {FeeOption? feeOption}) {
    if (state.feeOptionValue == null) return "";
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    return "${EthAmountFormatter(fee, digit: 7).format()} ETH";
  }
}

class WCSendTransactionPageArgs {
  final int id;
  final WCPeerMeta peerMeta;
  final WCEthereumTransaction transaction;
  final String uuid;
  final String? topic; // For Wallet Connect 2.0
  final bool isWalletConnect2;

  WCSendTransactionPageArgs(
    this.id,
    this.peerMeta,
    this.transaction,
    this.uuid, {
    this.topic,
    this.isWalletConnect2 = false,
  });
}
