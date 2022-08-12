//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/biometrics_util.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:local_auth/local_auth.dart';
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
  TezosWallet? _currentWallet;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    fetchPersona();
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    final wallets = await Future.wait(
        personas.map((e) => LibAukDart.getWallet(e.uuid).getTezosWallet()));

    final currentWallet = wallets.firstWhereOrNull(
        (element) => element.address == widget.request.sourceAddress);

    if (currentWallet == null) {
      injector<TezosBeaconService>().signResponse(widget.request.id, null);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    _estimateFee(currentWallet);

    setState(() {
      _currentWallet = currentWallet;
    });
  }

  Future _estimateFee(TezosWallet wallet) async {
    try {
      final fee = await injector<TezosService>()
          .estimateOperationFee(wallet, widget.request.operations!);
      setState(() {
        _fee = fee;
      });
    } on TezartNodeError catch (err) {
      log.info(err);
      UIHelper.showInfoDialog(
        context,
        "Estimation failed",
        getTezosErrorMessage(err),
        isDismissible: true,
      );
    } catch (err) {
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

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>()
              .operationResponse(widget.request.id, null);
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          Container(
            margin: pageEdgeInsetsWithSubmitButton,
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
                          "Confirm",
                          style: theme.textTheme.headline1,
                        ),
                        const SizedBox(height: 40.0),
                        Text(
                          "Asset",
                          style: theme.textTheme.headline4,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          "Tezos (XTZ)",
                          style: theme.textTheme.bodyText2,
                        ),
                        const Divider(height: 32),
                        Text(
                          "From",
                          style: theme.textTheme.headline4,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          widget.request.sourceAddress ?? "",
                          style: theme.textTheme.bodyText2,
                        ),
                        const Divider(height: 32),
                        Text(
                          "Connection",
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
                              "Send",
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
                              "Gas fee",
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
                              "Total Amount",
                              style: theme.textTheme.headline4,
                            ),
                            Text(
                              "${total != null ? XtzAmountFormatter(total).format() : "-"} XTZ",
                              style: theme.textTheme.headline4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "Send".toUpperCase(),
                        onPress: (_currentWallet != null &&
                                _fee != null &&
                                !_isSending)
                            ? () async {
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
                                              'Authentication for "Autonomy"');
                                  if (!didAuthenticate) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                    return;
                                  }
                                }

                                try {
                                  final txHash =
                                      await injector<TezosService>()
                                          .sendOperationTransaction(
                                              _currentWallet!,
                                              widget.request.operations!);

                                  injector<TezosBeaconService>()
                                      .operationResponse(
                                          widget.request.id, txHash);
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                } on TezartNodeError catch (err) {
                                  log.info(err);
                                  if (!mounted) return;
                                  UIHelper.showInfoDialog(
                                    context,
                                    "Operation failed",
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
          _isSending ? const Center(child: CupertinoActivityIndicator()) : const SizedBox(),
        ],
      ),
    );
  }
}
