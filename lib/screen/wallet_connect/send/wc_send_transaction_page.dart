import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_state.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  @override
  void initState() {
    super.initState();

    final to = EthereumAddress.fromHex(widget.args.transaction.to);
    final EtherAmount amount = EtherAmount.fromUnitAndValue(
        EtherUnit.wei, widget.args.transaction.value);

    context
        .read<WCSendTransactionBloc>()
        .add(WCSendTransactionEstimateEvent(to, amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          context.read<WCSendTransactionBloc>().add(
              WCSendTransactionRejectEvent(
                  widget.args.peerMeta, widget.args.id));
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: BlocBuilder<WCSendTransactionBloc, WCSendTransactionState>(
          builder: (context, state) {
            final EtherAmount amount = EtherAmount.fromUnitAndValue(
                EtherUnit.wei, widget.args.transaction.value);
            final total =
                state.fee != null ? state.fee! + amount.getInWei : null;

            return Column(
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
                              "${state.fee != null ? EthAmountFormatter(state.fee!).format().characters.take(7) : "-"} ETH",
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
                    if (state.fee == null) return;
                    final to =
                        EthereumAddress.fromHex(widget.args.transaction.to);

                    context.read<WCSendTransactionBloc>().add(
                        WCSendTransactionSendEvent(
                            widget.args.peerMeta,
                            widget.args.id,
                            to,
                            amount.getInWei,
                            state.fee!,
                            widget.args.transaction.data));
                  },
                ),
              ],
            );
          },
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
