// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:web3dart/crypto.dart';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'payload': payload,
      'chain': chain,
      'sourceAddress': sourceAddress,
      'metadata': metadata,
    };
  }

  factory IRLSignMessagePayload.fromJson(Map<String, dynamic> map) {
    return IRLSignMessagePayload(
      payload: map['payload'] as String,
      chain: map['chain'] as String,
      sourceAddress: map['sourceAddress'] as String,
      metadata: map['metadata'] == null
          ? null
          : map['metadata'] as Map<String, dynamic>,
    );
  }
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transactions': transactions,
      'chain': chain,
      'sourceAddress': sourceAddress,
      'metadata': metadata,
    };
  }

  factory IRLSendTransactionPayload.fromJson(Map<String, dynamic> map) {
    return IRLSendTransactionPayload(
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
}

class IRLSignMessageScreen extends StatefulWidget {
  final IRLSignMessagePayload payload;
  const IRLSignMessageScreen({Key? key, required this.payload})
      : super(key: key);

  @override
  State<IRLSignMessageScreen> createState() => _IRLSignMessageScreenState();
}

class _IRLSignMessageScreenState extends State<IRLSignMessageScreen> {
  WalletIndex? _currentWallet;

  @override
  void initState() {
    super.initState();
    getWallet();
  }

  getWallet() async {
    final accountService = injector<AccountService>();
    _currentWallet = await accountService.getAccountByAddress(
      chain: widget.payload.chain,
      address: widget.payload.sourceAddress,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.payload.payload);
    final Uint8List viewMessage = message.length > 6 &&
            message.sublist(0, 2).equals(Uint8List.fromList([5, 1]))
        ? message.sublist(6)
        : message;
    final messageInUtf8 = utf8.decode(viewMessage, allowMalformed: true);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
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
                    Text(
                      widget.payload.metadata?['name'] ?? "",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                    Text(
                      "message".tr(),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      messageInUtf8,
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
                    onPress: _currentWallet != null
                        ? () => withDebounce(() async {
                              final signature =
                                  await _currentWallet!.signMessage(
                                chain: widget.payload.chain,
                                message: widget.payload.payload,
                              );

                              if (!mounted) return;

                              Navigator.of(context).pop(signature);
                              final notificationEnabled =
                                  injector<ConfigurationService>()
                                          .isNotificationEnabled() ??
                                      false;
                              if (notificationEnabled) {
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
    );
  }
}
