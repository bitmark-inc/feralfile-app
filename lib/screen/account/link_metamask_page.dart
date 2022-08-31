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
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:autonomy_flutter/view/responsive.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "link_to_extension".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "lte_to_link_your".tr(),
                      //"To link your MetaMask browser extension to Autonomy:",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 20),
                    _stepWidget('1', "lte_generate_a_link".tr()),
                    //'Generate a link request and send it to the web browser where you are currently signed in to MetaMask.'),
                    const SizedBox(height: 10),
                    _stepWidget('2', "lte_when_prompted_by".tr()),
                    //'When prompted by MetaMask, approve Autonomy’s permissions requests.'),
                    const SizedBox(height: 40),
                    Row(
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
                    text: "generate_link".tr().toUpperCase(),
                    onPress: () => _generateLinkAndListen(),
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(String stepNumber, String stepGuide) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: theme.textTheme.button,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: theme.textTheme.bodyText1),
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

    final sessionID = const Uuid().v4();

    final link =
        "${Environment.extensionSupportURL}/metamask-wallet?session_id=$sessionID";

    _websocketChannel = WebSocketChannel.connect(
      Uri.parse(
          '${Environment.connectWebsocketURL}/init?session_id=$sessionID'),
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

      if (!mounted) return;

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
