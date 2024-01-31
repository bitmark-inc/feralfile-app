//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';

class AUSignMessagePage extends StatefulWidget {
  static const String tag = 'au_sign_message';
  final Wc2RequestPayload request;

  const AUSignMessagePage({required this.request, super.key});

  @override
  State<AUSignMessagePage> createState() => _AUSignMessagePageState();
}

class _AUSignMessagePageState extends State<AUSignMessagePage> {
  WalletStorage? _currentPersona;

  @override
  void initState() {
    super.initState();
    unawaited(fetchPersona());
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
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _currentPersona = currentWallet;
    });
  }

  Future _rejectRequest({String? reason}) async {
    log.info('[AUSignMessagePage] _rejectRequest: $reason');
    await injector<Wc2Service>().respondOnReject(
      widget.request.topic,
      reason: reason,
    );
  }

  Future _handleAuSignRequest({required Wc2RequestPayload request}) async {
    final accountService = injector<AccountService>();
    final params = Wc2SignRequestParams.fromJson(request.params);
    final address = params.address;
    final chain = params.chain;
    final account = await accountService.getAccountByAddress(
      chain: chain,
      address: address,
    );
    final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
    if (!didAuthenticate) {
      return;
    }
    try {
      final signature = await account.signMessage(
        chain: chain,
        message: params.message,
      );
      if (!mounted) return;
      Navigator.of(context).pop(signature);
      log.info("[Wc2RequestPage] _handleAuSignRequest: $signature");
    } catch (e) {
      log.info('[Wc2RequestPage] _handleAuSignRequest $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewMessage = widget.request.params['message'];

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
            Navigator.of(context).pop();
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
                        child: _wc2AppInfo(widget.request.proposer),
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
                            viewMessage,
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
                            ? () => withDebounce(() async {
                                  unawaited(_handleAuSignRequest(
                                      request: widget.request));
                                  if (!mounted) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  showInfoNotification(
                                    const Key('signed'),
                                    'signed'.tr(),
                                    frontWidget: SvgPicture.asset(
                                      'assets/images/checkbox_icon.svg',
                                      width: 24,
                                    ),
                                  );
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

  Widget _wc2AppInfo(PairingMetadata? proposer) {
    final theme = Theme.of(context);

    return proposer != null
        ? Row(
            children: [
              if (proposer.icons.isNotEmpty) ...[
                CachedNetworkImage(
                  imageUrl: proposer.icons.first,
                  width: 64,
                  height: 64,
                  errorWidget: (context, url, error) => SizedBox(
                      width: 64,
                      height: 64,
                      child: SvgPicture.asset(
                          'assets/images/feralfileAppIcon.svg')),
                ),
              ] else ...[
                SizedBox(
                    width: 64,
                    height: 64,
                    child:
                        SvgPicture.asset('assets/images/feralfileAppIcon.svg')),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposer.name,
                        style: theme.textTheme.ppMori700Black24),
                  ],
                ),
              )
            ],
          )
        : const SizedBox();
  }
}
