import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TBConnectPage extends StatelessWidget {
  static const String tag = 'tb_connect';

  final BeaconRequest request;

  const TBConnectPage({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final networkInjector = injector<NetworkConfigInjector>();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<TezosBeaconService>().permissionResponse(request.id, null);
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
                request.icon != null
                    ? Image.network(
                        request.icon!,
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
                      Text(request.appName ?? "",
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
            Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Authorize".toUpperCase(),
                    onPress: () async {
                      final publicKey = await networkInjector
                          .I<TezosService>()
                          .getPublicKey();
                      injector<TezosBeaconService>()
                          .permissionResponse(request.id, publicKey);

                      Navigator.of(context).pop();
                    },
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
