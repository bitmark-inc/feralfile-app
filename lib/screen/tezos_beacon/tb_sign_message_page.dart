//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';

class TBSignMessagePage extends StatefulWidget {
  static const String tag = 'tb_sign_message';
  final BeaconRequest request;

  const TBSignMessagePage({Key? key, required this.request}) : super(key: key);

  @override
  State<TBSignMessagePage> createState() => _TBSignMessagePageState();
}

class _TBSignMessagePageState extends State<TBSignMessagePage> {
  WalletStorage? _currentPersona;

  @override
  void initState() {
    super.initState();
    fetchPersona();
  }

  @override
  void dispose() {
    super.dispose();
    Future.delayed(const Duration(seconds: 2), () {
      injector<TezosBeaconService>().handleNextRequest(isRemove: true);
    });
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    WalletStorage? currentWallet;
    for (final persona in personas) {
      final address = await persona.wallet().getTezosAddress();
      if (address == widget.request.sourceAddress) {
        currentWallet = persona.wallet();
        break;
      }
    }

    if (currentWallet == null) {
      await _rejectRequest(
        reason: "No wallet found for address ${widget.request.sourceAddress}",
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
    log.info("[TBSignMessagePage] _rejectRequest: $reason");
    if (widget.request.wc2Topic != null) {
      await injector<Wc2Service>().respondOnReject(
        widget.request.wc2Topic!,
        reason: reason,
      );
    } else {
      await injector<TezosBeaconService>().signResponse(
        widget.request.id,
        null,
      );
    }
  }

  Future _approveRequest({required String signature}) async {
    log.info("[TBSignMessagePage] _approveRequest");
    if (widget.request.wc2Topic != null) {
      await injector<Wc2Service>().respondOnApprove(
        widget.request.wc2Topic!,
        signature,
      );
    } else {
      await injector<TezosBeaconService>().signResponse(
        widget.request.id,
        signature,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.request.payload!);
    final Uint8List viewMessage = message.length > 6 &&
            message.sublist(0, 2).equals(Uint8List.fromList([5, 1]))
        ? message.sublist(6)
        : message;
    final messageInUtf8 = utf8.decode(viewMessage, allowMalformed: true);

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
          title: "signature_request".tr(),
        ),
        body: Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: _tbAppInfo(widget.request),
                      ),
                      const SizedBox(height: 60),
                      addOnlyDivider(),
                      const SizedBox(height: 30),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: Text(
                          "message".tr(),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 22),
                          decoration: BoxDecoration(
                            color: AppColor.auLightGrey,
                            borderRadius: BorderRadiusGeometry.lerp(
                                const BorderRadius.all(Radius.circular(5)),
                                const BorderRadius.all(Radius.circular(5)),
                                5),
                          ),
                          child: Text(
                            messageInUtf8,
                            style: theme.textTheme.ppMori400Black14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: "sign".tr(),
                        onTap: _currentPersona != null
                            ? () => withDebounce(() async {
                                  final signature =
                                      await injector<TezosService>()
                                          .signMessage(
                                              _currentPersona!, message);
                                  await _approveRequest(signature: signature);
                                  if (!mounted) return;

                                  final metricClient =
                                      injector.get<MetricClientService>();

                                  metricClient.addEvent(
                                    "Sign In",
                                    hashedData: {"uuid": widget.request.id},
                                  );
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
                                    Future.delayed(const Duration(seconds: 3),
                                        () {
                                      showInfoNotification(
                                          const Key("switchBack"),
                                          "you_all_set".tr());
                                    });
                                  }
                                })
                            : null,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _tbAppInfo(BeaconRequest request) {
    final theme = Theme.of(context);

    return Row(
      children: [
        request.icon != null
            ? CachedNetworkImage(
                imageUrl: request.icon!,
                width: 64.0,
                height: 64.0,
                errorWidget: (context, url, error) => SvgPicture.asset(
                  "assets/images/tezos_social_icon.svg",
                  width: 64.0,
                  height: 64.0,
                ),
              )
            : SvgPicture.asset(
                "assets/images/tezos_social_icon.svg",
                width: 64.0,
                height: 64.0,
              ),
        const SizedBox(width: 24.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.appName ?? "",
                  style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }
}
