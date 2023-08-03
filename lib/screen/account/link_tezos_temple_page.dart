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
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/important_note_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
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

class _LinkTezosTemplePageState extends State<LinkTezosTemplePage>
    with AfterLayoutMixin<LinkTezosTemplePage> {
  WebSocketChannel? _websocketChannel;
  Peer? _peer;

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
        appBar: getBackAppBar(
          context,
          onBack: () {
            metricClient.addEvent(MixpanelEvent.backGenerateLink);
            Navigator.of(context).pop();
          },
          title: "temple".tr(),
        ),
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
                        "to_link_temple".tr(),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 15),
                      stepWidget(context, '1', "ltt_generate_a_link".tr()),
                      const SizedBox(height: 15),
                      stepWidget(context, '2', "ltt_when_prompted_by".tr()),
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
