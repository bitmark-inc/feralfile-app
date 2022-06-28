//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_service.dart';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_transport.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class LinkLedgerPage extends StatefulWidget {
  final String payload;
  const LinkLedgerPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<LinkLedgerPage> createState() => _LinkLedgerPageState(payload);
}

class _LinkLedgerPageState extends State<LinkLedgerPage> {
  final String blockchain;
  _LinkLedgerPageState(this.blockchain);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    injector<LedgerHardwareService>().stopScanning();
    injector<LedgerHardwareService>().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        body: BlocListener<AccountsBloc, AccountsState>(
            listener: (context, state) {
              final event = state.event;
              if (event == null) return;

              if (event is LinkAccountSuccess) {
                final linkedAccount = event.connection;
                final walletName =
                    linkedAccount.ledgerConnection?.ledgerName ?? 'Ledger';

                // SideEffect: pre-fetch tokens
                injector<TokensService>()
                    .fetchTokensForAddresses(linkedAccount.accountNumbers);

                UIHelper.showInfoDialog(context, "Account linked",
                    "Autonomy has received autorization to link to your account ${linkedAccount.accountNumbers.last.mask(4)} in $walletName.");

                final delay = 3;

                Future.delayed(Duration(seconds: delay), () {
                  UIHelper.hideInfoDialog(context);

                  if (injector<ConfigurationService>().isDoneOnboarding()) {
                    Navigator.of(context).pushNamed(
                        AppRouter.nameLinkedAccountPage,
                        arguments: linkedAccount);
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRouter.nameLinkedAccountPage, (route) => false,
                        arguments: linkedAccount);
                  }
                });
              }

              if (event is AlreadyLinkedError) {
                showErrorDiablog(
                    context,
                    ErrorEvent(
                        null,
                        "Already linked",
                        "You’ve already linked this account to Autonomy.",
                        ErrorItemState.seeAccount), defaultAction: () {
                  Navigator.of(context).pushNamed(
                      AppRouter.linkedAccountDetailsPage,
                      arguments: event.connection);
                });
              }

              context.read<AccountsBloc>().add(ResetEventEvent());
            },
            child: Container(
                margin: EdgeInsets.only(
                    top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ledger wallet",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Text(
                          "Select your ledger wallet:",
                          style: appTextTheme.headline4,
                        ),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: 30),
                    _deviceList(context),
                  ],
                ))));
  }

  Widget _deviceList(BuildContext context) {
    return FutureBuilder<bool>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == true)
            return StreamBuilder<Iterable<LedgerHardwareWallet>>(
              builder: (context, snapshot) {
                log.info("snapshot: " + snapshot.toString());
                final deviceList = snapshot.data;
                if (deviceList == null) {
                  return CupertinoActivityIndicator();
                }

                List<LedgerHardwareWallet> list = deviceList.toList();

                return ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: ((context, index) {
                      return TappableForwardRow(
                        leftWidget: Text(
                          list[index].name,
                          style: appTextTheme.bodyText1,
                        ),
                        onTap: () => _onDeviceTap(context, list[index]),
                      );
                    }),
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: list.length);
              },
              stream: injector<LedgerHardwareService>().ledgerWallets(),
            );
          else {
            return Text(
              "Your Bluetooth device is not available at the moment.\n Please make sure it's turned on in the iOS Settings.",
              style: appTextTheme.headline4,
            );
          }
        } else {
          return CupertinoActivityIndicator();
        }
      },
      future: injector<LedgerHardwareService>().scanForLedgerWallet(),
    );
  }

  _onDeviceTap(BuildContext context, LedgerHardwareWallet ledger) async {
    UIHelper.showInfoDialog(context, ledger.name, "Connecting...",
        feedback: null);
    if (!ledger.isConnected) {
      final result = await injector<LedgerHardwareService>().connect(ledger);
      if (!result) {
        UIHelper.hideInfoDialog(context);
        return await _dismissAndShowError(
            context, ledger, "Failed to connect!");
      }

      await Future.delayed(Duration(seconds: 1));
    }

    // probe for opening app
    try {
      final openingApplication = await LedgerCommand.application(ledger);
      final name = openingApplication["name"];
      late String ledgerAppname;
      switch (blockchain) {
        case "Tezos":
          ledgerAppname = "Tezos Wallet";
          break;
        default:
          ledgerAppname = blockchain;
          break;
      }
      if (name != ledgerAppname) {
        return await _dismissAndShowError(context, ledger,
            "Please open the $blockchain app on your ledger.\nIf you haven't installed, please do it in the Ledger Live app.");
      }

      await Future.delayed(Duration(seconds: 1));

      UIHelper.hideInfoDialog(context);
      UIHelper.showInfoDialog(context, ledger.name,
          "Verify and approve the address sharing on your wallet.");

      late Map<String, dynamic> data;
      switch (blockchain) {
        case "Ethereum":
          data = await LedgerCommand.getEthAddress(ledger, "44'/60'/0'/0/0",
              verify: true);
          break;
        case "Tezos":
          data = await LedgerCommand.getTezosAddress(ledger, "44'/1729'/0'/0'",
              verify: true);
          break;
        default:
          throw "Unknown blockchain";
      }

      if (data["address"] == null) {
        return await _dismissAndShowError(context, ledger,
            "Cannot get an address from your ETH app.\nMake sure you have created an account in the Ledger wallet.");
      } else {
        final address = data["address"] as String;
        log.info("Catched an address: $address");
        UIHelper.hideInfoDialog(context);

        context.read<AccountsBloc>().add(LinkLedgerWalletEvent(
            address, blockchain, ledger.name, ledger.device.id.id, data));

        Vibrate.feedback(FeedbackType.success);
      }
    } catch (error) {
      log.warning("Error when connecting to ledger: $error");
      await injector<LedgerHardwareService>().disconnect(ledger);
      return await _dismissAndShowError(context, ledger,
          "Failed to send message to ledger.\nMake sure your ledger is unlocked.");
    }
  }

  _dismissAndShowError(BuildContext context, LedgerHardwareWallet ledger,
      String errorMessage) async {
    return await Future.delayed(Duration(milliseconds: 300), () async {
      await UIHelper.showInfoDialog(context, ledger.name, errorMessage,
          autoDismissAfter: 2, feedback: FeedbackType.error);
    });
  }
}
