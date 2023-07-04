//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewAccountPage extends StatelessWidget {
  NewAccountPage({Key? key}) : super(key: key);

  final metricClient = injector.get<MetricClientService>();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: canPop == true
            ? () {
                Navigator.of(context).pop();
              }
            : null,
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "do_you_have_nfts".tr(),
                      //"Do you have NFTs you want to view with Autonomy?",
                      style: theme.textTheme.displayLarge,
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _optionItem(
                            context, "yes".tr(), "ad_i_already_have".tr(),
                            //"I already have NFTs in other wallets that I want to view with Autonomy.",
                            onTap: () {
                          metricClient.addEvent(
                            MixpanelEvent.addExistAccount,
                          );
                          Navigator.of(context)
                              .pushNamed(AppRouter.accessMethodPage);
                        }),
                        const Divider(
                          height: 1,
                        ),
                        createPersonaOption(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BlocConsumer<PersonaBloc, PersonaState> createPersonaOption() {
    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
        switch (state.createAccountState) {
          case ActionState.done:
            UIHelper.hideInfoDialog(context);
            UIHelper.showGeneratedPersonaDialog(context, onContinue: () {
              UIHelper.hideInfoDialog(context);
              final createdPersona = state.persona;
              if (createdPersona != null) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.namePersonaPage, (route) => false,
                    arguments: NamePersonaPayload(uuid: createdPersona.uuid));
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return _optionItem(context, "no".tr(), "ne_make_a_new_account".tr(),
            //"Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos.",
            onTap: () {
          metricClient.addEvent(MixpanelEvent.createNewAccount);
          if (state.createAccountState == ActionState.loading) return;
          UIHelper.showInfoDialog(context, "generating".tr(), "",
              isDismissible: true);
          //context.read<PersonaBloc>().add(CreatePersonaEvent());
        });
      },
    );
  }

  Widget _optionItem(BuildContext context, String title, String description,
      {required Function() onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium,
              ),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      onTap: () => onTap(),
    );
  }
}
