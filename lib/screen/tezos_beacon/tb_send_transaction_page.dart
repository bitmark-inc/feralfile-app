import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/models/ethereum/wc_ethereum_transaction.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

class TBSendTransactionPage extends StatefulWidget {
  static const String tag = 'tb_send_transaction';

  final BeaconRequest request;

  const TBSendTransactionPage({Key? key, required this.request})
      : super(key: key);

  @override
  _TBSendTransactionPageState createState() => _TBSendTransactionPageState();
}

class _TBSendTransactionPageState extends State<TBSendTransactionPage> {
  @override
  void initState() {
    super.initState();

    //
    // final to = EthereumAddress.fromHex(widget.args.transaction.to);
    // final EtherAmount amount = EtherAmount.fromUnitAndValue(
    //     EtherUnit.wei, widget.args.transaction.value);
    //
    // context
    //     .read<WCSendTransactionBloc>()
    //     .add(WCSendTransactionEstimateEvent(to, amount, widget.args.transaction.data));

    _estimateFee();
  }

  Future _estimateFee() async {
    print("*********************");
    final fee = await injector<NetworkConfigInjector>().I<TezosService>().estimateOperationFee(widget.request.operations!);
    print("---------------------");
    print(fee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>().operationResponse(widget.request.id, null);
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
                      "Tezos (XTZ)",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "From",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      widget.request.sourceAddress ?? "",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Divider(height: 32),
                    Text(
                      "Connection",
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      widget.request.appName ?? "",
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
                          "${XtzAmountFormatter(widget.request.operations!.first.amount ?? 0).format()} XTZ",
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
                          "- XTZ",
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
                          "- XTZ",
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Send".toUpperCase(),
                    onPress: () async {
                      // if (state.fee == null) return;
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}