//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unused_field

import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/injector.dart';
import '../../database/cloud_database.dart';
import '../../database/entity/connection.dart';
import '../../util/constants.dart';
import '../bloc/persona/persona_bloc.dart';

class AccessMethodPage extends StatefulWidget {
  const AccessMethodPage({Key? key}) : super(key: key);

  @override
  State<AccessMethodPage> createState() => _AccessMethodPageState();
}

class _AccessMethodPageState extends State<AccessMethodPage> {
  var _redrawObject = Object();
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "add_wallet".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            addTitleSpace(),
            if (injector<ConfigurationService>().isDoneOnboarding()) ...[
              Padding(
                padding: padding,
                child: _createAccountOption(context),
              ),
              addDivider(height: 48),
            ],
            Padding(
              padding: padding,
              child: _linkAccount(context),
            ),
            addDivider(height: 48),
            injector<ConfigurationService>().isDoneOnboarding()
                ? _linkDebugWidget(context)
                : const SizedBox(),
          ]),
        ),
      ),
    );
  }

  Widget _addWalletItem(
      {required BuildContext context,
      required String title,
      String? content,
      required dynamic Function()? onTap}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (title.isNotEmpty) ...[
          Text(
            content ?? "",
            style: theme.textTheme.ppMori400Grey14,
          ),
          const SizedBox(height: 16),
        ],
        PrimaryButton(
          text: title,
          onTap: onTap,
        )
      ],
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
                    arguments: NamePersonaPayload(uuid: createdPersona.uuid));
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return _addWalletItem(
          context: context,
          title: "create_a_new_wallet".tr(),
          content: "ne_make_a_new_account".tr(),
          onTap: () {
            if (state.createAccountState == ActionState.loading) return;
            UIHelper.showInfoDialog(context, "generating".tr(), "",
                isDismissible: true);
            context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }

  Widget _linkAccount(BuildContext context) {
    return _addWalletItem(
        context: context,
        title: "link_existing_wallet".tr(),
        content: "ad_i_already_have".tr(),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.linkAccountpage);
        });
  }

  Widget _linkDebugWidget(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                Padding(
                  padding: padding,
                  child: _addWalletItem(
                      context: context,
                      title: 'debug_address'.tr(),
                      content: "da_manually_input_an".tr(),
                      onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.linkManually,
                          arguments: 'address')),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: _addWalletItem(
                      context: context,
                      title: 'test_artwork'.tr(),
                      onTap: () => Navigator.of(context).pushNamed(
                            AppRouter.testArtwork,
                          )),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: _linkTokenIndexerIDWidget(context),
                ),
                addDivider(height: 48),
                Padding(
                  padding: padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("show_token_debug_log".tr(),
                          style: theme.textTheme.headlineMedium),
                      AuToggle(
                        value: injector<ConfigurationService>()
                            .showTokenDebugInfo(),
                        onToggle: (isEnabled) async {
                          await injector<ConfigurationService>()
                              .setShowTokenDebugInfo(isEnabled);
                          setState(() {
                            _redrawObject = Object();
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          return const SizedBox();
        });
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    return Column(
      children: [
        _addWalletItem(
          context: context,
          title: "debug_indexer_tokenId".tr(),
          content: "dit_manually_input_an".tr(),
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
}
