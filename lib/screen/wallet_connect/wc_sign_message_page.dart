//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:web3dart/crypto.dart';

class WCSignMessagePage extends StatefulWidget {
  final WCSignMessagePageArgs args;

  const WCSignMessagePage({required this.args, super.key});

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

    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () {
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
                        child: _wcAppInfo(widget.args.peerMeta),
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
                child: _signButton(context, message, messageInUtf8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wcAppInfo(PairingMetadata peerMeta) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (peerMeta.icons.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: peerMeta.icons.first,
            width: 64,
            height: 64,
            errorWidget: (context, url, error) => SizedBox(
                width: 64,
                height: 64,
                child:
                    Image.asset('assets/images/walletconnect-alternative.png')),
          ),
        ] else ...[
          SizedBox(
              width: 64,
              height: 64,
              child:
                  Image.asset('assets/images/walletconnect-alternative.png')),
        ],
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerMeta.name, style: theme.textTheme.ppMori700Black24),
            ],
          ),
        )
      ],
    );
  }

  Widget _signButton(
          BuildContext pageContext, Uint8List message, String messageInUtf8) =>
      Row(
        children: [
          Expanded(
            child: PrimaryButton(
              text: 'sign'.tr(),
              onTap: () => withDebounce(() async {
                final didAuthenticate =
                    await LocalAuthenticationService.checkLocalAuth();
                if (!didAuthenticate) {
                  return;
                }
                final args = widget.args;
                final WalletIndex wallet;
                wallet =
                    WalletIndex(LibAukDart.getWallet(args.uuid), args.index);
                final String signature;

                switch (args.type) {
                  case WCSignType.PERSONAL_MESSAGE:
                  case WCSignType.MESSAGE:
                    signature = await injector<EthereumService>()
                        .signPersonalMessage(
                            wallet.wallet, wallet.index, message);
                    break;
                  case WCSignType.TYPED_MESSAGE:
                    signature = await injector<EthereumService>()
                        .signMessage(wallet.wallet, wallet.index, message);
                    break;
                }

                if (!mounted) {
                  return;
                }
                showInfoNotification(
                  const Key('signed'),
                  'signed'.tr(),
                  frontWidget: SvgPicture.asset(
                    'assets/images/checkbox_icon.svg',
                    width: 24,
                  ),
                );
                Navigator.of(context).pop(signature);
              }),
            ),
          )
        ],
      );
}

class WCSignMessagePageArgs {
  final String topic;
  final PairingMetadata peerMeta;
  final String message;
  final WCSignType type;
  final String uuid;
  final int index;

  WCSignMessagePageArgs(
    this.topic,
    this.peerMeta,
    this.message,
    this.type,
    this.uuid,
    this.index,
  );
}

// ignore: constant_identifier_names
enum WCSignType { MESSAGE, PERSONAL_MESSAGE, TYPED_MESSAGE }

class WCEthereumSignMessage {
  final List<String> raw;
  final WCSignType type;

  WCEthereumSignMessage({
    required this.raw,
    required this.type,
  });

  String? get data {
    switch (type) {
      case WCSignType.MESSAGE:
        return raw[1];
      case WCSignType.TYPED_MESSAGE:
        return raw[1];
      case WCSignType.PERSONAL_MESSAGE:
        return raw[0];
      default:
        return null;
    }
  }
}
