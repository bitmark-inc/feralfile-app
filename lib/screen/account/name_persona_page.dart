//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NamePersonaPage extends StatefulWidget {
  final NamePersonaPayload payload;

  const NamePersonaPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<NamePersonaPage> createState() => _NamePersonaPageState();
}

class _NamePersonaPageState extends State<NamePersonaPage> with RouteAware {
  final TextEditingController _nameController = TextEditingController();

  bool isSavingAliasDisabled = true;
  final bool canPop = false;

  void saveAliasButtonChangedState() {
    setState(() {
      isSavingAliasDisabled = !isSavingAliasDisabled;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uuid = widget.payload.uuid;
    context.read<PersonaBloc>().add(GetInfoPersonaEvent(uuid));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
        switch (state.namePersonaState) {
          case ActionState.notRequested:
            _nameController.text = state.persona?.name ?? "";
            break;

          case ActionState.done:
            _doneNaming();
            break;

          default:
            break;
        }
        switch (state.deletePersonaState) {
          case ActionState.done:
            Navigator.of(context).pop();
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return canPop;
          },
          child: Scaffold(
            appBar: getBackAppBar(
              context,
              onBack: state.persona == null || !widget.payload.allowBack
                  ? null
                  : () {
                      context
                          .read<PersonaBloc>()
                          .add(DeletePersonaEvent(state.persona!));
                    },
              title: "wallet_alias".tr(),
            ),
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
                            injector<ConfigurationService>().isDoneOnboarding()
                                ? "need_add_alias".tr()
                                : "aa_you_can_add".tr(),
                            style: theme.textTheme.ppMori400Black14,
                          ),
                          const SizedBox(height: 40),
                          AuTextField(
                              labelSemantics: "enter_alias_full",
                              title: "",
                              placeholder: "enter_alias".tr(),
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
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: "save_alias".tr(),
                              onTap: isSavingAliasDisabled
                                  ? null
                                  : () {
                                      context.read<PersonaBloc>().add(
                                          NamePersonaEvent(
                                              _nameController.text.trim()));
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      !injector<ConfigurationService>().isDoneOnboarding() &&
                              !widget.payload.isForceAlias
                          ? OutlineButton(
                              onTap: () async {
                                //_doneNaming();
                                if (!mounted) {
                                  _doneNaming();
                                  return;
                                }
                                context
                                    .read<PersonaBloc>()
                                    .add(NamePersonaEvent(''));
                              },
                              text: "skip".tr(),
                              color: AppColor.white,
                              textColor: AppColor.primaryBlack,
                              borderColor: AppColor.primaryBlack,
                            )
                          : const SizedBox(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future _doneNaming() async {
    if (Platform.isAndroid) {
      final isAndroidEndToEndEncryptionAvailable =
          await injector<AccountService>()
              .isAndroidEndToEndEncryptionAvailable();

      if (!mounted) return;

      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context).pushReplacementNamed(AppRouter.cloudAndroidPage,
            arguments: isAndroidEndToEndEncryptionAvailable);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudAndroidPage, (route) => false,
            arguments: isAndroidEndToEndEncryptionAvailable);
      }
    } else {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .pushReplacementNamed(AppRouter.cloudPage, arguments: "nameAlias");
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudPage, (route) => false,
            arguments: "nameAlias");
      }
    }
  }
}

class NamePersonaPayload {
  final String uuid;
  final bool isForceAlias;
  final bool allowBack;

  NamePersonaPayload(
      {required this.uuid, this.isForceAlias = false, this.allowBack = false});
}
