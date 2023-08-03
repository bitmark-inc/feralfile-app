//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
// ignore_for_file: unused_field

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  var _redrawObject = Object();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "set_up_account".tr(),
                      style: theme.textTheme.displayLarge,
                    ),
                    addTitleSpace(),
                    _linkAccountOption(context),
                    addDivider(),
                    _createAccountOption(context),
                    _linkDebugWidget(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkDebugWidget(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                addDivider(),
                TappableForwardRowWithContent(
                  leftWidget: Text('debug_address'.tr(),
                      style: theme.textTheme.headlineMedium),
                  bottomWidget: Text("da_manually_input_an".tr(),
                      //'Manually input an address for debugging purposes.',
                      style: theme.textTheme.bodyLarge),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.linkManually, arguments: 'address'),
                ),
                _linkTokenIndexerIDWidget(context),
                addDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("show_token_debug_log".tr(),
                        style: theme.textTheme.ppMori400Black14),
                    AuToggle(
                      value:
                          injector<ConfigurationService>().showTokenDebugInfo(),
                      onToggle: (isEnabled) async {
                        await injector<ConfigurationService>()
                            .setShowTokenDebugInfo(isEnabled);
                        setState(() {
                          _redrawObject = Object();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          return const SizedBox();
        });
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addDivider(),
        TappableForwardRowWithContent(
          leftWidget: Text("debug_indexer_tokenId".tr(),
              style: theme.textTheme.headlineMedium),
          bottomWidget: Text("dit_manually_input_an".tr(),
              //'Manually input an indexer tokenID for debugging purposes',
              style: theme.textTheme.bodyLarge),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRouter.linkManually, arguments: 'indexerTokenID'),
        ),
        TextButton(
            onPressed: () {
              injector<CloudDatabase>().connectionDao.deleteConnectionsByType(
                  ConnectionType.manuallyIndexerTokenID.rawValue);
            },
            child: Text("delete_all_debug_li".tr())),
      ],
    );
  }

  Widget _linkAccountOption(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRowWithContent(
      leftWidget: Text('add'.tr(), style: theme.textTheme.headlineMedium),
      bottomWidget: Text("ad_i_already_have".tr(),
          //'I already have NFTs in other wallets that I want to view with Autonomy.',
          style: theme.textTheme.bodyLarge),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.linkAccountpage),
    );
  }

  Widget _createAccountOption(BuildContext context) {
    final theme = Theme.of(context);
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
                    arguments: NamePersonaPayload(uuid: createdPersona.uuid));
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return TappableForwardRowWithContent(
          leftWidget: Text('new'.tr(), style: theme.textTheme.headlineMedium),
          bottomWidget: Text("ne_make_a_new_account".tr(),
              //'Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos. ',
              style: theme.textTheme.bodyLarge),
          onTap: () {
            if (state.createAccountState == ActionState.loading) return;
            UIHelper.showInfoDialog(context, "generating".tr(), "",
                isDismissible: true);
            //context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }
}
