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
import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/local_auth_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/models/pending_tx_params.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';

class SendArtworkReviewPage extends StatefulWidget {
  final SendArtworkReviewPayload payload;

  const SendArtworkReviewPage({required this.payload, super.key});

  @override
  State<SendArtworkReviewPage> createState() => _SendArtworkReviewPageState();
}

class _SendArtworkReviewPageState extends State<SendArtworkReviewPage> {
  bool _isSending = false;
  final tokensService = injector<TokensService>();
  final ethFormatter = EthAmountFormatter();
  final xtzFormatter = XtzAmountFormatter();

  Future<void> _sendArtwork() async {
    setState(() {
      _isSending = true;
    });
    final didAuthenticate = await LocalAuthenticationService.checkLocalAuth();
    if (!didAuthenticate) {
      setState(() {
        _isSending = false;
      });
      return;
    }

    try {
      final assetToken = widget.payload.assetToken;
      if (widget.payload.assetToken.blockchain == 'ethereum') {
        final ethereumService = injector<EthereumService>();

        final contractAddress =
            EthereumAddress.fromHex(assetToken.contractAddress!);
        final to = EthereumAddress.fromHex(widget.payload.address);
        final from = EthereumAddress.fromHex(await widget.payload.wallet
            .getETHEip55Address(index: widget.payload.index));
        final tokenId = assetToken.tokenId!;

        final data = widget.payload.assetToken.contractType == 'erc1155'
            ? await ethereumService.getERC1155TransferTransactionData(
                contractAddress, from, to, tokenId, widget.payload.quantity,
                feeOption: widget.payload.feeOption)
            : await ethereumService.getERC721TransferTransactionData(
                contractAddress, from, to, tokenId,
                feeOption: widget.payload.feeOption);

        final txHash = await ethereumService.sendTransaction(
            widget.payload.wallet,
            widget.payload.index,
            contractAddress,
            BigInt.zero,
            data,
            feeOption: widget.payload.feeOption);

        //post pending token to indexer
        if (txHash.isNotEmpty) {
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final signature = await ethereumService.signPersonalMessage(
              widget.payload.wallet,
              widget.payload.index,
              Uint8List.fromList(utf8.encode(timestamp)));
          final pendingTxParams = PendingTxParams(
            blockchain: assetToken.blockchain,
            id: assetToken.tokenId ?? '',
            contractAddress: assetToken.contractAddress ?? '',
            ownerAccount: assetToken.owner,
            pendingTx: txHash,
            timestamp: timestamp,
            signature: signature,
          );
          unawaited(tokensService.postPendingToken(pendingTxParams));
        }

        if (!mounted) {
          return;
        }
        final payload = {
          'isTezos': false,
          'hash': txHash,
          'isSentAll': widget.payload.quantity >= widget.payload.ownedTokens,
          'sentQuantity': widget.payload.quantity,
        };
        Navigator.of(context).pop(payload);
      } else {
        final tezosService = injector<TezosService>();
        final tokenId = assetToken.tokenId!;

        final wallet = widget.payload.wallet;
        final index = widget.payload.index;
        final address = await wallet.getTezosAddress(index: index);
        final operation = await tezosService.getFa2TransferOperation(
          widget.payload.assetToken.contractAddress!,
          address,
          widget.payload.address,
          tokenId,
          widget.payload.quantity,
        );
        final opHash = await tezosService.sendOperationTransaction(
            wallet, index, [operation],
            baseOperationCustomFee:
                widget.payload.feeOption.tezosBaseOperationCustomFee);

        //post pending token to indexer
        if (opHash != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final publicKey = await wallet.getTezosPublicKey(index: index);
          final signature = await tezosService.signMessage(
              wallet, index, Uint8List.fromList(utf8.encode(timestamp)));
          final pendingTxParams = PendingTxParams(
            blockchain: assetToken.blockchain,
            id: assetToken.tokenId ?? '',
            contractAddress: assetToken.contractAddress ?? '',
            ownerAccount: assetToken.owner,
            pendingTx: opHash,
            timestamp: timestamp,
            signature: signature,
            publicKey: publicKey,
          );
          unawaited(tokensService.postPendingToken(pendingTxParams));
        }
        if (!mounted) {
          return;
        }
        final payload = {
          'isTezos': true,
          'hash': opHash,
          'isSentAll': widget.payload.quantity >= widget.payload.ownedTokens,
          'sentQuantity': widget.payload.quantity,
        };
        Navigator.of(context).pop(payload);
      }
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      if (!e.isNetworkIssue) {
        unawaited(UIHelper.showMessageAction(
          context,
          'transaction_failed'.tr(),
          'try_later'.tr(),
        ));
      }
    }
    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fee = widget.payload.feeOptionValue.getFee(widget.payload.feeOption);
    final theme = Theme.of(context);
    final assetToken = widget.payload.assetToken;

    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        assetToken.artistName?.toIdentityOrMask(identityState.identityMap);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final divider = addDivider(height: 20);
    return AbsorbPointer(
      absorbing: _isSending,
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'confirmation'.tr(),
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        body: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
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
                            padding: padding,
                            child: Text(
                              'send_artwork'.tr(),
                              style: theme.textTheme.ppMori400Black16,
                            ),
                          ),
                          const SizedBox(height: 40),
                          divider,
                          Padding(
                            padding: padding,
                            child: Column(
                              children: [
                                _item(
                                  context: context,
                                  title: 'title'.tr(),
                                  content: assetToken.displayTitle ?? '',
                                ),
                                divider,
                                _item(
                                    context: context,
                                    title: 'artist'.tr(),
                                    content: artistName ?? '',
                                    tapLink: assetToken.artistURL),
                                divider,
                                if (!widget.payload.assetToken.fungible) ...[
                                  _item(
                                      context: context,
                                      title: 'edition'.tr(),
                                      content: assetToken.editionSlashMax),
                                  divider,
                                ],
                                _item(
                                    context: context,
                                    title: 'token'.tr(),
                                    content:
                                        polishSource(assetToken.source ?? ''),
                                    tapLink: assetToken.assetURL),
                                divider,
                                _item(
                                  context: context,
                                  title: 'contract'.tr(),
                                  content: assetToken.blockchain.capitalize(),
                                  tapLink: assetToken.getBlockchainUrl(),
                                ),
                                divider,
                                _item(
                                    context: context,
                                    title: 'minted'.tr(),
                                    content: assetToken.mintedAt != null
                                        ? localTimeString(assetToken.mintedAt!)
                                        : ''),
                                divider,
                                if (widget.payload.assetToken.fungible) ...[
                                  _item(
                                      context: context,
                                      title: 'owned_tokens'.tr(),
                                      content: '${widget.payload.ownedTokens}'),
                                  divider,
                                  _item(
                                      context: context,
                                      title: 'quantity_sent'.tr(),
                                      content: '${widget.payload.quantity}'),
                                  divider,
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColor.primaryBlack),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'to'.tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.payload.address,
                                        style: theme.textTheme.ppMori400White14,
                                      ),
                                      addDivider(color: AppColor.white),
                                      Text(
                                        'gas_fee2'.tr(),
                                        style: theme.textTheme.ppMori400Grey14,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _amountFormat(
                                          fee,
                                          isETH: widget.payload.assetToken
                                                  .blockchain ==
                                              'ethereum',
                                        ),
                                        style: theme.textTheme.ppMori400White14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: padding,
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                              text: _isSending ? 'sending'.tr() : 'sendH'.tr(),
                              isProcessing: _isSending,
                              onTap: _isSending ? null : _sendArtwork),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required String title,
    required String content,
    String? tapLink,
    double width = 120,
    bool forceSafariVC = true,
  }) {
    final theme = Theme.of(context);
    Function()? onValueTap;

    if (tapLink != null) {
      final uri = Uri.parse(tapLink);
      onValueTap = () => unawaited(launchUrl(uri,
          mode: forceSafariVC
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault));
    }
    return Row(
      children: [
        SizedBox(
          width: width,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onValueTap,
            child: Text(
              content,
              style: theme.textTheme.ppMori400Black14.copyWith(
                decoration:
                    (onValueTap != null) ? TextDecoration.underline : null,
                decorationColor: AppColor.primaryBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
      ],
    );
  }

  String _amountFormat(BigInt fee, {required bool isETH}) => isETH
      ? '${ethFormatter.format(fee)} ETH '
          '(${widget.payload.exchangeRate.ethToUsd(fee)} USD)'
      : '${xtzFormatter.format(fee.toInt())} XTZ '
          '(${widget.payload.exchangeRate.xtzToUsd(fee.toInt())} USD)';
}

class SendArtworkReviewPayload {
  final AssetToken assetToken;
  final WalletStorage wallet;
  final int index;
  final String address;
  final BigInt fee;
  final CurrencyExchangeRate exchangeRate;
  final int ownedTokens;
  final int quantity;
  final FeeOption feeOption;
  final FeeOptionValue feeOptionValue;

  SendArtworkReviewPayload(
      this.assetToken,
      this.wallet,
      this.index,
      this.address,
      this.fee,
      this.exchangeRate,
      this.ownedTokens,
      this.quantity,
      this.feeOption,
      this.feeOptionValue);
}
