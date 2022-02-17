import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkWalletConnectPage extends StatefulWidget {
  const LinkWalletConnectPage({Key? key}) : super(key: key);

  @override
  State<LinkWalletConnectPage> createState() => _LinkWalletConnectPageState();
}

class _LinkWalletConnectPageState extends State<LinkWalletConnectPage> {
  @override
  void initState() {
    super.initState();

    injector<WalletConnectDappService>().start();
    injector<WalletConnectDappService>().connect();
  }

  @override
  void dispose() {
    super.dispose();
    injector<WalletConnectDappService>().disconnect();
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
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: BlocConsumer<FeralfileBloc, FeralFileState>(
          listener: (context, state) {
            switch (state.linkState) {
              case ActionState.done:
                UIHelper.showInfoDialog(context, 'Account linked',
                    'Autonomy has linked your Feral File account.');

                Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
                  if (injector<ConfigurationService>().isDoneOnboarding()) {
                    Navigator.of(context).popUntil((route) =>
                        route.settings.name == AppRouter.settingsPage);
                  } else {
                    doneOnboarding(context);
                  }
                });
                break;

              default:
                break;
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Scan code to link",
                          style: appTextTheme.headline1,
                        ),
                        addTitleSpace(),
                        Text(
                          "If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                          style: appTextTheme.bodyText1,
                        ),
                        SizedBox(height: 24),
                        _wcQRCode()
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _wcQRCode() {
    return ValueListenableBuilder<String?>(
        valueListenable: injector<WalletConnectDappService>().wcURI,
        builder: (BuildContext context, String? wcURI, Widget? child) {
          return Container(
            alignment: Alignment.center,
            width: 180,
            height: 180,
            child: wcURI != null
                ? QrImage(
                    data: wcURI,
                    version: QrVersions.auto,
                    size: 180.0,
                  )
                : CupertinoActivityIndicator(
                    // color: Colors.black,
                  ),
          );
        });
  }
}
