//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/important_note_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LinkMetamaskPage extends StatefulWidget {
  const LinkMetamaskPage({Key? key}) : super(key: key);

  @override
  State<LinkMetamaskPage> createState() => _LinkMetamaskPageState();
}

class _LinkMetamaskPageState extends State<LinkMetamaskPage>
    with AfterLayoutMixin<LinkMetamaskPage> {
  WebSocketChannel? _websocketChannel;

  final metricClient = injector.get<MetricClientService>();

  @override
  void afterFirstLayout(BuildContext context) {
    metricClient.timerEvent(MixpanelEvent.backGenerateLink);
    metricClient.timerEvent(MixpanelEvent.generateLink);
  }

  @override
  void dispose() {
    super.dispose();

    _websocketChannel?.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: getBackAppBar(context, onBack: () {
          metricClient.addEvent(MixpanelEvent.backGenerateLink);
          Navigator.of(context).pop();
        }, title: "metamask".tr()),
        body: Container(
          margin: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Text(
                        "link_to_extension".tr(),
                        style: theme.textTheme.ppMori700Black24,
                      ),
                      addTitleSpace(),
                      Text(
                        "lte_to_link_your".tr(),
                        //"To link your MetaMask browser extension to Autonomy:",
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 15),
                      stepWidget(context, '1', "lte_generate_a_link".tr()),
                      //'Generate a link request and send it to the web browser where you are currently signed in to MetaMask.'),
                      const SizedBox(height: 15),
                      stepWidget(context, '2', "lte_when_prompted_by".tr()),
                      //'When prompted by MetaMask, approve Autonomy’s permissions requests.'),
                      const SizedBox(height: 30),
                      ImportantNoteView(
                        note: "please_note_link_only_desktop".tr(),
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                text: "generate_link".tr(),
                onTap: () {
                  metricClient.addEvent(MixpanelEvent.generateLink);
                  withDebounce(() => _generateLinkAndListen(),
                      debounceTime: 2000000);
                },
              ),
            ],
          ),
        ));
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
