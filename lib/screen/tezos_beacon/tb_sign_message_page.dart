//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';

class TBSignMessagePage extends StatefulWidget {
  static const String tag = 'tb_sign_message';
  final BeaconRequest request;

  const TBSignMessagePage({required this.request, super.key});

  @override
  State<TBSignMessagePage> createState() => _TBSignMessagePageState();
}

class _TBSignMessagePageState extends State<TBSignMessagePage> {
  WalletIndex? _currentPersona;

  @override
  void initState() {
    super.initState();
    unawaited(fetchPersona());
  }

  @override
  void dispose() {
    super.dispose();
    Future.delayed(const Duration(seconds: 2), () {
      unawaited(
          injector<TezosBeaconService>().handleNextRequest(isRemoved: true));
    });
  }

  Future fetchPersona() async {
    WalletIndex? currentWallet;
    if (widget.request.sourceAddress != null) {
      final walletAddress = await injector<CloudDatabase>()
          .addressDao
          .findByAddress(widget.request.sourceAddress!);
      if (walletAddress != null) {
        currentWallet =
            WalletIndex(WalletStorage(walletAddress.uuid), walletAddress.index);
      }
    }

    if (currentWallet == null) {
      await _rejectRequest(
        reason: 'No wallet found for address ${widget.request.sourceAddress}',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _currentPersona = currentWallet;
    });
  }

  Future _rejectRequest({String? reason}) async {
    log.info('[TBSignMessagePage] _rejectRequest: $reason');
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
    log.info('[TBSignMessagePage] _approveRequest');
    if (widget.request.wc2Topic != null) {
      await injector<Wc2Service>().respondOnApprove(
        widget.request.wc2Topic!,
        signature,
      );
    } else {
      final tezosService = injector<TezosBeaconService>();
      await tezosService.signResponse(
        widget.request.id,
        signature,
      );
    }
  }

  Future<void> _sign(BuildContext context, Uint8List message) async {
    final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
    if (!didAuthenticate) {
      return;
    }
    final signature = await injector<TezosService>()
        .signMessage(_currentPersona!.wallet, _currentPersona!.index, message);
    await _approveRequest(signature: signature);
    log.info('[TBSignMessagePage] _sign: $signature');
    if (!mounted) {
      return;
    }

    final metricClient = injector.get<MetricClientService>();

    unawaited(metricClient.addEvent(
      'Sign In',
      hashedData: {'uuid': widget.request.id},
    ));
    Navigator.of(context).pop(true);
    showInfoNotification(
      const Key('signed'),
      'signed'.tr(),
      frontWidget: SvgPicture.asset(
        'assets/images/checkbox_icon.svg',
        width: 24,
      ),
    );
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
        await _rejectRequest(reason: 'User reject');
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
            unawaited(_rejectRequest(reason: 'User reject'));
            Navigator.of(context).pop(false);
          },
          title: 'signature_request'.tr(),
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
                        child: _tbAppInfo(context, widget.request),
                      ),
                      const SizedBox(height: 60),
                      addOnlyDivider(),
                      const SizedBox(height: 30),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: Text(
                          'message'.tr(),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 22),
                          decoration: BoxDecoration(
                            color: AppColor.auLightGrey,
                            borderRadius: BorderRadius.circular(5),
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
                        text: 'sign'.tr(),
                        onTap: _currentPersona != null
                            ? () => withDebounce(
                                () => unawaited(_sign(context, message)))
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

  Widget _tbAppInfo(BuildContext context, BeaconRequest request) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (request.icon != null)
          CachedNetworkImage(
            imageUrl: request.icon!,
            width: 64,
            height: 64,
            errorWidget: (context, url, error) => SvgPicture.asset(
              'assets/images/tezos_social_icon.svg',
              width: 64,
              height: 64,
            ),
          )
        else
          SvgPicture.asset(
            'assets/images/tezos_social_icon.svg',
            width: 64,
            height: 64,
          ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.appName ?? '',
                  style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }
}
