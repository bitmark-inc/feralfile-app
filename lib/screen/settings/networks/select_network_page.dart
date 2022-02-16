import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/screen/settings/networks/select_network_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectNetworkPage extends StatelessWidget {
  static const String tag = 'select_network';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocBuilder<SelectNetworkBloc, Network>(builder: (context, state) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Network",
                  style: appTextTheme.headline1,
                ),
              ),
              SizedBox(height: 30),
              ListTile(
                title: Text(
                  "Main Network",
                  style: appTextTheme.headline4,
                ),
                trailing: Radio(
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
              Divider(
                height: 1,
                indent: 16.0,
                endIndent: 16.0,
              ),
              ListTile(
                title: Text(
                  'Test Network',
                  style: appTextTheme.headline4,
                ),
                trailing: Radio(
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
            ],
          ),
        );
      }),
    );
  }
}
