//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:share/share.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LinkTezosTemplePage extends StatefulWidget {
  const LinkTezosTemplePage({Key? key}) : super(key: key);

  @override
  State<LinkTezosTemplePage> createState() => _LinkTezosTemplePageState();
}

class _LinkTezosTemplePageState extends State<LinkTezosTemplePage> {
  WebSocketChannel? _websocketChannel;
  Peer? _peer;

  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    metricClient.timerEvent(MixpanelEvent.backGenerateLink);
    metricClient.timerEvent(MixpanelEvent.generateLink);
    super.initState();
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
        appBar: getBackAppBar(
          context,
          onBack: () {
            metricClient.addEvent(MixpanelEvent.backGenerateLink);
            Navigator.of(context).pop();
          },
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
                      "linking_to_temple".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "ltt_since_temple_only".tr(),
                      //"Since Temple only exists as a browser extension, you will need to follow these additional steps to link it to Autonomy: ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 20),
                    _stepWidget(context, '1', "ltt_generate_a_link".tr()),
                    //'Generate a link request and send it to the web browser where you are currently signed in to Temple.'),
                    const SizedBox(height: 10),
                    _stepWidget(context, '2', "ltt_when_prompted_by".tr()),
                    //'When prompted by Temple, approve Autonomy’s permissions requests. '),
                    const SizedBox(height: 40),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: wantMoreSecurityWidget(
                                  context, WalletApp.Temple))
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
                    onPress: () {
                      metricClient.addEvent(MixpanelEvent.generateLink);
                      withDebounce(() => _generateLinkAndListen(),
                          debounceTime: 2000000);
                    },
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(
      BuildContext context, String stepNumber, String stepGuide) {
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
    log.info('[LinkTemple][start] _generateLinkAndListen');

    if (_websocketChannel != null) {
      log.info('[LinkTemple][start] close existing channel');
      _websocketChannel!.sink.close();
      _peer = null;
    }

    final tezosBeaconService = injector<TezosBeaconService>();

    final payload = await tezosBeaconService.getPostMessageConnectionURI();
    final sessionID = const Uuid().v4();

    final link =
        "${Environment.extensionSupportURL}?session_id=$sessionID&data=$payload";

    _websocketChannel = WebSocketChannel.connect(
      Uri.parse(
          '${Environment.connectWebsocketURL}/init?session_id=$sessionID'),
    );

    if (_websocketChannel == null) return;

    log.info('[LinkTemple] connect WebSocketChannel and listen');
    _websocketChannel!.stream.listen((event) {
      log.info("[LinkTemple] _websocketChannel: has event $event");
      Map<String, dynamic> message = json.decode(event);

      final payload = message['payload'];

      if (_peer == null) {
        _handlePostMessageOpenChannel(payload);
      } else {
        _handleMessageResponse(_peer!.publicKey, payload);
      }
    });

    Share.share(link);
  }

  Future _handlePostMessageOpenChannel(String payload) async {
    log.info('[LinkTemple][start] _handlePostMessageOpenChannel');
    final result = await injector<TezosBeaconService>()
        .handlePostMessageOpenChannel(payload);

    final peer = result[0];
    final permissionRequestMessage = result[1];

    if (peer is Peer && permissionRequestMessage is String) {
      _peer = peer;
      final wcEvent = {
        'type': 'encrypted_message',
        'payload': permissionRequestMessage
      };
      _websocketChannel?.sink.add(json.encode(wcEvent));

      log.info('[LinkTemple][done] _handlePostMessageOpenChannel');
      if (!mounted) return;
      UIHelper.showInfoDialog(context, "link_requested".tr(),
          "autonomy_has_sent".tr(args: [peer.name]),
          autoDismissAfter: 3, isDismissible: true);
      //"Autonomy has sent a request to ${peer.name} to link to your account. Please open the wallet and authorize the request.");
    }
  }

  Future _handleMessageResponse(String peerPublicKey, String payload) async {
    log.info('[LinkTemple][start] _handleMessageResponse');
    try {
      final result = await injector<TezosBeaconService>()
          .handlePostMessageMessage(peerPublicKey, payload);

      final tzAddress = result[0];
      final response = result[1];

      if (!mounted) return;
      UIHelper.hideInfoDialog(context);

      if (_peer != null &&
          tzAddress is String &&
          response is PermissionResponse) {
        final linkedAccount = await injector<TezosBeaconService>()
            .onPostMessageLinked(tzAddress, _peer!, response);
        _websocketChannel?.sink.add(json.encode({
          'type': 'success',
        }));

        // SideEffect: pre-fetch tokens
        injector<TokensService>().fetchTokensForAddresses([tzAddress]);

        log.info('[LinkTemple][Done] _handleMessageResponse');
        if (!mounted) return;
        UIHelper.showInfoDialog(context, "account_linked".tr(),
            "autonomy_has_received".tr(args: [_peer!.name, tzAddress.mask(4)]));
        //Autonomy has received authorization to link to your account {accountNumbers} in {walletName}.;

        Future.delayed(SHOW_DIALOG_DURATION, () {
          UIHelper.hideInfoDialog(context);

          if (injector<ConfigurationService>().isDoneOnboarding()) {
            Navigator.of(context).pushNamed(AppRouter.nameLinkedAccountPage,
                arguments: linkedAccount);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.nameLinkedAccountPage, (route) => false,
                arguments: linkedAccount);
          }
        });
      } else {
        throw SystemException(
            '[LinkTemple][error] _handleMessageResponse: unexpected param $_peer; $tzAddress; $response');
      }
    } on AbortedException catch (_) {
      UIHelper.hideInfoDialog(context);
      _websocketChannel?.sink.add(json.encode({
        'type': 'aborted',
      }));
      rethrow;
    } on AlreadyLinkedException catch (exception) {
      UIHelper.hideInfoDialog(context);
      showErrorDiablog(
          context,
          ErrorEvent(
              null,
              "already_linked".tr(),
              "al_you’ve_already".tr(),
              //"You’ve already linked this account to Autonomy.",
              ErrorItemState.seeAccount), defaultAction: () {
        Navigator.of(context).pushNamed(AppRouter.linkedAccountDetailsPage,
            arguments: exception.connection);
      });
    } catch (_) {
      rethrow;
    }
  }
}
