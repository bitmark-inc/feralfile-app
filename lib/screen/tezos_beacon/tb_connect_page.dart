import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TBConnectPage extends StatefulWidget {
  static const String tag = 'tb_connect';

  final BeaconRequest request;

  const TBConnectPage({Key? key, required this.request}) : super(key: key);

  @override
  State<TBConnectPage> createState() => _TBConnectPageState();
}

class _TBConnectPageState extends State<TBConnectPage> {
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
          injector<TezosBeaconService>()
              .permissionResponse(null, widget.request.id, null);
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
                widget.request.icon != null
                    ? Image.network(
                        widget.request.icon!,
                        width: 64.0,
                        height: 64.0,
                      )
                    : SvgPicture.asset(
                        "assets/images/tezos_social_icon.svg",
                        width: 64.0,
                        height: 64.0,
                      ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.request.appName ?? "",
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
              "• View your persona’s balance and activity",
              style: appTextTheme.bodyText1,
            ),
            SizedBox(height: 4.0),
            Text(
              "• Request approval for transactions",
              style: appTextTheme.bodyText1,
            ),
            SizedBox(height: 32.0),
            Text(
              "Choose a persona: ",
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
                    text: "Authorize".toUpperCase(),
                    onPress: selectedPersona != null
                        ? () async {
                            final tezosWallet = await selectedPersona!
                                .wallet()
                                .getTezosWallet();
                            final publicKey = await networkInjector
                                .I<TezosService>()
                                .getPublicKey(tezosWallet);
                            injector<TezosBeaconService>().permissionResponse(
                                tezosWallet.address,
                                widget.request.id,
                                publicKey);

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
