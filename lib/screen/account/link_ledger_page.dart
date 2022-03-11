import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_service.dart';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_transport.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class LinkLedgerPage extends StatefulWidget {
  const LinkLedgerPage({Key? key}) : super(key: key);

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
    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        body: StreamBuilder<Iterable<LedgerHardwareWallet>>(
          builder: (context, snapshot) => Container(
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
                  Text(
                    "Select your ledger wallet to start:",
                    style: appTextTheme.headline4,
                  ),
                  SizedBox(height: 30),
                  if (snapshot.connectionState == ConnectionState.waiting) ...[
                    Expanded(
                        child: Center(
                            child: CupertinoActivityIndicator(
                      color: Colors.grey,
                    )))
                  ] else ...[
                    _deviceList(context, snapshot.data),
                  ],
                ],
              )),
          stream: injector<LedgerHardwareService>().scanForLedgerWallet(),
        ));
  }

  Widget _deviceList(
      BuildContext context, Iterable<LedgerHardwareWallet>? deviceList) {
    if (deviceList == null) {
      return Container();
    }

    List<LedgerHardwareWallet> list = deviceList.toList();

    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: ((context, index) {
          return Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: TappableForwardRow(
                leftWidget: Text(
                  list[index].name,
                  style: appTextTheme.bodyText1,
                ),
                onTap: () => _onDeviceTap(context, list[index]),
              ));
        }),
        separatorBuilder: (context, index) => Divider(),
        itemCount: list.length);
  }

  _onDeviceTap(BuildContext context, LedgerHardwareWallet ledger) async {
    UIHelper.showInfoDialog(context, ledger.name, "Connecting...");
    if (!ledger.isConnected) {
      final result = await injector<LedgerHardwareService>().connect(ledger);
      if (!result) {
        UIHelper.hideInfoDialog(context);
        return await _dismissAndShowError(
            context, ledger, "Failed to connect!");
      }
    }

    // probe for opening app
    try {
      final openingApplication = await LedgerCommand.application(ledger);
      final name = openingApplication["name"];
      if (name != "Bitcoin") {
        return await _dismissAndShowError(context, ledger,
            "Please open the ETH app on your ledger.\nIf you haven't installed, please do it in the Ledger Live app.");
      }

      await Future.delayed(Duration(seconds: 1));

      final pubkey = await LedgerCommand.pubKey(ledger, []);
      if (pubkey["address"] == null) {
        return await _dismissAndShowError(context, ledger,
            "Cannot get an address from your ETH app. Please make sure you have created an account in the Ledger wallet.");
      } else {
        log.info("Catched an address: ${pubkey["address"]}");
        Vibrate.feedback(FeedbackType.success);
      }
    } catch (error) {
      log.warning("Error when connecting to ledger: $error");
      await injector<LedgerHardwareService>().disconnect(ledger);
      return await _dismissAndShowError(
          context, ledger, "Failed to send message to ledger.");
    }
  }

  _dismissAndShowError(BuildContext context, LedgerHardwareWallet ledger,
      String errorMessage) async {
    return await Future.delayed(Duration(milliseconds: 300), () async {
      Vibrate.feedback(FeedbackType.error);
      await UIHelper.showInfoDialog(context, ledger.name, errorMessage,
          autoDismissAfter: 2);
    });
  }
}
