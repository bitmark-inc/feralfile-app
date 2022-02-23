import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

class WCConnectPage extends StatefulWidget {
  static const String tag = 'wc_connect';

  final WCConnectPageArgs args;

  const WCConnectPage({Key? key, required this.args}) : super(key: key);

  @override
  State<WCConnectPage> createState() => _WCConnectPageState();
}

class _WCConnectPageState extends State<WCConnectPage> {
  List<Persona> personas = [];
  Persona? selectedPersona;

  @override
  void initState() {
    super.initState();
    fetchPersonas();
  }

  Future fetchPersonas() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    setState(() {
      this.personas = personas;
      this.selectedPersona = personas.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<WalletConnectService>().rejectSession(widget.args.peerMeta);
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            Text(
              "Connect",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 40.0),
            Row(
              children: [
                Image.network(
                  widget.args.peerMeta.icons.first,
                  width: 64.0,
                  height: 64.0,
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.args.peerMeta.name,
                          style: appTextTheme.headline4),
                      Text(
                        "requests permission to:",
                        style: appTextTheme.bodyText1,
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              "• View your account balance and NFTs",
              style: appTextTheme.bodyText1,
            ),
            SizedBox(height: 4.0),
            Text(
              "• Request approval for transactions",
              style: appTextTheme.bodyText1,
            ),
            SizedBox(height: 32.0),
            Text(
              "Under the account: ",
              style: appTextTheme.headline4,
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ...personas
                      .map((persona) => Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Container(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                            "assets/images/autonomyIcon.png")),
                                    SizedBox(width: 16.0),
                                    Text(persona.name,
                                        style: appTextTheme.bodyText1)
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                                trailing: Radio(
                                  activeColor: Colors.black,
                                  value: persona,
                                  groupValue: selectedPersona,
                                  onChanged: (Persona? value) {
                                    setState(() {
                                      selectedPersona = value;
                                    });
                                  },
                                ),
                              ),
                              Divider(height: 16.0),
                            ],
                          ))
                      .toList(),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Connect".toUpperCase(),
                    onPress: selectedPersona != null
                        ? () async {
                            final address = await networkInjector
                                .I<EthereumService>()
                                .getETHAddress(selectedPersona!.wallet());
                            final chainId =
                                injector<ConfigurationService>().getNetwork() ==
                                        Network.MAINNET
                                    ? 1
                                    : 4;
                            injector<WalletConnectService>().approveSession(
                                selectedPersona!.uuid,
                                widget.args.peerMeta,
                                [address],
                                chainId);
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WCConnectPageArgs {
  final int id;
  final WCPeerMeta peerMeta;

  WCConnectPageArgs(this.id, this.peerMeta);
}
