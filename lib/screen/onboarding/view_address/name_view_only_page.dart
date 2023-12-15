//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NameViewOnlyAddressPage extends StatefulWidget {
  final Connection connection;

  const NameViewOnlyAddressPage({required this.connection, super.key});

  @override
  State<NameViewOnlyAddressPage> createState() =>
      _NameViewOnlyAddressPageState();
}

class _NameViewOnlyAddressPageState extends State<NameViewOnlyAddressPage> {
  final TextEditingController _nameController = TextEditingController();

  bool isSavingAliasDisabled = true;
  bool canPop = false;

  void saveAliasButtonChangedState() {
    setState(() {
      isSavingAliasDisabled = !isSavingAliasDisabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async => canPop,
      child: Scaffold(
        appBar: getBackAppBar(context,
            title: 'view_existing_address'.tr(),
            onBack: () => Navigator.of(context).pop()),
        body: Container(
          margin: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addTitleSpace(),
                      Text(
                        'aa_you_can_add'.tr(),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const SizedBox(height: 15),
                      AuTextField(
                          labelSemantics: 'enter_alias_link',
                          title: '',
                          placeholder: 'enter_alias'.tr(),
                          controller: _nameController,
                          onChanged: (valueChanged) {
                            if (_nameController.text.trim().isEmpty !=
                                isSavingAliasDisabled) {
                              saveAliasButtonChangedState();
                            }
                          }),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'continue'.tr(),
                      onTap: isSavingAliasDisabled
                          ? null
                          : () {
                              context.read<AccountsBloc>().add(
                                  NameLinkedAccountEvent(
                                      widget.connection, _nameController.text));
                              _doneNaming();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _doneNaming() {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      injector<NavigationService>().popUntilHomeOrSettings();
    } else {
      unawaited(injector<ConfigurationService>().setDoneOnboarding(true));
      unawaited(Navigator.of(context).pushNamed(AppRouter.homePage));
    }
  }
}
