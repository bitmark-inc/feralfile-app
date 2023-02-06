//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:autonomy_flutter/service/account_service.dart';

class AUSignMessagePage extends StatefulWidget {
  static const String tag = 'au_sign_message';
  final Wc2Request request;

  const AUSignMessagePage({Key? key, required this.request}) : super(key: key);

  @override
  State<AUSignMessagePage> createState() => _AUSignMessagePageState();
}

class _AUSignMessagePageState extends State<AUSignMessagePage> {
  WalletStorage? _currentPersona;

  @override
  void initState() {
    super.initState();
    fetchPersona();
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    WalletStorage? currentWallet;
    for (final persona in personas) {
      final addressDID = await persona.wallet().getAccountDID();
      if (addressDID == widget.request.params['address']) {
        currentWallet = persona.wallet();
        break;
      }
    }

    if (currentWallet == null) {
      await _rejectRequest(
        reason:
            "No wallet found for address ${widget.request.params['address']}",
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentPersona = currentWallet;
    });
  }

  Future _rejectRequest({String? reason}) async {
    log.info("[AUSignMessagePage] _rejectRequest: $reason");
    await injector<Wc2Service>().respondOnReject(
      widget.request.topic,
      reason: reason,
    );
  }

  Future _handleAuSignRequest({required Wc2Request request}) async {
    final accountService = injector<AccountService>();
    final params = Wc2SignRequestParams.fromJson(request.params);
    final address = params.address;
    final chain = params.chain;
    final account = await accountService.getAccountByAddress(
      chain: chain,
      address: address,
    );
    final wc2Service = injector<Wc2Service>();
    try {
      final signature = await account.signMessage(
        chain: chain,
        message: params.message,
      );
      wc2Service.respondOnApprove(request.topic, signature);
    } catch (e) {
      log.info("[Wc2RequestPage] _handleAuSignRequest $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewMessage = widget.request.params['message'];

    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        await _rejectRequest(reason: "User reject");
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            _rejectRequest(reason: "User reject");
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
                        style: theme.textTheme.displayLarge,
                      ),
                      const SizedBox(height: 40.0),
                      Text(
                        "connection".tr(),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16.0),
                      // Text(
                      //   widget.request.appName ?? "",
                      //   style: theme.textTheme.bodyMedium,
                      // ),
                      const Divider(height: 32),
                      Text(
                        "message".tr(),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        viewMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "sign".tr().toUpperCase(),
                      onPress: _currentPersona != null
                          ? () => withDebounce(() async {
                                _handleAuSignRequest(request: widget.request);
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                final notificationEnable =
                                    injector<ConfigurationService>()
                                            .isNotificationEnabled() ??
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
                              })
                          : null,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
