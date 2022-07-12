//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LinkMetamaskPage extends StatefulWidget {
  const LinkMetamaskPage({Key? key}) : super(key: key);

  @override
  State<LinkMetamaskPage> createState() => _LinkMetamaskPageState();
}

class _LinkMetamaskPageState extends State<LinkMetamaskPage> {
  WebSocketChannel? _websocketChannel;

  @override
  void dispose() {
    super.dispose();

    _websocketChannel?.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link to extension",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "To link your MetaMask browser extension to Autonomy:",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 20),
                    _stepWidget('1',
                        'Generate a link request and send it to the web browser where you are currently signed in to MetaMask.'),
                    SizedBox(height: 10),
                    _stepWidget('2',
                        'When prompted by MetaMask, approve Autonomy’s permissions requests.'),
                    SizedBox(height: 40),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: wantMoreSecurityWidget(
                                  context, WalletApp.MetaMask))
                        ]),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "GENERATE LINK".toUpperCase(),
                    onPress: () => _generateLinkAndListen(),
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(String stepNumber, String stepGuide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: appTextTheme.caption,
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: appTextTheme.bodyText1),
        )
      ],
    );
  }

  // MARK: - Handlers
  Future _generateLinkAndListen() async {
    log.info('[LinkMetamaskBrowser][start] _generateLinkAndListen');

    if (_websocketChannel != null) {
      log.info('[LinkMetamaskBrowser][start] close existing channel');
      _websocketChannel!.sink.close();
    }

    final sessionID = Uuid().v4();

    final network = injector<ConfigurationService>().getNetwork();
    final link = Environment.networkedExtensionSupportURL(network) +
        "/metamask-wallet?session_id=$sessionID";

    _websocketChannel = WebSocketChannel.connect(
      Uri.parse(Environment.networkedWebsocketURL(network) +
          '/init?session_id=$sessionID'),
    );

    if (_websocketChannel == null) return;

    log.info('[LinkMetamaskBrowser] connect WebSocketChannel and listen');
    _websocketChannel!.stream.listen((event) {
      log.info("[LinkMetamaskBrowser] _websocketChannel: has event $event");
      Map<String, dynamic> message = json.decode(event);

      switch (message['type']) {
        case 'success':
          _handleMessageResponse(message['payload']);
          break;
        case 'aborted':
          UIHelper.showAbortedByUser(context);
          break;
        default:
          break;
      }
    });

    Share.share(link);
  }

  Future _handleMessageResponse(String payload) async {
    try {
      final linkedAccount = await injector<AccountService>()
          .linkETHBrowserWallet(payload, WalletApp.MetaMask);

      _websocketChannel?.sink.add(json.encode({
        'type': 'success',
      }));

      UIHelper.showAccountLinked(
          context, linkedAccount, WalletApp.MetaMask.rawValue);
    } on AlreadyLinkedException catch (exception) {
      UIHelper.showAlreadyLinked(context, exception.connection);
    } catch (_) {
      UIHelper.hideInfoDialog(context);
      rethrow;
    }
  }
}
