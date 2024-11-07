// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:web3dart/crypto.dart';

class IRLSignMessagePayload {
  String payload;
  String chain;
  String sourceAddress;
  Map<String, dynamic>? metadata;

  IRLSignMessagePayload({
    required this.payload,
    required this.chain,
    required this.sourceAddress,
    this.metadata,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'payload': payload,
        'chain': chain,
        'sourceAddress': sourceAddress,
        'metadata': metadata,
      };

  factory IRLSignMessagePayload.fromJson(Map<String, dynamic> map) =>
      IRLSignMessagePayload(
        payload: map['payload'] as String,
        chain: map['chain'] as String,
        sourceAddress: map['sourceAddress'] as String,
        metadata: map['metadata'] == null
            ? null
            : map['metadata'] as Map<String, dynamic>,
      );
}

class IRLSendTransactionPayload {
  List<Map<String, dynamic>> transactions;
  String chain;
  String sourceAddress;
  Map<String, dynamic>? metadata;

  IRLSendTransactionPayload({
    required this.transactions,
    required this.chain,
    required this.sourceAddress,
    this.metadata,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'transactions': transactions,
        'chain': chain,
        'sourceAddress': sourceAddress,
        'metadata': metadata,
      };

  factory IRLSendTransactionPayload.fromJson(Map<String, dynamic> map) =>
      IRLSendTransactionPayload(
        transactions: List<Map<String, dynamic>>.from(
          (map['transactions'] as List).map<Map<String, dynamic>>(
            (x) => x,
          ),
        ),
        chain: map['chain'] as String,
        sourceAddress: map['sourceAddress'] as String,
        metadata: map['metadata'] == null
            ? null
            : map['metadata'] as Map<String, dynamic>,
      );
}

class IRLSignMessageScreen extends StatefulWidget {
  final IRLSignMessagePayload payload;

  const IRLSignMessageScreen({required this.payload, super.key});

  @override
  State<IRLSignMessageScreen> createState() => _IRLSignMessageScreenState();
}

class _IRLSignMessageScreenState extends State<IRLSignMessageScreen> {
  WalletIndex? _currentWallet;
  late PairingMetadata? appMetadata;

  @override
  void initState() {
    super.initState();
    appMetadata = widget.payload.metadata != null
        ? PairingMetadata.fromJson(widget.payload.metadata!)
        : null;
    unawaited(getWallet());
  }

  Future<void> getWallet() async {
    final accountService = injector<AccountService>();
    _currentWallet = await accountService.getAccountByAddress(
      chain: widget.payload.chain,
      address: widget.payload.sourceAddress,
    );
    setState(() {});
  }

  Future<void> _sign() async {
    final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
    if (!didAuthenticate) {
      return;
    }
    final signature = await _currentWallet!.signMessage(
      chain: widget.payload.chain,
      message: widget.payload.payload,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(signature);

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
    late String viewingMessage;
    if (widget.payload.payload.isHex) {
      final message = hexToBytes(widget.payload.payload);
      final Uint8List trimmedMessage = message.length > 6 &&
              message.sublist(0, 2).equals(Uint8List.fromList([5, 1]))
          ? message.sublist(6)
          : message;
      try {
        viewingMessage = utf8.decode(trimmedMessage, allowMalformed: false);
      } catch (_) {
        viewingMessage = '0x${widget.payload.payload}';
      }
    } else {
      viewingMessage = widget.payload.payload;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        action: () =>
            unawaited(UIHelper.showAppReportBottomSheet(context, appMetadata)),
        onBack: () {
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
                      child: _metadataInfo(widget.payload.metadata),
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
                          viewingMessage,
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
                      onTap: _currentWallet != null
                          ? () => withDebounce(_sign)
                          : null,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _metadataInfo(Map<String, dynamic>? metadata) {
    final theme = Theme.of(context);

    final icons = metadata?['icons'] as List?;
    final name = metadata?['name'];

    return metadata != null
        ? Row(
            children: [
              if (icons != null && icons.isNotEmpty) ...[
                CachedNetworkImage(
                  imageUrl: icons.first,
                  width: 64,
                  height: 64,
                  errorWidget: (context, url, error) => const SizedBox(
                    width: 64,
                    height: 64,
                  ),
                ),
              ] else ...[
                const SizedBox(
                  width: 64,
                  height: 64,
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.ppMori700Black24),
                  ],
                ),
              )
            ],
          )
        : const SizedBox();
  }
}
