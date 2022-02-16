import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';

class SendReviewPage extends StatelessWidget {
  static const String tag = 'send_review';

  final SendCryptoPayload payload;

  const SendReviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = payload.amount + payload.fee;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirmation",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 40.0),
            Text(
              "To",
              style: appTextTheme.headline4,
            ),
            SizedBox(height: 16.0),
            Text(
              payload.address,
              style: appTextTheme.bodyText2,
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Send",
                  style: appTextTheme.headline4,
                ),
                Text(
                  payload.type == CryptoType.ETH
                      ? "${EthAmountFormatter(payload.amount).format()} ETH (${payload.exchangeRate.ethToUsd(payload.amount)} USD)"
                      : "${XtzAmountFormatter(payload.amount.toInt()).format()} XTZ (${payload.exchangeRate.xtzToUsd(payload.amount.toInt())} USD)",
                  style: appTextTheme.bodyText2,
                ),
              ],
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Gas fee",
                  style: appTextTheme.headline4,
                ),
                Text(
                  payload.type == CryptoType.ETH
                      ? "${EthAmountFormatter(payload.fee).format()} ETH (${payload.exchangeRate.ethToUsd(payload.fee)} USD)"
                      : "${XtzAmountFormatter(payload.fee.toInt()).format()} XTZ (${payload.exchangeRate.xtzToUsd(payload.fee.toInt())} USD)",
                  style: appTextTheme.bodyText2,
                ),
              ],
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Amount",
                  style: appTextTheme.headline4,
                ),
                Text(
                  payload.type == CryptoType.ETH
                      ? "${EthAmountFormatter(total).format()} ETH (${payload.exchangeRate.ethToUsd(total)} USD)"
                      : "${XtzAmountFormatter(total.toInt()).format()} XTZ (${payload.exchangeRate.xtzToUsd(total.toInt())} USD)",
                  style: appTextTheme.headline4,
                ),
              ],
            ),
            Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Send",
                    onPress: () async {
                      final networkInjector = injector<NetworkConfigInjector>();
                      switch (payload.type) {
                        case CryptoType.ETH:
                          final address =
                              EthereumAddress.fromHex(payload.address);
                          final txHash = await networkInjector
                              .I<EthereumService>()
                              .sendTransaction(payload.wallet, address,
                                  payload.amount, null, null);

                          Navigator.of(context).pop(txHash);
                          break;
                        case CryptoType.XTZ:
                          final tezosWallet =
                              await payload.wallet.getTezosWallet();
                          final sig = await networkInjector
                              .I<TezosService>()
                              .sendTransaction(tezosWallet, payload.address,
                                  payload.amount.toInt());

                          Navigator.of(context).pop(sig);
                          break;
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
