//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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

  const SelectNetworkPage({Key? key}) : super(key: key);

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
            Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.homePageNoTransition, (route) => false);
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
              const SizedBox(height: 22),
              _networkItem(context, state, "Main Network", Network.MAINNET),
              const Divider(height: 1),
              _networkItem(context, state, "Test Network", Network.TESTNET),
            ],
          ),
        );
      }),
    );
  }

  Widget _networkItem(
      BuildContext ctx, Network currentNetwork, String title, Network network) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: appTextTheme.headline4,
      ),
      trailing: Transform.scale(
        scale: 1.25,
        child: Radio(
          activeColor: Colors.black,
          value: network,
          groupValue: currentNetwork,
          onChanged: (Network? value) {
            if (value != null) {
              ctx.read<SelectNetworkBloc>().add(SelectNetworkEvent(value));
            }
          },
        ),
      ),
      onTap: () {
        ctx.read<SelectNetworkBloc>().add(SelectNetworkEvent(network));
      },
    );
  }
}
