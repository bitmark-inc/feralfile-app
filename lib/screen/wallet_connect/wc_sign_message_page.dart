//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/crypto.dart';

class WCSignMessagePage extends StatefulWidget {
  static const String tag = 'wc_sign_message';

  final WCSignMessagePageArgs args;

  const WCSignMessagePage({Key? key, required this.args}) : super(key: key);

  @override
  State<WCSignMessagePage> createState() => _WCSignMessagePageState();
}

class _WCSignMessagePageState extends State<WCSignMessagePage> {
  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.args.message);
    final messageInUtf8 = utf8.decode(message, allowMalformed: true);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>()
              .rejectRequest(widget.args.peerMeta, widget.args.id);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
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
                      "Connection",
                      style: theme.textTheme.headline4,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.args.peerMeta.name,
                      style: theme.textTheme.bodyText2,
                    ),
                    const Divider(height: 32),
                    Text(
                      "Message",
                      style: theme.textTheme.headline4,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
                      style: theme.textTheme.bodyText2,
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
        // because user may be wanting to login FeralFile; so skip to show this error
        // Thread: https://bitmark.slack.com/archives/C034EPS6CLS/p1648218027439049
        Navigator.of(context).pop();
        return;
      } else if (event is FFUnlinked) {
        Navigator.of(context).pop();
        return;
      } else if (event is FFNotConnected) {
        showErrorDiablog(
            context,
            ErrorEvent(
                null,
                "Uh-oh!",
                "To sign in with a Web3 wallet, you must first create a Feral File account then connect your wallet.",
                ErrorItemState.close), defaultAction: () {
          Navigator.of(context).popUntil((route) =>
              route.settings.name == AppRouter.settingsPage ||
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition);
        });
      }
    }, builder: (context, state) {
      final networkInjector = injector<NetworkConfigInjector>();

      return Row(
        children: [
          Expanded(
            child: AuFilledButton(
              text: "Sign".toUpperCase(),
              onPress: () => withDebounce(() async {
                final WalletStorage wallet =
                    LibAukDart.getWallet(widget.args.uuid);
                final signature = await networkInjector
                    .I<EthereumService>()
                    .signPersonalMessage(wallet, message);

                injector<WalletConnectService>().approveRequest(
                    widget.args.peerMeta, widget.args.id, signature);

                if (!mounted) return;

                if (widget.args.peerMeta.url.contains("feralfile")) {
                  if (messageInUtf8.contains(
                      'Feral File is requesting to connect your wallet address')) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        widget.args.topic,
                        widget.args.peerMeta.url,
                        wallet,
                        true));
                  } else if (messageInUtf8.contains(
                      'Feral File is requesting authorization to sign in')) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        widget.args.topic,
                        widget.args.peerMeta.url,
                        wallet,
                        false));
                  } else if (messageInUtf8.contains(
                      "Feral File is requesting authorization to disconnect your wallet from your Feral File account")) {
                    final matched =
                        RegExp("Wallet address:\\n(0[xX][0-9a-fA-F]+)\\n")
                            .firstMatch(messageInUtf8);
                    final address = matched?.group(0)?.split("\n")[1].trim();
                    if (address == null) {
                      Navigator.of(context).pop();
                      return;
                    }
                    context.read<FeralfileBloc>().add(UnlinkFFWeb3AccountEvent(
                        source: widget.args.peerMeta.url, address: address));
                  } else {
                    Navigator.of(context).pop();
                  }
                  // result in listener - linkState.done
                } else {
                  Navigator.of(context).pop();
                }
              }),
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
