import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage> {
  String? _balance;

  @override
  void initState() {
    super.initState();

    context.read<FeralfileBloc>().add(GetFFAccountInfoEvent(widget.connection));

    switch (widget.connection.connectionType) {
      case "walletBeacon":
        fetchXtzBalance();
        break;

      case "walletConnect":
        fetchETHBalance();
        break;

      default:
        break;
    }
  }

  Future fetchXtzBalance() async {
    int balance = await injector<NetworkConfigInjector>()
        .I<TezosService>()
        .getBalance(widget.connection.accountNumber);
    setState(() {
      _balance = "${XtzAmountFormatter(balance).format()} XTZ";
    });
  }

  Future fetchETHBalance() async {
    final balance = await injector<NetworkConfigInjector>()
        .I<EthereumService>()
        .getBalance(widget.connection.accountNumber);
    setState(() {
      _balance = "${EthAmountFormatter(balance.getInWei).format()} ETH";
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    final balanceStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.toUpperCase(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              child: BlocBuilder<FeralfileBloc, FeralFileState>(
                builder: (context, state) {
                  final wyreWallet =
                      state.connection?.ffConnection?.ffAccount.wyreWallet;

                  final String source;
                  final String coinType;
                  final String balanceString;
                  final String addressType;
                  switch (widget.connection.connectionType) {
                    case "feralFileToken":
                    case "feralFileWeb3":
                      source = "FeralFile";
                      coinType = "USD Coin (USDC)";
                      balanceString = wyreWallet == null
                          ? "-- USDC"
                          : "${wyreWallet.availableBalances['USDC'] ?? 0} USDC";
                      addressType = 'Bitmark';
                      break;
                    case "walletBeacon":
                      source =
                          widget.connection.walletBeaconConnection?.peer.name ??
                              "Tezos Wallet";
                      coinType = "Tezos (XTZ)";
                      balanceString = _balance ?? "-- XTZ";
                      addressType = 'Tezos';
                      break;

                    case "walletConnect":
                      source = "Ethereum Wallet";
                      coinType = "Ethereum (ETH)";
                      balanceString = _balance ?? "-- ETH";
                      addressType = 'Ethereum';
                      break;

                    default:
                      source = "";
                      coinType = "";
                      balanceString = "";
                      addressType = "";
                      break;
                  }

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Linked address",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Text(addressType, style: appTextTheme.headline4),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.connection?.accountNumber ?? "",
                                style: addressStyle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Crypto",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              coinType,
                              style: appTextTheme.headline4,
                            ),
                            Text(
                              balanceString,
                              style: balanceStyle,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 40),
                        Text(
                          "Backup",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Text(
                            "The keys for this account are in $source. You should manage your key backups there.",
                            style: appTextTheme.bodyText1),
                      ]);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
