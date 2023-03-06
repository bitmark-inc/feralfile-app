//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/currency_exchange.dart';
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
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:tezart/tezart.dart';
import 'package:url_launcher/url_launcher.dart';

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
  WalletIndex? _currentWallet;
  bool _isSending = false;
  late Wc2Service _wc2Service;
  late FeeOption feeOption;
  FeeOptionValue? feeOptionValue;
  int? balance;
  final metricClient = injector.get<MetricClientService>();
  late CurrencyExchangeRate exchangeRate;
  late FeeOption _selectedPriority;

  @override
  void dispose() {
    super.dispose();
    Future.delayed(const Duration(seconds: 2), () {
      injector<TezosBeaconService>().handleNextRequest(isRemoved: true);
    });
  }

  @override
  void initState() {
    _wc2Service = injector<Wc2Service>();
    super.initState();
    fetchPersona();
    feeOption = DEFAULT_FEE_OPTION;
    _selectedPriority = feeOption;
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    WalletIndex? currentWallet;
    if (widget.request.sourceAddress != null) {
      for (final persona in personas) {
        final addresses = await persona.getTezosAddresses();
        if (addresses.contains(widget.request.sourceAddress)) {
          currentWallet = WalletIndex(persona.wallet(),
              addresses.indexOf(widget.request.sourceAddress!));
          break;
        }
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

    _estimateFee(currentWallet.wallet, currentWallet.index);

    setState(() {
      _currentWallet = currentWallet;
    });
  }

  Future _estimateFee(WalletStorage wallet, int index) async {
    try {
      exchangeRate = await injector<CurrencyService>().getExchangeRates();
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
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final divider = addDivider(height: 20);

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
          title: "confirmation".tr(),
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
                              "purchase_artwork".tr(),
                              style: theme.textTheme.ppMori400Black16,
                            ),
                          ),
                          const SizedBox(height: 64.0),
                          divider,
                          Padding(
                            padding: padding,
                            child: Column(
                              children: [
                                _item(
                                    context: context,
                                    title: "asset".tr(),
                                    content: "tezos_xtz".tr()),
                                divider,
                                _item(
                                  context: context,
                                  title: "connection".tr(),
                                  content: widget.request.appName ?? "",
                                ),
                                divider,
                                _item(
                                    context: context,
                                    title: "amount".tr(),
                                    content:
                                        "${XtzAmountFormatter(widget.request.operations!.first.amount ?? 0).format()} XTZ"),
                                divider,
                                _item(
                                    context: context,
                                    title: "total_amount".tr().capitalize(),
                                    content:
                                        "${total != null ? XtzAmountFormatter(total).format() : "-"} XTZ"),
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
                                        "from".tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        widget.request.sourceAddress ?? "",
                                        style: theme.textTheme.ppMori400White14,
                                      ),
                                      addDivider(color: AppColor.white),
                                      Text(
                                        "gas_fee2".tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8.0),
                                      if (feeOptionValue != null) ...[
                                        feeTable(context)
                                      ],
                                      gasFeeStatus(theme),
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
                            text: "sendH".tr(),
                            onTap: (_currentWallet != null &&
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
                                              _currentWallet!.wallet,
                                              _currentWallet!.index,
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

    if (onValueTap == null && tapLink != null) {
      final uri = Uri.parse(tapLink);
      onValueTap = () => launchUrl(uri,
          mode: forceSafariVC == true
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault);
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
                    (onValueTap != null) ? TextDecoration.underline : null),
          ),
        )
      ],
    );
  }

  Widget gasFeeStatus(ThemeData theme) {
    if (feeOptionValue == null || balance == null) {
      return Text("gas_fee_calculating".tr(),
          style:
              theme.textTheme.headlineSmall?.copyWith(color: AppColor.white));
    }
    bool isValid = balance! > feeOptionValue!.getFee(feeOption).toInt() + 10;
    if (!isValid) {
      return Text("gas_fee_insufficient".tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
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
            UIHelper.showDialog(
              context,
              "edit_priority".tr().capitalize(),
              _editPriorityView(context, onSave: () {
                setState(() {
                  feeOption = _selectedPriority;
                });
              }),
              backgroundColor: AppColor.auGreyBackground,
              padding: const EdgeInsets.symmetric(vertical: 32),
              paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets,
            );
          },
          child: Text("edit_priority".tr(),
              style: theme.textTheme.ppMori400White14.copyWith(
                decoration: TextDecoration.underline,
              )),
        ),
      ],
    );
  }

  Widget _editPriorityView(BuildContext context, {required Function() onSave}) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return StatefulBuilder(builder: (context, setState) {
      return Column(
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
              text: "save_priority".tr(),
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
              text: "cancel".tr(),
              onTap: () {
                _selectedPriority = feeOption;
                Navigator.of(context).pop();
              },
            ),
          )
        ],
      );
    });
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
    if (feeOptionValue == null) return "";
    final fee = feeOptionValue!.getFee(feeOption).toInt();
    return "${XtzAmountFormatter(fee).format()} XTZ  (${exchangeRate.xtzToUsd(fee.toInt())} USD)";
  }
}
