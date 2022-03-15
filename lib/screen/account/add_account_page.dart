import 'dart:io';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAccountPage extends StatelessWidget {
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
                      "Add account",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    _linkAccountOption(context),
                    addDivider(),
                    _importAccountOption(context),
                    addDivider(),
                    _createAccountOption(context),
                    _linkAddressWidget()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkAddressWidget() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                addDivider(),
                TappableForwardRowWithContent(
                  leftWidget:
                      Text('Link address', style: appTextTheme.headline4),
                  bottomWidget: Text('Manually input an address (Debug only)',
                      style: appTextTheme.bodyText1),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.linkManuallyAddress),
                ),
              ],
            );
          }

          return SizedBox();
        });
  }

  Widget _linkAccountOption(BuildContext context) {
    return TappableForwardRowWithContent(
      leftWidget: Text('Link account', style: appTextTheme.headline4),
      bottomWidget: Text(
          'I already have NFTs in other wallets that I want to view with Autonomy.',
          style: appTextTheme.bodyText1),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.linkAccountpage),
    );
  }

  Widget _importAccountOption(BuildContext context) {
    return TappableForwardRowWithContent(
      leftWidget: Text('Import account', style: appTextTheme.headline4),
      bottomWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Enter a recovery phrase from another wallet to control your NFTs, sign authorizations, and connect to other platforms.',
              style: appTextTheme.bodyText1),
          SizedBox(height: 16),
          Text(
            'Learn more about Autonomy security...',
            style: linkStyle,
          )
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
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
          leftWidget: Text('Create account', style: appTextTheme.headline4),
          bottomWidget: Text(
              'Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos.',
              style: appTextTheme.bodyText1),
          onTap: () {
            context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }
}
