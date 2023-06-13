import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/irl_screen/get_address_screen.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/tezos_beacon/tb_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tezart/tezart.dart';
import 'package:wallet_connect/wallet_connect.dart';

class IRLWebScreen extends StatefulWidget {
  final Uri url;

  const IRLWebScreen({Key? key, required this.url}) : super(key: key);

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
    _metricClient.addEvent(MixpanelEvent.callIrlFunction, data: {
      'function': func,
      'error': result.errorMessage,
      'result': JSResult.result.toString(),
    });
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
      final arguments = (args.firstOrNull as Map);

      final chain = arguments['chain'];
      if (chain == null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.error('Blockchain is invalid'),
        );
      }

      if (chain == null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.error('Blockchain is unsupported'),
        );
      }
      final address = await Navigator.of(context).pushNamed(
        AppRouter.irlGetAddress,
        arguments: IRLGetAddressPayLoad(
          blockchain: chain,
          params: arguments['params'],
          metadata: arguments['metadata'],
        ),
      );
      if (address != null) {
        return _logAndReturnJSResult(
          '_getAddress',
          JSResult.result(address),
        );
      }
      return null;
    } catch (e) {
      return _logAndReturnJSResult(
        '_getAddress',
        JSResult.error(e.toString()),
      );
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
            'Wallet not found. Chain ${argument.chain}, address: ${argument.sourceAddress}',
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
            'Wallet not found. Chain ${argument.chain}, address: ${argument.sourceAddress}',
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
            if (transaction["data"] == null) transaction["data"] = "";
            if (transaction["gas"] == null) transaction["gas"] = "";

            final args = WCSendTransactionPageArgs(
              1,
              WCPeerMeta.fromJson(argument.metadata ??
                  {
                    "name": "",
                    "url": "",
                    "icons": [""]
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
          final txHash = await Navigator.of(context).pushNamed(
            TBSendTransactionPage.tag,
            arguments: beaconRequest,
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
        injector.get<NavigationService>().popUntilHomeOrSettings();
        _metricClient.addEvent(MixpanelEvent.callIrlFunction, data: {
          'function': IrlWebviewFunction.closeWebview,
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
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
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: widget.url),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  _addJavaScriptHandler();
                },
                onConsoleMessage: (controller, consoleMessage) {},
              ),
            )
          ],
        ),
      ),
    );
  }
}

class JSResult {
  String? errorMessage;
  dynamic result;

  JSResult({
    this.errorMessage,
    this.result,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'errorMessage': errorMessage,
      'result': result,
    };
  }

  factory JSResult.fromJson(Map<String, dynamic> map) {
    return JSResult(
      errorMessage:
          map['errorMessage'] != null ? map['errorMessage'] as String : null,
      result: map['result'] != null ? map['result'] as dynamic : null,
    );
  }

  factory JSResult.error(String error) {
    return JSResult(
      errorMessage: error,
    );
  }

  factory JSResult.result(dynamic result) {
    return JSResult(
      result: result,
    );
  }
}
