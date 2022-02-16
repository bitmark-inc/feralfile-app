import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/src/provider.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

class PersonaDetailsPage extends StatefulWidget {
  final Persona persona;

  const PersonaDetailsPage({Key? key, required this.persona}) : super(key: key);

  @override
  State<PersonaDetailsPage> createState() => _PersonaDetailsPageState();
}

class _PersonaDetailsPageState extends State<PersonaDetailsPage> {
  @override
  void initState() {
    super.initState();

    context
        .read<EthereumBloc>()
        .add(GetEthereumAddressEvent(widget.persona.uuid));

    context.read<TezosBloc>().add(GetTezosAddressEvent(widget.persona.uuid));

    context
        .read<EthereumBloc>()
        .add(GetEthereumBalanceWithUUIDEvent(widget.persona.uuid));

    context
        .read<TezosBloc>()
        .add(GetTezosBalanceWithUUIDEvent(widget.persona.uuid));
  }

  @override
  Widget build(BuildContext context) {
    final network = injector<ConfigurationService>().getNetwork();
    final uuid = widget.persona.uuid;

    final addressStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    final balanceStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.persona.name.toUpperCase(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Addresses",
                    style: appTextTheme.headline1,
                  ),
                  SizedBox(height: 24),
                  BlocBuilder<EthereumBloc, EthereumState>(
                      builder: (context, state) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset("assets/images/iconEth.svg"),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                state.personaAddresses?[uuid] ?? "",
                                style: addressStyle,
                              ),
                            ),
                          ],
                        ),
                        addDivider(),
                      ],
                    );
                  }),
                  BlocBuilder<TezosBloc, TezosState>(builder: (context, state) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset("assets/images/iconXtz.svg"),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                state.personaAddresses?[uuid] ?? "",
                                style: addressStyle,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: 40),
                  Text(
                    "Crypto",
                    style: appTextTheme.headline1,
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  Column(
                    children: [
                      BlocBuilder<EthereumBloc, EthereumState>(
                        builder: (context, state) {
                          final ethAddress = state.personaAddresses?[uuid];
                          final ethBalance =
                              state.ethBalances[network]?[ethAddress];

                          return TappableForwardRow(
                              leftWidget: Text('Ethereum (ETH)',
                                  style: appTextTheme.headline4),
                              rightWidget: Text(
                                  ethBalance == null
                                      ? "-- ETH"
                                      : "${EthAmountFormatter(ethBalance.getInWei).format()} ETH",
                                  style: balanceStyle),
                              onTap: () => Navigator.of(context).pushNamed(
                                    AppRouter.walletDetailsPage,
                                    arguments: WalletDetailsPayload(
                                        type: CryptoType.ETH,
                                        wallet: widget.persona.wallet()),
                                  ));
                        },
                      ),
                      addDivider(),
                      BlocBuilder<TezosBloc, TezosState>(
                        builder: (context, state) {
                          final tezosAddress = state.personaAddresses?[uuid];
                          final xtzBalance =
                              state.balances[network]?[tezosAddress];

                          return TappableForwardRow(
                              leftWidget: Text('Tezos (XTZ)',
                                  style: appTextTheme.headline4),
                              rightWidget: Text(
                                  xtzBalance == null
                                      ? "-- XTZ"
                                      : "${XtzAmountFormatter(xtzBalance).format()} XTZ",
                                  style: balanceStyle),
                              onTap: () => Navigator.of(context).pushNamed(
                                    AppRouter.walletDetailsPage,
                                    arguments: WalletDetailsPayload(
                                        type: CryptoType.XTZ,
                                        wallet: widget.persona.wallet()),
                                  ));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
