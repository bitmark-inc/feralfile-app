import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/model/wc_ethereum_transaction.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/irl_screen/sign_message_screen.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/select_address.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:tezart/tezart.dart';
import 'package:uuid/uuid.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';

class IRLWebScreen extends StatefulWidget {
  final IRLWebScreenPayload payload;

  const IRLWebScreen({required this.payload, super.key});

  @override
  State<IRLWebScreen> createState() => _IRLWebScreenState();
}

class _IRLWebScreenState extends State<IRLWebScreen> {
  InAppWebViewController? _controller;
  final _accountService = injector<AccountService>();

  Future<WalletIndex?> getAccountByAddress(
      {required String chain, required String address}) async {
    try {
      return await _accountService.getAccountByAddress(
        chain: chain,
        address: address,
      );
    } catch (e) {
      return null;
    }
  }

  JSResult _logAndReturnJSResult(String func, JSResult result) {
    log.info('[IRLWebScreen] $func: ${result.toJson()}');
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
      final addresses = _getWalletAddress(cryptoType);
      if (addresses.isEmpty) {
        try {
          final addedAddress = await _accountService.insertNextAddress(
              cryptoType == CryptoType.XTZ
                  ? WalletType.Tezos
                  : WalletType.Ethereum);
          addresses.add(addedAddress.first);
        } catch (e) {
          return _logAndReturnJSResult(
            '_getAddress',
            JSResult.error('Address not found'),
          );
        }
      }
      String? address;
      final params = arguments['params'] as Map?;
      final minimumCryptoBalance =
          int.tryParse(params?['minimumCryptoBalance'] ?? '') ?? 0;
      if (addresses.length == 1 && minimumCryptoBalance == 0) {
        address = addresses.first.address;
      } else {
        if (!mounted) {
          return null;
        }
        final type = SelectAddressType.fromString(params?['type'] ?? '');
        address = await UIHelper.showDialog(
          context,
          type.popUpTitle,
          IRLSelectAddressView(
            addresses: addresses,
            selectButton: type.selectButton,
            minimumCryptoBalance: minimumCryptoBalance,
          ),
          padding: const EdgeInsets.symmetric(vertical: 32),
          paddingTitle: const EdgeInsets.symmetric(horizontal: 14),
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

  Future<JSResult?> _countAddress(List<dynamic> args) async {
    try {
      log.info('[IRLWebScreen] countAddress: $args');
      if (args.firstOrNull == null || args.firstOrNull is! Map) {
        return _logAndReturnJSResult(
          '_countAddress',
          JSResult.error('Payload is invalid'),
        );
      }
      final arguments = args.firstOrNull as Map;

      final chain = arguments['chain'];
      if (chain == null) {
        return _logAndReturnJSResult(
          '_countAddress',
          JSResult.error('Blockchain is invalid'),
        );
      }

      final cryptoType = _getCryptoType(chain);
      if (cryptoType == null) {
        return _logAndReturnJSResult(
          '_countAddress',
          JSResult.error('Blockchain is unsupported'),
        );
      }
      final addresses = _getWalletAddress(cryptoType);
      if (addresses.isEmpty) {
        try {
          await _accountService.insertNextAddress(cryptoType == CryptoType.XTZ
              ? WalletType.Tezos
              : WalletType.Ethereum);
          return _logAndReturnJSResult(
            '_countAddress',
            JSResult.result(1),
          );
        } catch (e) {
          return _logAndReturnJSResult(
            '_countAddress',
            JSResult.error('Account not found'),
          );
        }
      }
      return _logAndReturnJSResult(
        '_countAddress',
        JSResult.result(addresses.length),
      );
    } catch (e) {
      return _logAndReturnJSResult(
        '_countAddress',
        JSResult.error(e.toString()),
      );
    }
  }

  List<WalletAddress> _getWalletAddress(CryptoType cryptoType) =>
      _accountService.getWalletsAddress(cryptoType);

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

        final configService = injector<ConfigurationService>();
        unawaited(configService.setMerchandiseOrderIds([orderId]));

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
      case 'instant_purchase':
        final data = argument['data'] as Map<String, dynamic>;
        final shouldClose = data['close'] as bool;
        log.info('[IRLWebScreen] handle instantPurchase close= $shouldClose:');
        try {
          final tokenIdsDynamic = data['token_ids'] as List<dynamic>? ?? [];
          final tokenIds = tokenIdsDynamic.map((e) => e.toString()).toList();
          final address = data['address'];
          final isNonCryptoPayment = data['is_non_crypto_payment'] as bool;
          if (tokenIds.isNotEmpty && address != null && isNonCryptoPayment) {
            final indexerService = injector<IndexerService>();
            final tokens =
                await indexerService.getNftTokens(QueryListTokensRequest(
              ids: tokenIds,
            ));
            final pendingTokens = tokens
                .map((e) => e.copyWith(
                      pending: true,
                      owner: address,
                      owners: {address: 1},
                      isManual: false,
                      lastActivityTime: DateTime.now(),
                      lastRefreshedTime: DateTime(1),
                      balance: 1,
                    ))
                .toList();
            log.info('[IRLWebScreen] instant_purchase : ${pendingTokens.length}'
                ' pending tokens');
            await injector<TokensService>().setCustomTokens(pendingTokens);
            unawaited(injector<TokensService>().reindexAddresses([address]));
            if (pendingTokens.isNotEmpty) {
              NftCollectionBloc.eventController
                  .add(UpdateTokensEvent(tokens: pendingTokens));
            }
          }
        } catch (e) {
          log.info('[IRLWebScreen] instant_purchase error while set'
              ' pending token : $e');
        }

        if (shouldClose) {
          log.info('[IRLWebScreen] instantPurchase finish and close ');
          unawaited(injector<NavigationService>().popToCollection());
        }
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
      log.info('[IRLWebScreen] sendTransaction: $args');
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
              const PairingMetadata(
                  name: '', description: '', url: '', icons: []),
              WCEthereumTransaction.fromJson(transaction),
              account.wallet.uuid,
              account.index,
            );

            final txHash = await Navigator.of(context).pushNamed(
              AppRouter.wcSendTransactionPage,
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
                  AppRouter.tbSendTransactionPage,
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
      handlerName: 'countAddress',
      callback: _countAddress,
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
        IRLHandler.closeWebview(args);
      },
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'closeWebviewThenNavigate',
      callback: (args) async {
        await IRLHandler.closeWebviewThenNavigate(args);
      },
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'didUpgradeMembership',
      callback: (args) async => await IRLHandler.refreshJWT(args),
    );
  }

