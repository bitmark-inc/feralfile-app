import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

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
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "Do you have NFTs you want to view with Autonomy?",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 30),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        _optionItem(context, "Yes",
                            "I already have NFTs in other wallets that I want to view with Autonomy.",
                            onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.linkAccountpage);
                        }),
                        Divider(
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
                    arguments: createdPersona.uuid);
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return _optionItem(context, "No",
            "Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos.",
            onTap: () => context.read<PersonaBloc>().add(CreatePersonaEvent()));
      },
    );
  }

  Widget _optionItem(BuildContext context, String title, String description,
      {required Function() onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: appTextTheme.headline4,
                ),
                Icon(CupertinoIcons.forward),
              ],
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: appTextTheme.bodyText1,
            ),
          ],
        ),
      ),
      onTap: () {
        onTap();
      },
    );
  }
}
