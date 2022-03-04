import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/crypto.dart';

class WCSignMessagePage extends StatelessWidget {
  static const String tag = 'wc_sign_message';

  final WCSignMessagePageArgs args;

  const WCSignMessagePage({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(args.message);
    final messageInUtf8 = utf8.decode(message, allowMalformed: true);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>()
              .rejectRequest(args.peerMeta, args.id);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.0),
                    Text(
                      "Confirm",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 40.0),
                    Text(
                      "Connection",
                      style: appTextTheme.headline4,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      args.peerMeta.name,
                      style: appTextTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Message",
                      style: appTextTheme.headline4,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: appTextTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
            _signButton(context, message, messageInUtf8),
          ],
        ),
      ),
    );
  }

  Widget _signButton(
      BuildContext pageContext, Uint8List message, String messageInUtf8) {
    return BlocConsumer<FeralfileBloc, FeralFileState>(
        listener: (context, state) {
      final event = state.event;
      if (event == null) return;

      if (event is LinkAccountSuccess) {
        Navigator.of(context).pop();
        return;
      } else if (event is AlreadyLinkedError) {
        showErrorDiablog(
            context,
            ErrorEvent(
                null,
                "Already linked",
                "You’ve already linked this account to Autonomy.",
                ErrorItemState.seeAccount), defaultAction: () {
          Navigator.of(context).pushReplacementNamed(
              AppRouter.linkedAccountDetailsPage,
              arguments: event.connection);
        }, cancelAction: () {
          Navigator.of(context).pop();
        });

        return;
      } else if (event is FFNotConnected) {
        showErrorDiablog(
            context,
            ErrorEvent(
                null,
                "Uh-oh!",
                "To sign in with a Web3 wallet, you must first create a Feral File account then connect your wallet.",
                ErrorItemState.close), defaultAction: () {
          Navigator.of(context).popUntil(
              (route) => route.settings.name == AppRouter.settingsPage);
        });
      }
    }, builder: (context, state) {
      final networkInjector = injector<NetworkConfigInjector>();

      return Row(
        children: [
          Expanded(
            child: AuFilledButton(
              text: "Sign".toUpperCase(),
              onPress: () async {
                final WalletStorage wallet = LibAukDart.getWallet(args.uuid);
                final signature = await networkInjector
                    .I<EthereumService>()
                    .signPersonalMessage(wallet, message);

                injector<WalletConnectService>()
                    .approveRequest(args.peerMeta, args.id, signature);

                if (args.peerMeta.url.contains("feralfile")) {
                  if (messageInUtf8.contains(
                      'Feral File is requesting to connect your wallet address')) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        args.topic, args.peerMeta.url, wallet, true));
                  } else if (messageInUtf8.contains(
                      'Feral File is requesting authorization to sign in')) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        args.topic, args.peerMeta.url, wallet, false));
                  } else {
                    Navigator.of(context).pop();
                  }
                  // result in listener - linkState.done
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          )
        ],
      );
    });
  }
}

class WCSignMessagePageArgs {
  final int id;
  final String topic;
  final WCPeerMeta peerMeta;
  final String message;
  final String uuid;

  WCSignMessagePageArgs(
      this.id, this.topic, this.peerMeta, this.message, this.uuid);
}
