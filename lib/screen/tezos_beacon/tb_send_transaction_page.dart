//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/currency_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:tezart/tezart.dart';

class TBSendTransactionPage extends StatefulWidget {
  static const String tag = 'tb_send_transaction';

  final BeaconRequest request;

  const TBSendTransactionPage({Key? key, required this.request})
      : super(key: key);

  @override
  State<TBSendTransactionPage> createState() => _TBSendTransactionPageState();
}

class _TBSendTransactionPageState extends State<TBSendTransactionPage> {
  int? _fee;
  WalletStorage? _currentWallet;
  bool _isSending = false;
  late Wc2Service _wc2Service;
  late FeeOption feeOption;
  bool _showAllFeeOption = false;
  FeeOptionValue? feeOptionValue;
  int? balance;
  final metricClient = injector.get<MetricClientService>();
  late CurrencyExchangeRate exchangeRate;

  @override
  void initState() {
    _wc2Service = injector<Wc2Service>();
    super.initState();
    fetchPersona();
    feeOption = DEFAULT_FEE_OPTION;
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    WalletStorage? currentWallet;
    for (final persona in personas) {
      final address = await persona.wallet().getTezosAddress();
      if (address == widget.request.sourceAddress) {
        currentWallet = persona.wallet();
        break;
      }
    }

    if (currentWallet == null) {
      final wc2Topic = widget.request.wc2Topic;
      if (wc2Topic != null) {
        await _wc2Service.respondOnReject(
          wc2Topic,
          reason: "Address ${widget.request.sourceAddress} not found",
        );
      } else {
        injector<TezosBeaconService>().signResponse(widget.request.id, null);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    _estimateFee(currentWallet);

    setState(() {
      _currentWallet = currentWallet;
    });
  }

  Future _estimateFee(WalletStorage wallet) async {
    try {
      exchangeRate = await injector<CurrencyService>().getExchangeRates();
      final fee = await injector<TezosService>().estimateOperationFee(
          await wallet.getTezosPublicKey(), widget.request.operations!,
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
          .getBalance(await wallet.getTezosAddress());
      setState(() {
        _fee = fee;
      });
    } on TezartNodeError catch (err) {
      log.info(err);
      if (!mounted) return;
      UIHelper.showInfoDialog(
        context,
        "estimation_failed".tr(),
        getTezosErrorMessage(err),
        isDismissible: true,
      );
    } catch (err) {
      if (!mounted) return;
      showErrorDialogFromException(err);
      log.warning(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _fee != null
        ? (widget.request.operations!.first.amount ?? 0) + _fee!
        : null;
    final theme = Theme.of(context);
    final wc2Topic = widget.request.wc2Topic;

    return WillPopScope(
      onWillPop: () async {
        metricClient.addEvent(MixpanelEvent.backConfirmTransaction);
        if (wc2Topic != null) {
          _wc2Service.respondOnReject(
            wc2Topic,
            reason: "User reject",
          );
        } else {
          injector<TezosBeaconService>()
              .operationResponse(widget.request.id, null);
        }
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            metricClient.addEvent(MixpanelEvent.backConfirmTransaction);
            if (wc2Topic != null) {
              _wc2Service.respondOnReject(
                wc2Topic,
                reason: "User reject",
              );
            } else {
              injector<TezosBeaconService>()
                  .operationResponse(widget.request.id, null);
            }
            Navigator.of(context).pop();
          },
        ),
        body: Stack(
          children: [
            Container(
              margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
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
                            "tezos_xtz".tr(),
                            style: theme.textTheme.bodyText2,
                          ),
                          const Divider(height: 32),
                          Text(
                            "from".tr(),
                            style: theme.textTheme.headline4,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            widget.request.sourceAddress ?? "",
                            style: theme.textTheme.bodyText2,
                          ),
                          const Divider(height: 32),
                          Text(
                            "connection".tr(),
                            style: theme.textTheme.headline4,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            widget.request.appName ?? "",
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
                                "${XtzAmountFormatter(widget.request.operations!.first.amount ?? 0).format()} XTZ",
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
                                "${_fee != null ? XtzAmountFormatter(_fee!).format() : "-"} XTZ",
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
                                "${total != null ? XtzAmountFormatter(total).format() : "-"} XTZ",
                                style: theme.textTheme.headline4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          gasFeeStatus(theme),
                          const SizedBox(height: 8.0),
                          if (feeOptionValue != null) feeTable(context),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "sendH".tr().toUpperCase(),
                          onPress: (_currentWallet != null &&
                                  _fee != null &&
                                  !_isSending)
                              ? () async {
                                  setState(() {
                                    _isSending = true;
                                  });
                                  metricClient.addEvent(
                                      MixpanelEvent.confirmTransaction);

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

                                  try {
                                    final txHash = await injector<
                                            TezosService>()
                                        .sendOperationTransaction(
                                            _currentWallet!,
                                            widget.request.operations!,
                                            baseOperationCustomFee: feeOption
                                                .tezosBaseOperationCustomFee);

                                    if (wc2Topic != null) {
                                      _wc2Service.respondOnApprove(
                                        wc2Topic,
                                        txHash ?? "",
                                      );
                                    } else {
                                      injector<TezosBeaconService>()
                                          .operationResponse(
                                              widget.request.id, txHash);
                                    }

                                    final address =
                                        widget.request.sourceAddress;
                                    if (address != null) {
                                      injector<PendingTokenService>()
                                          .checkPendingTezosTokens(address)
                                          .then((hasPendingTokens) {
                                        if (hasPendingTokens) {
                                          injector<NftCollectionBloc>()
                                              .add(RefreshNftCollection());
                                        }
                                      });
                                    }
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  } on TezartNodeError catch (err) {
                                    log.info(err);
                                    if (!mounted) return;
                                    UIHelper.showInfoDialog(
                                      context,
                                      "operation_failed".tr(),
                                      getTezosErrorMessage(err),
                                      isDismissible: true,
                                    );
                                  } catch (err) {
                                    showErrorDialogFromException(err);
                                    log.warning(err);
                                  }

                                  setState(() {
                                    _isSending = false;
                                  });
                                }
                              : null,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            _isSending
                ? const Center(child: CupertinoActivityIndicator())
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget gasFeeStatus(ThemeData theme) {
    if (feeOptionValue == null || balance == null) {
      return Text("gas_fee_calculating".tr(), style: theme.textTheme.headline5);
    }
    bool isValid = balance! > feeOptionValue!.getFee(feeOption).toInt() + 10;
    if (isValid) {
      return Text("gas_fee".tr(), style: theme.textTheme.headline5);
    } else {
      return Text("gas_fee_insufficient".tr(),
          style: theme.textTheme.headline5?.copyWith(
            color: AppColor.red,
          ));
    }
  }

  Widget feeTable(BuildContext context) {
    final theme = Theme.of(context);
    if (!_showAllFeeOption) {
      return Row(
        children: [
          Text(feeOption.name, style: theme.textTheme.atlasBlackBold12),
          const Spacer(),
          Text(_gasFee(feeOption), style: theme.textTheme.atlasBlackBold12),
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
          getFeeRow(FeeOption.LOW, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.MEDIUM, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.HIGH, theme),
        ],
      );
    }
  }

  Widget getFeeRow(FeeOption feeOption, ThemeData theme) {
    final isSelected = feeOption == this.feeOption;
    final textStyle = isSelected
        ? theme.textTheme.atlasBlackBold12
        : theme.textTheme.atlasBlackNormal12;
    return GestureDetector(
      onTap: () {
        setState(() {
          this.feeOption = feeOption;
          _fee = feeOptionValue?.getFee(feeOption).toInt();
        });
      },
      child: Row(
        children: [
          Text(feeOption.name, style: textStyle),
          const Spacer(),
          Text(_gasFee(feeOption), style: textStyle),
          const SizedBox(width: 56),
          SvgPicture.asset(isSelected
              ? "assets/images/radio_btn_selected.svg"
              : "assets/images/radio_btn_not_selected.svg"),
        ],
      ),
    );
  }

  String _gasFee(FeeOption feeOption) {
    if (feeOptionValue == null) return "";
    final fee = feeOptionValue!.getFee(feeOption).toInt();
    return "${XtzAmountFormatter(fee).format()} XTZ  (${exchangeRate.xtzToUsd(fee.toInt())} USD)";
  }
}
