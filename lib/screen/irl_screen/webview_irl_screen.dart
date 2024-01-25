import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/model/wc_ethereum_transaction.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/view/select_address.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tezart/tezart.dart';
import 'package:uuid/uuid.dart';

class IRLWebScreen extends StatefulWidget {
  final IRLWebScreenPayload payload;

  const IRLWebScreen({required this.payload, super.key});

  @override
  State<IRLWebScreen> createState() => _IRLWebScreenState();
}

class _IRLWebScreenState extends State<IRLWebScreen> {
  InAppWebViewController? _controller;
  final _metricClient = injector<MetricClientService>();

  Future<WalletIndex?> getAccountByAddress(
      {required String chain, required String address}) async {
    try {
      final accountService = injector<AccountService>();
      return await accountService.getAccountByAddress(
        chain: chain,
        address: address,
      );
    } catch (e) {
      return null;
    }
  }

  JSResult _logAndReturnJSResult(String func, JSResult result) {
    log.info('[IRLWebScreen] $func: ${result.toJson()}');
    unawaited(_metricClient.addEvent(MixpanelEvent.callIrlFunction, data: {
      'function': func,
      'error': result.errorMessage,
      'result': result.result.toString(),
      'url': widget.payload.url,
    }));
    return result;
  }

  Future<JSResult?> _getAddress(List<dynamic> args) async {
    try {
      log.info('[IRLWebScreen] getAddress: $args');
      if (args.firstOrNull == null || args.firstOrNull is! Map) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.error('Payload is invalid'),
        );
      }
      final arguments = args.firstOrNull as Map;

