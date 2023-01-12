//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:wallet_connect/wallet_connect.dart';
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
    String messageInUtf8;
    Uint8List message;
    switch (widget.args.type) {
      case WCSignType.MESSAGE:
      case WCSignType.PERSONAL_MESSAGE:
        message = hexToBytes(widget.args.message);
        messageInUtf8 = utf8.decode(message, allowMalformed: true);
        break;
      case WCSignType.TYPED_MESSAGE:
        message = TypedDataUtil.typedDataV4(jsonData: widget.args.message);
        messageInUtf8 = widget.args.message;
        break;
    }

    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.args.wc2Params != null) {
          await injector<Wc2Service>().respondOnReject(
            widget.args.topic,
            reason: "User reject",
          );
        } else {
          injector<WalletConnectService>()
              .rejectRequest(widget.args.peerMeta, widget.args.id);
        }
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () async {
            if (widget.args.wc2Params != null) {
              await injector<Wc2Service>().respondOnReject(
                widget.args.topic,
                reason: "User reject",
              );
            } else {
              injector<WalletConnectService>()
                  .rejectRequest(widget.args.peerMeta, widget.args.id);
            }
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
        body: Container(
          margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
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
                        "signature_request".tr(),
                        style: theme.textTheme.headline1,
                      ),
                      const SizedBox(height: 40.0),
                      Text(
                        "connection".tr(),
                        style: theme.textTheme.headline4,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        widget.args.peerMeta.name,
                        style: theme.textTheme.bodyText2,
                      ),
                      const Divider(height: 32),
                      Text(
                        "message".tr(),
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
      ),
    );
  }

  Widget _signButton(
      BuildContext pageContext, Uint8List message, String messageInUtf8) {
    return BlocConsumer<FeralfileBloc, FeralFileState>(
        listener: (context, state) {
      if (state.event != null) {
        Navigator.of(context).pop();
      }

      /***
       * Temporary ignore checking state with FF, will remove in the future
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
                "uh_oh".tr(),
                "must_create_ff".tr(),
                //"To sign in with a Web3 wallet, you must first create a Feral File account then connect your wallet.",
                ErrorItemState.close), defaultAction: () {
          Navigator.of(context).popUntil((route) =>
              route.settings.name == AppRouter.settingsPage ||
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition);
        });
      }
       */
    }, builder: (context, state) {
      return Row(
        children: [
          Expanded(
            child: AuFilledButton(
              text: "sign".tr().toUpperCase(),
              onPress: () => withDebounce(() async {
                final args = widget.args;
                final wc2Params = args.wc2Params;
                final WalletStorage wallet;
                if (wc2Params != null) {
                  final accountService = injector<AccountService>();
                  wallet = await accountService.getAccountByAddress(
                    chain: wc2Params.chain,
                    address: wc2Params.address,
                  );
                  final signature = await wallet.signMessage(
                    chain: wc2Params.chain,
                    message: wc2Params.message,
                  );
                  await injector<Wc2Service>().respondOnApprove(
                    args.topic,
                    signature,
                  );
                } else {
                  wallet = LibAukDart.getWallet(widget.args.uuid);
                  final String signature;

                  switch (widget.args.type) {
                    case WCSignType.PERSONAL_MESSAGE:
                      signature = await injector<EthereumService>()
                          .signPersonalMessage(wallet, message);
                      break;
                    case WCSignType.MESSAGE:
                    case WCSignType.TYPED_MESSAGE:
                      signature = await injector<EthereumService>()
                          .signMessage(wallet, message);
                      break;
                  }

                  injector<WalletConnectService>().approveRequest(
                      widget.args.peerMeta, widget.args.id, signature);
                }

                if (!mounted) return;

                if (widget.args.peerMeta.url.contains("feralfile")) {
                  if (messageInUtf8.contains("ff_request_connect".tr())) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        widget.args.topic,
                        widget.args.peerMeta.url,
                        wallet,
                        true));
                  } else if (messageInUtf8.contains("ff_request_auth".tr())) {
                    context.read<FeralfileBloc>().add(LinkFFWeb3AccountEvent(
                        widget.args.topic,
                        widget.args.peerMeta.url,
                        wallet,
                        false));
                  } else if (messageInUtf8
                      .contains("ff_request_auth_dis".tr())) {
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
                final notificationEnable =
                    injector<ConfigurationService>().isNotificationEnabled() ??
                        false;
                if (notificationEnable) {
                  showInfoNotification(
                    const Key("signed"),
                    "signed".tr(),
                    frontWidget: SvgPicture.asset(
                      "assets/images/checkbox_icon.svg",
                      width: 24,
                    ),
                  );
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
  final WCSignType type;
  final String uuid;
  final Wc2SignRequestParams? wc2Params;

  WCSignMessagePageArgs(
    this.id,
    this.topic,
    this.peerMeta,
    this.message,
    this.type,
    this.uuid, {
    this.wc2Params,
  });
}
