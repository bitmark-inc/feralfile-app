import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectNetworkPage extends StatelessWidget {
  static const String tag = 'select_network';

  @override
  Widget build(BuildContext context) {
    final configService = injector<ConfigurationService>();
    final oldNetwork = configService.getNetwork();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          final newNetwork = configService.getNetwork();
          if (oldNetwork == newNetwork) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.homePageNoTransition, (route) => false);
          }
        },
      ),
      body: BlocBuilder<SelectNetworkBloc, Network>(builder: (context, state) {
        return Container(
          margin: pageEdgeInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Networks",
                style: appTextTheme.headline1,
              ),
              SizedBox(height: 22),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Main Network",
                  style: appTextTheme.headline4,
                ),
                trailing: Transform.scale(
                  scale: 1.25,
                  child: Radio(
                    activeColor: Colors.black,
                    value: Network.MAINNET,
                    groupValue: state,
                    onChanged: (Network? value) {
                      if (value != null) {
                        context
                            .read<SelectNetworkBloc>()
                            .add(SelectNetworkEvent(value));
                      }
                    },
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Test Network',
                  style: appTextTheme.headline4,
                ),
                trailing: Transform.scale(
                  scale: 1.25,
                  child: Radio(
                    activeColor: Colors.black,
                    value: Network.TESTNET,
                    groupValue: state,
                    onChanged: (Network? value) {
                      if (value != null) {
                        context
                            .read<SelectNetworkBloc>()
                            .add(SelectNetworkEvent(value));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
