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
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NamePersonaPage extends StatefulWidget {
  final String uuid;

  const NamePersonaPage({Key? key, required this.uuid}) : super(key: key);

  @override
  State<NamePersonaPage> createState() => _NamePersonaPageState();
}

class _NamePersonaPageState extends State<NamePersonaPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uuid = widget.uuid;
    context.read<PersonaBloc>().add(GetInfoPersonaEvent(uuid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: BlocListener<PersonaBloc, PersonaState>(
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
        },
        child: Container(
          margin:
              const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Account alias",
                        style: appTextTheme.headline1,
                      ),
                      addTitleSpace(),
                      Text(
                        "You can add an optional alias for this account to help you recognize it. This alias will only be visible to you in Autonomy.",
                        style: appTextTheme.bodyText1,
                      ),
                      const SizedBox(height: 40),
                      AuTextField(
                          title: "",
                          placeholder: "Enter alias",
                          controller: _nameController),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "SAVE ALIAS".toUpperCase(),
                          onPress: () {
                            context
                                .read<PersonaBloc>()
                                .add(NamePersonaEvent(_nameController.text));
                          },
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                      onPressed: () {
                        _doneNaming();
                      },
                      child: Text("SKIP",
                          style: appTextTheme.button
                              ?.copyWith(color: Colors.black))),
                ],
              ),
            ],
          ),
        ),
      ),
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