      final chain = arguments['chain'];
      if (chain == null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.error('Blockchain is invalid'),
        );
      }

      final cryptoType = _getCryptoType(chain);
      if (cryptoType == null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.error('Blockchain is unsupported'),
        );
      }
      final addresses = await injector<CloudDatabase>()
          .addressDao
          .getAddressesByType(cryptoType.source);
      if (addresses.isEmpty) {
        final persona =
            await injector<AccountService>().getOrCreateDefaultPersona();
        final addedAddress = await persona.insertNextAddress(
            cryptoType == CryptoType.XTZ
                ? WalletType.Tezos
                : WalletType.Ethereum);
        addresses.add(addedAddress.first);
      }
      String? address;
      if (addresses.length == 1) {
        address = addresses.first.address;
      } else {
        if (!mounted) {
          return null;
        }
        address = await UIHelper.showDialog(
          context,
          'select_address_to_connect'.tr(),
          SelectAddressView(
            addresses: addresses,
          ),
        );
      }
      if (address != null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.result(address),
        );
      }
      return _logAndReturnJSResult(
        '_getAddress',
        JSResult.error('User rejected'),
      );
    } catch (e) {
      return _logAndReturnJSResult(
        '_getAddress',
        JSResult.error(e.toString()),
      );
    }
  }

  Future<void> _receiveData(List<dynamic> args) async {
    final argument = args.firstOrNull;
    log.info('[IRLWebScreen] passData: $argument');
    if (argument == null) {
      return;
    }
    final type = argument['type'];
    switch (type) {
      case 'customer_support':
        final customerSupportService = injector<CustomerSupportService>();
        final messageType = CSMessageType.CreateIssue.rawValue;
        final issueID = 'TEMP-${const Uuid().v4()}';
        final data = argument['data'] as Map<String, dynamic>;
        final title = data['title'];
        final text = data['text'];
        final orderId = data['orderId'];
        final indexId = data['indexId'];
        final draft = DraftCustomerSupport(
          uuid: const Uuid().v4(),
          issueID: issueID,
          type: messageType,
          data: json.encode(DraftCustomerSupportData(text: text, title: title)),
          createdAt: DateTime.now(),
          reportIssueType: ReportIssueType.MerchandiseIssue,
          mutedMessages: [orderId, indexId].join('[SEPARATOR]'),
        );

        await customerSupportService.draftMessage(draft);
        await injector<ConfigurationService>()
            .setHasMerchandiseSupport(data['indexId']);
        return;
      case 'open_customer_support':
        if (!mounted) {
          return;
        }
        unawaited(Navigator.of(context).pushNamed(AppRouter.supportListPage));
        return;
      case 'pay_to_mint_success':
        final data = argument['data'] as Map<String, dynamic>;
        Map<String, dynamic> response = {
          'result': true,
        };
        response.addAll(data);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(response);

        return;
      default:
        return;
    }
  }

  Future<JSResult?> _signMessage(List<dynamic> args) async {
    try {
      log.info('[IRLWebScreen] signMessage: $args');

      if (args.firstOrNull == null || args.firstOrNull is! Map) {
        return _logAndReturnJSResult(
          '_signMessage',
          JSResult.error('Payload is invalid'),
        );
      }

      final argument = IRLSignMessagePayload.fromJson(args.firstOrNull);
      final account = await getAccountByAddress(
        address: argument.sourceAddress,
        chain: argument.chain,
      );

      if (account == null) {
        return _logAndReturnJSResult(
          '_signMessage',
          JSResult.error(
            '''
            Wallet not found. Chain ${argument.chain}, 
            address: ${argument.sourceAddress}
            ''',
          ),
        );
      }
      if (!mounted) {
        return _logAndReturnJSResult(
          '_signMessage',
          JSResult(),
        );
      }

      final signature = await Navigator.of(context).pushNamed(
        AppRouter.irlSignMessage,
        arguments: argument,
      );

      if (signature == null) {
        return _logAndReturnJSResult(
          '_signMessage',
          JSResult.error('Rejected'),
        );
      }
      return _logAndReturnJSResult(
        '_signMessage',
        JSResult.result(signature),
      );
    } catch (e) {
      if (e is AccountException) {
        return _logAndReturnJSResult(
          '_signMessage',
          JSResult.error(e.message ?? ''),
        );
      }
      return _logAndReturnJSResult(
        '_signMessage',
        JSResult.error(e.toString()),
      );
    }
  }

  Future<JSResult?> _sendTransaction(List<dynamic> args) async {
    try {
      log.info('[IRLWebScreen] signMessage: $args');
      if (args.firstOrNull == null || args.firstOrNull is! Map) {
        return _logAndReturnJSResult(
          '_sendTransaction',
          JSResult.error('Payload is invalid'),
        );
      }
      final argument = IRLSendTransactionPayload.fromJson(args.firstOrNull);

      final account = await getAccountByAddress(
        address: argument.sourceAddress,
        chain: argument.chain,
      );

      if (account == null) {
        return _logAndReturnJSResult(
          '_sendTransaction',
          JSResult.error(
            '''
            Wallet not found. Chain ${argument.chain}, 
            address: ${argument.sourceAddress}
            ''',
          ),
        );
      }
      if (!mounted) {
        return _logAndReturnJSResult(
          '_sendTransaction',
          JSResult(),
        );
      }

      switch (argument.chain.caip2Namespace) {
        case Wc2Chain.ethereum:
          try {
            var transaction = argument.transactions.firstOrNull ?? {};
            if (transaction['data'] == null) {
              transaction['data'] = '';
            }
            if (transaction['gas'] == null) {
              transaction['gas'] = '';
            }
            if (transaction['to'] == null) {
              return _logAndReturnJSResult(
                '_sendTransaction',
                JSResult.error('Invalid transaction: no recipient'),
              );
            }

            final args = WCSendTransactionPageArgs(
              1,
              AppMetadata.fromJson(argument.metadata ??
                  {
                    'name': '',
                    'url': '',
                    'icons': [''],
                    'description': '',
                  }),
              WCEthereumTransaction.fromJson(transaction),
              account.wallet.uuid,
              account.index,
              isIRL: true,
            );

            final txHash = await Navigator.of(context).pushNamed(
              WCSendTransactionPage.tag,
              arguments: args,
            );
            if (txHash == null) {
              return _logAndReturnJSResult(
                '_sendTransaction',
                JSResult.error('Rejected'),
              );
            }
            return _logAndReturnJSResult(
              '_sendTransaction',
              JSResult.result(txHash),
            );
          } catch (e) {
            return _logAndReturnJSResult(
              '_sendTransaction',
              JSResult.error(e.toString()),
            );
          }

        case Wc2Chain.tezos:
          var operations =
              argument.transactions.map((e) => Operation.fromJson(e)).toList();

          final beaconRequest = BeaconRequest(
            account.wallet.uuid,
            operations: operations,
            sourceAddress: argument.sourceAddress,
          );
          final txHash = mounted
              ? await Navigator.of(context).pushNamed(
                  TBSendTransactionPage.tag,
                  arguments: beaconRequest,
                )
              : null;
          if (txHash == null) {
            return _logAndReturnJSResult(
              '_sendTransaction',
              JSResult.error('Rejected'),
            );
          }

          return _logAndReturnJSResult(
            '_sendTransaction',
            JSResult.result(txHash),
          );
        default:
          return _logAndReturnJSResult(
            '_sendTransaction',
            JSResult(),
          );
      }
    } catch (e) {
      return _logAndReturnJSResult(
        '_sendTransaction',
        JSResult.error(e.toString()),
      );
    }
  }

  void _addJavaScriptHandler() {
    _controller?.addJavaScriptHandler(
      handlerName: 'getAddress',
      callback: _getAddress,
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'passData',
      callback: _receiveData,
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'signMessage',
      callback: _signMessage,
    );
    _controller?.addJavaScriptHandler(
      handlerName: 'sendTransaction',
      callback: _sendTransaction,
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'closeWebview',
      callback: (args) async {
        injector.get<NavigationService>().goBack();
        unawaited(_metricClient.addEvent(MixpanelEvent.callIrlFunction, data: {
          'function': IrlWebviewFunction.closeWebview,
          'url': widget.payload.url,
        }));
      },
    );
  }

  void _addLocalStorageItems(Map<String, dynamic> items) {
    items.forEach((key, value) {
      unawaited(
          _controller?.webStorage.localStorage.setItem(key: key, value: value));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: widget.payload.statusBarColor ?? Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.white,
          toolbarHeight: 0,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: InAppWebViewPage(
                  payload: InAppWebViewPayload(widget.payload.url,
                      isPlainUI: widget.payload.isPlainUI,
                      backgroundColor: widget.payload.statusBarColor,
                      onWebViewCreated: (final controller) {
                    _controller = controller;
                    _addJavaScriptHandler();
                    if (widget.payload.localStorageItems != null) {
                      _addLocalStorageItems(widget.payload.localStorageItems!);
                    }
                  }),
                ),
              )
            ],
          ),
        ),
      );

  CryptoType? _getCryptoType(String chain) {
    switch (chain.toLowerCase()) {
      case 'ethereum':
      case 'eip155':
        return CryptoType.ETH;
      case 'tezos':
        return CryptoType.XTZ;
      default:
        return null;
    }
  }
}

class JSResult {
  String? errorMessage;
  dynamic result;

  JSResult({
    this.errorMessage,
    this.result,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'errorMessage': errorMessage,
        'result': result,
      };

  factory JSResult.fromJson(Map<String, dynamic> map) => JSResult(
        errorMessage:
            map['errorMessage'] != null ? map['errorMessage'] as String : null,
        result: map['result'] != null ? map['result'] as dynamic : null,
      );

  factory JSResult.error(String error) => JSResult(
        errorMessage: error,
      );

  factory JSResult.result(result) => JSResult(
        result: result,
      );
}

class IRLWebScreenPayload {
  final String url;
  final bool isPlainUI;
  final Map<String, dynamic>? localStorageItems;
  final Color? statusBarColor;

  IRLWebScreenPayload(this.url,
      {this.isPlainUI = false, this.localStorageItems, this.statusBarColor});
}