  void _addLocalStorageItems(Map<String, dynamic> items) {
    items.forEach((key, value) {
      unawaited(
          _controller?.webStorage.localStorage.setItem(key: key, value: value));
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          appBar: widget.payload.isDarkStatusBar
              ? getDarkEmptyAppBar(
                  widget.payload.statusBarColor ?? Colors.black)
              : getLightEmptyAppBar(
                  widget.payload.statusBarColor ?? Colors.white),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: InAppWebViewPage(
                    payload: InAppWebViewPayload(
                      widget.payload.url,
                      isPlainUI: widget.payload.isPlainUI,
                      backgroundColor: widget.payload.statusBarColor,
                      onWebViewCreated: (final controller) {
                        _controller = controller;
                        _addJavaScriptHandler();
                        if (widget.payload.localStorageItems != null) {
                          _addLocalStorageItems(
                              widget.payload.localStorageItems!);
                        }
                      },
                      onConsoleMessage: (controller, message) {
                        log.info('[IRLWebScreen] onConsoleMessage: $message');
                      },
                    ),
                  ),
                )
              ],
            ),
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
  final bool isDarkStatusBar;

  IRLWebScreenPayload(this.url,
      {this.isPlainUI = false,
      this.localStorageItems,
      this.statusBarColor,
      this.isDarkStatusBar = true});
}

class IRLHandler {
  static void closeWebview(List<dynamic> arguments) {
    injector.get<NavigationService>().goBack();
  }

  static Future<void> closeWebviewThenNavigate(List<dynamic> arguments) async {
    injector.get<NavigationService>().goBack();
    final json = arguments.firstOrNull as Map<String, dynamic>?;
    final navigatePath = json?['navigation_route'];
    if (navigatePath != null) {
      await injector<NavigationService>().navigatePath(navigatePath);
    }
  }

  static Future<JSResult> refreshJWT(List<dynamic> arguments) async {
    final authService = injector.get<AuthService>();
    final newJWT = await authService.refreshJWT();
    return JSResult.result(newJWT.isPremiumValid());
  }
}
