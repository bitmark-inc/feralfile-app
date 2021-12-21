import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/models/ethereum/wc_ethereum_transaction.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';
import 'package:web3dart/web3dart.dart';

class WCSendTransactionPage extends StatefulWidget {
  static const String tag = 'wc_send_transaction';

  final WCSendTransactionPageArgs args;

  const WCSendTransactionPage({Key? key, required this.args}) : super(key: key);

  @override
  _WCSendTransactionPageState createState() => _WCSendTransactionPageState();
}

class _WCSendTransactionPageState extends State<WCSendTransactionPage> {

  BigInt? fee;

  @override
  void initState() {
    super.initState();

    final to = EthereumAddress.fromHex(widget.args.transaction.to);
    final EtherAmount amount =
    EtherAmount.fromUnitAndValue(EtherUnit.wei, widget.args.transaction.value);

    injector<EthereumService>().estimateFee(to, amount).then((value) => {
      this.setState(() {
        fee = value;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    final EtherAmount amount =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, widget.args.transaction.value);
    final total = fee != null ? fee! + amount.getInWei : null;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>().rejectRequest(widget.args.id);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.0),
                    Text(
                      "Confirm",
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    SizedBox(height: 40.0),
                    Text(
                      "Asset",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      "Ethereum (ETH)",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "From",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      widget.args.transaction.from,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Connection",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      widget.args.peerMeta.name,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Send",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          "${EthAmountFormatter(amount.getInWei).format().characters.take(7)} ETH",
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Gas fee",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          "${fee != null ? EthAmountFormatter(fee!).format().characters.take(7) : "-"} ETH",
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          "${total != null ? EthAmountFormatter(total).format().characters.take(7) : "-"} ETH",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              text: "Send".toUpperCase(),
              onPress: () async {
                if (fee == null) return;
                final to = EthereumAddress.fromHex(widget.args.transaction.to);
                final txHash = await injector<EthereumService>().sendTransaction(to, amount.getInWei, fee!, widget.args.transaction.data);
                injector<WalletConnectService>().approveRequest(widget.args.id, txHash);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WCSendTransactionPageArgs {
  final int id;
  final WCPeerMeta peerMeta;
  final WCEthereumTransaction transaction;

  WCSendTransactionPageArgs(this.id, this.peerMeta, this.transaction);
}
