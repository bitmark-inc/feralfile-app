//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:tezart/tezart.dart';
import 'package:url_launcher/url_launcher.dart';

class TBSendTransactionPage extends StatefulWidget {
  final BeaconRequest request;

  const TBSendTransactionPage({required this.request, super.key});

  @override
  State<TBSendTransactionPage> createState() => _TBSendTransactionPageState();
}

class _TBSendTransactionPageState extends State<TBSendTransactionPage> {
  int? _fee;
  WalletIndex? _currentWallet;
  bool _isSending = false;
  String? _estimateMessage;
  late FeeOption feeOption;
  FeeOptionValue? feeOptionValue;
  int? balance;
  final metricClient = injector.get<MetricClientService>();
  CurrencyExchangeRate? _exchangeRate;
  late FeeOption _selectedPriority;
  final xtzFormatter = XtzAmountFormatter();
  final ethFormatter = EthAmountFormatter();

  @override
  void dispose() {
    super.dispose();
    Future.delayed(const Duration(seconds: 2), () {
      unawaited(
          injector<TezosBeaconService>().handleNextRequest(isRemoved: true));
    });
  }

  Future<void> _send() async {
    setState(() {
      _isSending = true;
    });

    final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
    if (!didAuthenticate) {
      setState(() {
        _isSending = false;
      });
      return;
    }

    try {
      final wc2Topic = widget.request.wc2Topic;

      final txHash = await injector<TezosService>().sendOperationTransaction(
          _currentWallet!.wallet,
          _currentWallet!.index,
          widget.request.operations!,
          baseOperationCustomFee: feeOption.tezosBaseOperationCustomFee);
      if (wc2Topic == null) {
        unawaited(injector<TezosBeaconService>()
            .operationResponse(widget.request.id, txHash));
      }

      final address = widget.request.sourceAddress;
      if (address != null) {
        unawaited(injector<PendingTokenService>()
            .checkPendingTezosTokens(address)
            .then((tokens) {
          if (tokens.isNotEmpty) {
            NftCollectionBloc.eventController
                .add(UpdateTokensEvent(tokens: tokens));
          }
        }));
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(txHash);
    } on TezartNodeError catch (err) {
      log.info(err);
      if (!mounted) {
        return;
      }
      unawaited(UIHelper.showInfoDialog(
        context,
        'operation_failed'.tr(),
        getTezosErrorMessage(err),
        isDismissible: true,
      ));
    } catch (err) {
      unawaited(showErrorDialogFromException(err));
      log.warning(err);
    }

    setState(() {
      _isSending = false;
    });
  }

  int _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_getExchangeRate());
    _totalAmount = widget.request.operations?.fold(
            0,
            (previousValue, element) =>
                (previousValue ?? 0) + (element.amount ?? 0)) ??
        0;
    unawaited(fetchPersona());
    feeOption = DEFAULT_FEE_OPTION;
    _selectedPriority = feeOption;
  }

  Future<void> _getExchangeRate() async {
    final exchangeRate = await injector<CurrencyService>().getExchangeRates();
    setState(() {
      _exchangeRate = exchangeRate;
    });
  }

  Future fetchPersona() async {
    WalletIndex? currentWallet;
    if (widget.request.sourceAddress != null) {
      final walletAddress = await injector<CloudDatabase>()
          .addressDao
          .findByAddress(widget.request.sourceAddress!);
      if (walletAddress != null) {
        currentWallet =
            WalletIndex(WalletStorage(walletAddress.uuid), walletAddress.index);
      }
    }

    if (currentWallet == null) {
      final wc2Topic = widget.request.wc2Topic;
      if (wc2Topic == null) {
        unawaited(injector<TezosBeaconService>()
            .signResponse(widget.request.id, null));
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    unawaited(_estimateFee(currentWallet.wallet, currentWallet.index));

    setState(() {
      _currentWallet = currentWallet;
    });
  }

  Future _estimateFee(WalletStorage wallet, int index) async {
    setState(() {
      _estimateMessage = null;
    });
    try {
      final fee = await injector<TezosService>().estimateOperationFee(
          await wallet.getTezosPublicKey(index: index),
          widget.request.operations!,
          baseOperationCustomFee: feeOption.tezosBaseOperationCustomFee);
      feeOptionValue = FeeOptionValue(
          BigInt.from(fee -
              feeOption.tezosBaseOperationCustomFee +
              baseOperationCustomFeeLow),
          BigInt.from(fee -
              feeOption.tezosBaseOperationCustomFee +
              baseOperationCustomFeeMedium),
          BigInt.from(fee -
              feeOption.tezosBaseOperationCustomFee +
              baseOperationCustomFeeHigh));
      balance = await injector<TezosService>()
          .getBalance(await wallet.getTezosAddress(index: index));
      setState(() {
        _fee = fee;
      });
    } on TezartNodeError catch (err) {
      final message = getTezosErrorMessage(err);
      final tezosError = getTezosError(err);
      log.info(err);
      if (!mounted) {
        return;
      }
      setState(() {
        _estimateMessage = 'estimation_failed'.tr();
      });
      if (tezosError == TezosError.other) {
        setState(() {
          _estimateMessage = 'estimation_failed'.tr();
        });
      }
      unawaited(UIHelper.showInfoDialog(
        context,
        'estimation_failed'.tr(),
        message,
        isDismissible: true,
      ));
    } on TezartHttpError catch (err) {
      log.info(err);
      if (!mounted) {
        return;
      }
      _handleShowErrorEstimationFailed(wallet, index);
    } catch (err) {
      final handleDialog = await showErrorDialogFromException(err);
      if (!mounted) {
        return;
      }
      if (!handleDialog) {
        _handleShowErrorEstimationFailed(wallet, index);
      }
      log.warning(err);
    }
  }

  void _handleShowErrorEstimationFailed(WalletStorage wallet, int index) {
    setState(() {
      _estimateMessage = 'estimation_failed'.tr();
    });
    unawaited(UIHelper.showInfoDialog(
      context,
      'estimation_failed'.tr(),
      'cannot_connect_to_rpc'.tr(),
      isDismissible: true,
      closeButton: 'try_again'.tr(),
      onClose: () {
        _estimateFee(wallet, index);
        Navigator.of(context).pop();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = _fee != null ? _totalAmount + _fee! : null;
    final theme = Theme.of(context);
    final wc2Topic = widget.request.wc2Topic;
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final divider = addDivider(height: 20);
    final tezosAmount = widget.request.operations!.first.amount ?? 0;
    final tezosAmountInUsd = _exchangeRate?.xtzToUsd(tezosAmount);
    final amountText = '${xtzFormatter.format(tezosAmount)} XTZ '
        '($tezosAmountInUsd USD)';
    final totalAmountText = total == null
        ? '- XTZ (- USD)'
        : '${xtzFormatter.format(total)} XTZ '
            '(${_exchangeRate?.xtzToUsd(total)} USD)';
    return PopScope(
      canPop: wc2Topic != null,
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'confirmation'.tr(),
          onBack: () async {
            if (wc2Topic == null) {
              await injector<TezosBeaconService>()
                  .operationResponse(widget.request.id, null);
            }
            if (!context.mounted) {
              return;
            }
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
                              children: [
                                _item(
                                    context: context,
                                    title: 'asset'.tr(),
                                    content: 'tezos_xtz'.tr()),
                                divider,
                                _item(
                                  context: context,
                                  title: 'connection'.tr(),
                                  content: widget.request.appName ?? '',
                                ),
                                divider,
                                _item(
                                    context: context,
                                    title: 'amount'.tr(),
                                    content: amountText),
                                divider,
                                _item(
                                    context: context,
                                    title: 'total_amount'.tr().capitalize(),
                                    content: totalAmountText),
                                divider,
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColor.primaryBlack),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'from'.tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.request.sourceAddress ?? '',
                                        style: theme.textTheme.ppMori400White14,
                                      ),
                                      addDivider(color: AppColor.white),
                                      Text(
                                        'gas_fee2'.tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8),
                                      if (feeOptionValue != null) ...[
                                        feeTable(context)
                                      ],
                                      Visibility(
                                        visible: !(_estimateMessage != null &&
                                            _estimateMessage!.isNotEmpty),
                                        child: gasFeeStatus(theme),
                                      ),
                                      Visibility(
                                        visible: _estimateMessage != null &&
                                            _estimateMessage!.isNotEmpty &&
                                            _currentWallet != null,
                                        child: Row(
                                          children: [
                                            Text(
                                              _estimateMessage ?? '',
                                              style: theme
                                                  .textTheme.ppMori400Grey14
                                                  .copyWith(color: Colors.red),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                unawaited(_estimateFee(
                                                  _currentWallet!.wallet,
                                                  _currentWallet!.index,
                                                ));
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'try_again'
                                                        .tr()
                                                        .toLowerCase(),
                                                    style: theme.textTheme
                                                        .ppMori400White14
                                                        .copyWith(
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: padding,
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'sendH'.tr(),
                            onTap: (_currentWallet != null &&
                                    _fee != null &&
                                    !_isSending)
                                ? _send
                                : null,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isSending)
              const Center(child: CupertinoActivityIndicator())
            else
              const SizedBox(),
          ],
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
        GestureDetector(
          onTap: onValueTap,
          child: Text(
            content,
            style: theme.textTheme.ppMori400Black14.copyWith(
              decoration:
                  (onValueTap != null) ? TextDecoration.underline : null,
              decorationColor: AppColor.primaryBlack,
            ),
          ),
        )
      ],
    );
  }

  Widget gasFeeStatus(ThemeData theme) {
    if (feeOptionValue == null || balance == null) {
      return Text('gas_fee_calculating'.tr(),
          style: theme.textTheme.ppMori400White12);
    }
    bool isValid = balance! > feeOptionValue!.getFee(feeOption).toInt() + 10;
    if (!isValid) {
      return Text('gas_fee_insufficient'.tr(),
          style: theme.textTheme.ppMori400Black12.copyWith(
            color: AppColor.red,
          ));
    }
    return const SizedBox();
  }

  Widget feeTable(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(_gasFee(feeOption), style: theme.textTheme.ppMori400White14),
        const Spacer(),
        GestureDetector(
          onTap: () {
            unawaited(UIHelper.showDialog(
              context,
              'edit_priority'.tr().capitalize(),
              _editPriorityView(context, onSave: () {
                setState(() {
                  feeOption = _selectedPriority;
                });
              }),
              backgroundColor: AppColor.auGreyBackground,
              padding: const EdgeInsets.symmetric(vertical: 32),
              paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets,
            ));
          },
          child: Text('edit_priority'.tr(),
              style: theme.textTheme.ppMori400White14.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColor.white,
              )),
        ),
      ],
    );
  }

  Widget _editPriorityView(BuildContext context, {required Function() onSave}) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return StatefulBuilder(
        builder: (context, setState) => Column(
              children: [
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.LOW, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.MEDIUM, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.HIGH, theme, setState),
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
                      _selectedPriority = feeOption;
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            ));
  }

  Widget getFeeRow(FeeOption feeOption, ThemeData theme, StateSetter setState) {
    final textStyle = theme.textTheme.ppMori400White14;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = feeOption;
        });
      },
      child: Row(
        children: [
          Text(feeOption.name, style: textStyle),
          const Spacer(),
          Text(_gasFee(feeOption), style: textStyle),
          const SizedBox(width: 56),
          AuRadio(
              color: AppColor.white,
              onTap: (FeeOption value) {
                setState(() {
                  _selectedPriority = feeOption;
                });
              },
              value: feeOption,
              groupValue: _selectedPriority)
        ],
      ),
    );
  }

  String _gasFee(FeeOption feeOption) {
    if (feeOptionValue == null) {
      return '';
    }
    final fee = feeOptionValue!.getFee(feeOption).toInt();
    return '${xtzFormatter.format(fee)} XTZ  '
        '(${_exchangeRate?.xtzToUsd(fee)} USD)';
  }
}
