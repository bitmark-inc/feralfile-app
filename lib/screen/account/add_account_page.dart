import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkAccountOption(BuildContext context) {
    return TappableForwardRow(
      leftWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Link account', style: appTextTheme.headline4),
          SizedBox(height: 16),
          Text(
              'I already have NFTs in other wallets that I want to view with Autonomy.',
              style: appTextTheme.bodyText1),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.linkAccountpage),
    );
  }

  Widget _importAccountOption(BuildContext context) {
    return TappableForwardRow(
      leftWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import account', style: appTextTheme.headline4),
          SizedBox(height: 16),
          Text('Enter recovery phrase from existing account.',
              style: appTextTheme.bodyText1),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
    );
  }

  Widget _createAccountOption(BuildContext context) {
    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
        switch (state.createAccountState) {
          case ActionState.loading:
            UIHelper.showInfoDialog(context, "Creating...", "");
            break;

          case ActionState.done:
            UIHelper.hideInfoDialog(context);
            UIHelper.showInfoDialog(context, "Account created", "");

            Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
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
        return TappableForwardRow(
          leftWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create account', style: appTextTheme.headline4),
              SizedBox(height: 16),
              Text('Make a new account.', style: appTextTheme.bodyText1),
            ],
          ),
          onTap: () {
            context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }
}
