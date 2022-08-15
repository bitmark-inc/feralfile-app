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
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/services/tokens_service.dart';

class LinkLedgerPage extends StatefulWidget {
  final String payload;
  const LinkLedgerPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<LinkLedgerPage> createState() => _LinkLedgerPageState();
}

class _LinkLedgerPageState extends State<LinkLedgerPage> {
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
    final theme = Theme.of(context);
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
                    linkedAccount.ledgerConnection?.ledgerName ?? 'ledger'.tr();

                // SideEffect: pre-fetch tokens
                injector<TokensService>()
                    .fetchTokensForAddresses(linkedAccount.accountNumbers);

                UIHelper.showInfoDialog(context, "account_linked".tr(),
                  "al_autonomy_has_received".tr(namedArgs: {"accountNumbers":linkedAccount.accountNumbers.last.mask(4),"walletName":walletName}),);
                //"Autonomy has received autorization to link to your account ${linkedAccount.accountNumbers.last.mask(4)} in $walletName.");

                const delay = 3;

                Future.delayed(const Duration(seconds: delay), () {
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
                        "already_linked".tr(),
                        "al_you’ve_already".tr(),
                        //"You’ve already linked this account to Autonomy.",
                        ErrorItemState.seeAccount), defaultAction: () {
                  Navigator.of(context).pushNamed(
                      AppRouter.linkedAccountDetailsPage,
                      arguments: event.connection);
                });
              }

              context.read<AccountsBloc>().add(ResetEventEvent());
            },
            child: Container(
                margin: const EdgeInsets.only(
                    top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ledger_wallet".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Text(
                          "select_your_ledger_wallet:".tr(),
                          style: theme.textTheme.headline4,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _deviceList(context),
                  ],
                ))));
  }

  Widget _deviceList(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == true) {
            return StreamBuilder<Iterable<LedgerHardwareWallet>>(
              builder: (context, snapshot) {
                log.info("snapshot: $snapshot");
                final deviceList = snapshot.data;
                if (deviceList == null) {
                  return const CupertinoActivityIndicator();
                }

                List<LedgerHardwareWallet> list = deviceList.toList();

                return ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: ((context, index) {
                      return TappableForwardRow(
                        leftWidget: Text(
                          list[index].name,
                          style: theme.textTheme.bodyText1,
                        ),
                        onTap: () => _onDeviceTap(context, list[index]),
                      );
                    }),
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: list.length);
              },
              stream: injector<LedgerHardwareService>().ledgerWallets(),
            );
          } else {
            return Text(
              "your_bluetooth_device_na".tr(),
              //"Your Bluetooth device is not available at the moment.\n Please make sure it's turned on in the iOS Settings.",
              style: theme.textTheme.headline4,
            );
          }
        } else {
          return const CupertinoActivityIndicator();
        }
      },
      future: injector<LedgerHardwareService>().scanForLedgerWallet(),
    );
  }

  _onDeviceTap(BuildContext context, LedgerHardwareWallet ledger) async {
    UIHelper.showInfoDialog(context, ledger.name, "connecting".tr(),
        feedback: null);
    if (!ledger.isConnected) {
      final result = await injector<LedgerHardwareService>().connect(ledger);
      if (!result) {
        if (!mounted) return;
        UIHelper.hideInfoDialog(context);
        return await _dismissAndShowError(
            context, ledger, "failed_to_connect".tr());
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    // probe for opening app
    try {
      final openingApplication = await LedgerCommand.application(ledger);
      final name = openingApplication["name"];
      late String ledgerAppname;
      switch (widget.payload) {
        case "Tezos":
          ledgerAppname =  "tezos_wallet".tr();
          break;
        default:
          ledgerAppname = widget.payload;
          break;
      }
      if (name != ledgerAppname) {
        if (!mounted) return;
        return await _dismissAndShowError(context, ledger,
            "please_open_the_app".tr(args: [widget.payload]));
            //"Please open the ${widget.payload} app on your ledger.\nIf you haven't installed, please do it in the Ledger Live app.");
      }

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      UIHelper.hideInfoDialog(context);
      UIHelper.showInfoDialog(context, ledger.name,
          "verify_and_approve".tr());
          //"Verify and approve the address sharing on your wallet.");

      late Map<String, dynamic> data;
      switch (widget.payload) {
        case "Ethereum":
          data = await LedgerCommand.getEthAddress(ledger, "44'/60'/0'/0/0",
              verify: true);
          break;
        case "Tezos":
          data = await LedgerCommand.getTezosAddress(ledger, "44'/1729'/0'/0'",
              verify: true);
          break;
        default:
          throw "unknown_blockchain".tr();
      }

      if (!mounted) return;
      if (data["address"] == null) {
        return await _dismissAndShowError(context, ledger,
            "cannot_get_an_address".tr());
            //"Cannot get an address from your ETH app.\nMake sure you have created an account in the Ledger wallet.");
      } else {
        final address = data["address"] as String;
        log.info("Catched an address: $address");
        UIHelper.hideInfoDialog(context);
        context.read<AccountsBloc>().add(LinkLedgerWalletEvent(
            address, widget.payload, ledger.name, ledger.device.id.id, data));

        Vibrate.feedback(FeedbackType.success);
      }
    } catch (error) {
      log.warning("Error when connecting to ledger: $error");
      await injector<LedgerHardwareService>().disconnect(ledger);
      if (!mounted) return;
      return await _dismissAndShowError(context, ledger,
          "failed_to_send_message".tr());
          //"Failed to send message to ledger.\nMake sure your ledger is unlocked.");
    }
  }

  _dismissAndShowError(BuildContext context, LedgerHardwareWallet ledger,
      String errorMessage) async {
    return await Future.delayed(const Duration(milliseconds: 300), () async {
      await UIHelper.showInfoDialog(context, ledger.name, errorMessage,
          autoDismissAfter: 2, feedback: FeedbackType.error);
    });
  }
}
