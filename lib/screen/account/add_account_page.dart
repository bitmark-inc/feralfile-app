//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_bloc.dart';
import 'package:autonomy_flutter/screen/settings/forget_exist/forget_exist_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAccountPage extends StatefulWidget {
  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  var _redrawObject = Object();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set up account",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    _linkAccountOption(context),
                    addDivider(),
                    _createAccountOption(context),
                    _linkDebugWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkDebugWidget() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                addDivider(),
                TappableForwardRowWithContent(
                  leftWidget:
                      Text('Debug address', style: appTextTheme.headline4),
                  bottomWidget: Text(
                      'Manually input an address for debugging purposes.',
                      style: appTextTheme.bodyText1),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.linkManually, arguments: 'address'),
                ),
                _linkTokenIndexerIDWidget(context),
                addDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Show Token Debug log', style: appTextTheme.headline4),
                    CupertinoSwitch(
                      value:
                          injector<ConfigurationService>().showTokenDebugInfo(),
                      onChanged: (isEnabled) async {
                        await injector<ConfigurationService>()
                            .setShowTokenDebugInfo(isEnabled);
                        setState(() {
                          _redrawObject = Object();
                        });
                      },
                      activeColor: Colors.black,
                    )
                  ],
                ),
                addDivider(),
                TappableForwardRowWithContent(
                    leftWidget: Text(
                      'Debug - Erase Device Info',
                      style: appTextTheme.headline4,
                    ),
                    bottomWidget: Text(
                        'Erase all information about me and delete my keys from my cloud backup including the keys on this device. Keep cloud database for restoring',
                        style: appTextTheme.bodyText1),
                    onTap: () => _showEraseDeviceInfoDialog()),
                SizedBox(height: 40),
              ],
            );
          }

          return SizedBox();
        });
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    return Column(
      children: [
        addDivider(),
        TappableForwardRowWithContent(
          leftWidget:
              Text('Debug Indexer TokenID', style: appTextTheme.headline4),
          bottomWidget: Text(
              'Manually input an indexer tokenID for debugging purposes',
              style: appTextTheme.bodyText1),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRouter.linkManually, arguments: 'indexerTokenID'),
        ),
        TextButton(
            onPressed: () {
              injector<CloudDatabase>().connectionDao.deleteConnectionsByType(
                  ConnectionType.manuallyIndexerTokenID.rawValue);
            },
            child: Text("Delete All Debug Linked IndexerTokenIDs")),
      ],
    );
  }

  Widget _linkAccountOption(BuildContext context) {
    return TappableForwardRowWithContent(
      leftWidget: Text('Add', style: appTextTheme.headline4),
      bottomWidget: Text(
          'I already have NFTs in other wallets that I want to view with Autonomy.',
          style: appTextTheme.bodyText1),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.linkAccountpage),
    );
  }

  Widget _createAccountOption(BuildContext context) {
    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
        switch (state.createAccountState) {
          case ActionState.done:
            UIHelper.hideInfoDialog(context);
            UIHelper.showGeneratedPersonaDialog(context, onContinue: () {
              UIHelper.hideInfoDialog(context);
              final createdPersona = state.persona;
              if (createdPersona != null) {
                Navigator.of(context).pushNamed(AppRouter.namePersonaPage,
                    arguments: createdPersona.uuid);
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return TappableForwardRowWithContent(
          leftWidget: Text('New', style: appTextTheme.headline4),
          bottomWidget: Text(
              'Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos. ',
              style: appTextTheme.bodyText1),
          onTap: () {
            if (state.createAccountState == ActionState.loading) return;
            context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }

  void _showEraseDeviceInfoDialog() {
    UIHelper.showDialog(
      context,
      "Erase Device Info",
      BlocProvider(
        create: (_) => ForgetExistBloc(
          injector(),
          injector(),
          injector(),
          injector(),
          injector(),
          injector<NetworkConfigInjector>().mainnetInjector(),
          injector<NetworkConfigInjector>().testnetInjector(),
          injector(),
          injector(),
        ),
        child: ForgetExistView(event: 'ConfirmEraseDeviceInfoEvent'),
      ),
      isDismissible: false,
    );
  }
}
