//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc_ethereum_transaction.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';

class WCSendTransactionPage extends StatefulWidget {
  static const String tag = 'wc_send_transaction';

  final WCSendTransactionPageArgs args;

  const WCSendTransactionPage({required this.args, super.key});

  @override
  State<WCSendTransactionPage> createState() => _WCSendTransactionPageState();
}

class _WCSendTransactionPageState extends State<WCSendTransactionPage> {
  final metricClient = injector.get<MetricClientService>();
  late FeeOption _selectedPriority;
  final ethFormatter = EthAmountFormatter();

  @override
  void initState() {
    super.initState();

    final to = EthereumAddress.fromHex(widget.args.transaction.to!);
    final EtherAmount amount = EtherAmount.fromBase10String(
        EtherUnit.wei, widget.args.transaction.value ?? '0');

    context.read<WCSendTransactionBloc>().add(WCSendTransactionEstimateEvent(
        to,
        amount,
        widget.args.transaction.data ?? '',
        widget.args.uuid,
        widget.args.index));
    _selectedPriority = context.read<WCSendTransactionBloc>().state.feeOption;
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final divider = addDivider(height: 20);

    return WillPopScope(
      onWillPop: () async {
        unawaited(metricClient.addEvent(MixpanelEvent.backConfirmTransaction));

        context.read<WCSendTransactionBloc>().add(
              WCSendTransactionRejectEvent(
                widget.args.peerMeta,
                widget.args.id,
                isWalletConnect2: widget.args.isWalletConnect2,
                topic: widget.args.topic,
                isIRL: widget.args.isIRL,
              ),
            );
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'confirmation'.tr(),
          onBack: () {
            unawaited(
                metricClient.addEvent(MixpanelEvent.backConfirmTransaction));
            context.read<WCSendTransactionBloc>().add(
                  WCSendTransactionRejectEvent(
                    widget.args.peerMeta,
                    widget.args.id,
                    isWalletConnect2: widget.args.isWalletConnect2,
                    topic: widget.args.topic,
                    isIRL: widget.args.isIRL,
                  ),
                );
          },
        ),
        body: BlocConsumer<WCSendTransactionBloc, WCSendTransactionState>(
          listener: (context, state) {
            final EtherAmount amount = EtherAmount.fromBase10String(
                EtherUnit.wei, widget.args.transaction.value ?? '0');
            final total =
                state.fee != null ? state.fee! + amount.getInWei : null;
            if (total != null &&
                state.balance != null &&
                total > state.balance!) {
              unawaited(UIHelper.showMessageAction(
                context,
                'transaction_failed'.tr(),
                'dont_enough_money'.tr(),
              ));
              return;
            }
            if (state.isError) {
              unawaited(UIHelper.showMessageAction(
                context,
                'transaction_failed'.tr(),
                'try_later'.tr(),
              ));
            }
          },
          builder: (context, state) {
            final EtherAmount amount = EtherAmount.fromBase10String(
                EtherUnit.wei, widget.args.transaction.value ?? '0');
            final total =
                state.fee != null ? state.fee! + amount.getInWei : null;
            final theme = Theme.of(context);
            final ethAmountText = '${ethFormatter.format(amount.getInWei)} ETH '
                '(${state.exchangeRate?.ethToUsd(amount.getInWei) ?? '-'} USD)';
            final ethTotalAmountText = total == null
                ? '- ETH (- USD)'
                : '${ethFormatter.format(total)} ETH'
                    ' (${state.exchangeRate?.ethToUsd(total) ?? '-'} USD)';
            return Stack(
              children: [
                Container(
                  margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
                      .copyWith(left: 0, right: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addTitleSpace(),
                              Padding(
                                padding: padding,
                                child: Text(
                                  'confirm_transaction'.tr(),
                                  style: theme.textTheme.ppMori400Black16,
                                ),
                              ),
                              const SizedBox(height: 64),
                              divider,
                              Padding(
                                padding: padding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _item(
                                      context: context,
                                      title: 'asset'.tr(),
                                      content: 'ethereum_eth'.tr(),
                                    ),
                                    divider,
                                    _item(
                                        context: context,
                                        title: 'connection'.tr(),
                                        content: widget.args.peerMeta.name),
                                    divider,
                                    _item(
                                        context: context,
                                        title: 'amount'.tr(),
                                        content: ethAmountText),
                                    divider,
                                    _item(
                                        context: context,
                                        title: 'total_amount'.tr(),
                                        content: ethTotalAmountText),
                                    divider,
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: AppColor.primaryBlack),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'from'.tr(),
                                            style:
                                                theme.textTheme.ppMori400Grey14,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.args.transaction.from,
                                            style: theme
                                                .textTheme.ppMori400White14,
                                          ),
                                          addDivider(color: AppColor.white),
                                          Text(
                                            'gas_fee2'.tr(),
                                            style:
                                                theme.textTheme.ppMori400Grey14,
                                          ),
                                          const SizedBox(height: 8),
                                          if (state.feeOptionValue != null) ...[
                                            feeTable(state, context)
                                          ],
                                        ],
                                      ),
                                    ),
                                    gasFeeStatus(state, theme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: padding,
                        child: Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'send'.tr(),
                                enabled: widget.args.transaction.to != null,
                                onTap: (state.fee != null &&
                                        !state.isSending &&
                                        widget.args.transaction.to != null)
                                    ? () async {
                                        unawaited(metricClient.addEvent(
                                            MixpanelEvent.confirmTransaction));

                                        final to = EthereumAddress.fromHex(
                                            widget.args.transaction.to!);

                                        context
                                            .read<WCSendTransactionBloc>()
                                            .add(
                                              WCSendTransactionSendEvent(
                                                widget.args.peerMeta,
                                                widget.args.id,
                                                to,
                                                amount.getInWei,
                                                state.fee,
                                                widget.args.transaction.data,
                                                widget.args.uuid,
                                                widget.args.index,
                                                isWalletConnect2: widget
                                                    .args.isWalletConnect2,
                                                topic: widget.args.topic,
                                                isIRL: widget.args.isIRL,
                                              ),
                                            );
                                      }
                                    : null,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isSending)
                  const Center(child: CupertinoActivityIndicator())
                else
                  const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required String title,
    required String content,
    String? tapLink,
    double width = 120,
    bool forceSafariVC = true,
  }) {
    final theme = Theme.of(context);
    Function()? onValueTap;

    if (tapLink != null) {
      final uri = Uri.parse(tapLink);
      onValueTap = () => unawaited(launchUrl(uri,
          mode: forceSafariVC
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault));
    }
    return Row(
      children: [
        SizedBox(
          width: width,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onValueTap,
            child: Text(
              content,
              style: theme.textTheme.ppMori400Black14.copyWith(
                  decoration:
                      (onValueTap != null) ? TextDecoration.underline : null),
            ),
          ),
        ),
      ],
    );
  }

  Widget gasFeeStatus(WCSendTransactionState state, ThemeData theme) {
    if (state.feeOptionValue == null) {
      return Text('gas_fee_calculating'.tr(),
          style: theme.textTheme.ppMori400Black12);
    }
    if (state.feeOptionValue != null) {
      if (state.balance == null) {
        return const SizedBox();
      }
      bool isValid = state.balance! >
          ((BigInt.parse(widget.args.transaction.value ?? '0')) +
              (state.fee ?? BigInt.zero) +
              BigInt.from(10));
      if (!isValid) {
        return Text('gas_fee_insufficient'.tr(),
            style: theme.textTheme.ppMori400Black12.copyWith(
              color: AppColor.red,
            ));
      }
    }
    return const SizedBox();
  }

  Widget feeTable(WCSendTransactionState state, BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(_gasFee(state), style: theme.textTheme.ppMori400White14),
        const Spacer(),
        GestureDetector(
          onTap: () {
            unawaited(UIHelper.showDialog(
              context,
              'edit_priority'.tr().capitalize(),
              _editPriorityView(context, state, onSave: () {
                context
                    .read<WCSendTransactionBloc>()
                    .add(FeeOptionChangedEvent(_selectedPriority));
              }),
              backgroundColor: AppColor.auGreyBackground,
              padding: const EdgeInsets.symmetric(vertical: 32),
              paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets,
            ));
          },
          child: Text('edit_priority'.tr(),
              style: theme.textTheme.ppMori400White14.copyWith(
                decoration: TextDecoration.underline,
              )),
        ),
      ],
    );
  }

  Widget _editPriorityView(BuildContext context, WCSendTransactionState state,
      {required Function() onSave}) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return StatefulBuilder(
        builder: (context, setState) => Column(
              children: [
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.LOW, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.MEDIUM, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.HIGH, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                const SizedBox(height: 12),
                Padding(
                  padding: padding,
                  child: PrimaryButton(
                    text: 'save_priority'.tr(),
                    onTap: () {
                      onSave();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: padding,
                  child: OutlineButton(
                    text: 'cancel'.tr(),
                    onTap: () {
                      _selectedPriority = state.feeOption;
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            ));
  }

  Widget getFeeRow(FeeOption feeOption, WCSendTransactionState state,
      ThemeData theme, StateSetter setState) {
    final textStyle = theme.textTheme.ppMori400White14;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = feeOption;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Text(feeOption.name, style: textStyle),
            const Spacer(),
            Text(_gasFee(state, feeOption: feeOption), style: textStyle),
            const SizedBox(width: 56),
            AuRadio(
              onTap: (FeeOption value) {
                setState(() {
                  _selectedPriority = feeOption;
                });
              },
              value: feeOption,
              groupValue: _selectedPriority,
              color: AppColor.white,
            ),
          ],
        ),
      ),
    );
  }

  String _gasFee(WCSendTransactionState state, {FeeOption? feeOption}) {
    if (state.feeOptionValue == null) {
      return '';
    }
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    return '${ethFormatter.format(fee)} ETH '
        '(${state.exchangeRate?.ethToUsd(fee) ?? '-'} USD)';
  }
}

class WCSendTransactionPageArgs {
  final int id;
  final AppMetadata peerMeta;
  final WCEthereumTransaction transaction;
  final String uuid;
  final int index;
  final String? topic; // For Wallet Connect 2.0
  final bool isWalletConnect2;
  final bool isIRL;

  WCSendTransactionPageArgs(
    this.id,
    this.peerMeta,
    this.transaction,
    this.uuid,
    this.index, {
    this.topic,
    this.isWalletConnect2 = false,
    this.isIRL = false,
  });
}
