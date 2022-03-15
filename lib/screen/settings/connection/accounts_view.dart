import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/cupertino.dart';

class AccountsView extends StatefulWidget {
  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountsBloc, AccountsState>(
      listener: (context, state) {
        final accounts = state.accounts;
        if (accounts == null) return;

        // move back to onboarding
        if (accounts.isEmpty) {
          injector<ConfigurationService>().setDoneOnboardingOnce(true);
          injector<ConfigurationService>().setDoneOnboarding(false);
          Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.newAccountPage, (route) => false);
        }
      },
      builder: (context, state) {
        final accounts = state.accounts;
        if (accounts == null) return CupertinoActivityIndicator();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...accounts
                .map((account) => Column(
                      children: [
                        Slidable(
                            key: UniqueKey(),
                            endActionPane: ActionPane(
                              // A motion is a widget used to control how the pane animates.
                              motion: const ScrollMotion(),

                              // A pane can dismiss the Slidable.
                              dismissible: DismissiblePane(onDismissed: () {
                                _showDeleteAccountConfirmation(
                                    context, account);
                              }),

                              // All actions are defined in the children parameter.
                              children: [
                                // A SlidableAction can have an icon and/or a label.
                                SlidableAction(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  icon: CupertinoIcons.delete,
                                  onPressed: (_) {
                                    _showDeleteAccountConfirmation(
                                        context, account);
                                  },
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 16),
                                accountItem(
                                  context,
                                  account,
                                  onPersonaTap: () =>
                                      Navigator.of(context).pushNamed(
                                    AppRouter.personaDetailsPage,
                                    arguments: account.persona,
                                  ),
                                  onConnectionTap: () => Navigator.of(context)
                                      .pushNamed(
                                          AppRouter.linkedAccountDetailsPage,
                                          arguments:
                                              account.connections!.first),
                                ),
                                SizedBox(height: 16),
                              ],
                            )),
                        Divider(height: 1.0),
                      ],
                    ))
                .toList(),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(
      BuildContext pageContext, Account account) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    var accountName = account.name;
    if (accountName.isEmpty) {
      accountName = account.accountNumber.mask(4);
    }

    showModalBottomSheet(
        context: pageContext,
        enableDrag: false,
        builder: (context) {
          return Container(
            color: Color(0xFF737373),
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delete account', style: theme.textTheme.headline1),
                    SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Are you sure you want to delete the account ',
                          ),
                          TextSpan(
                              text: '“$accountName”',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: '?',
                          ),
                          if (account.persona != null) ...[
                            TextSpan(
                                text:
                                    ' If you haven’t backed up your recovery phrase, you will lose access to your funds.')
                          ]
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: AuFilledButton(
                            text: "DELETE",
                            onPress: () {
                              Navigator.of(context).pop();
                              _deleteAccount(pageContext, account);
                            },
                            color: theme.primaryColor,
                            textStyle: TextStyle(
                                color: theme.backgroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("CANCEL",
                              style: theme.textTheme.button
                                  ?.copyWith(color: Colors.white))),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _deleteAccount(BuildContext context, Account account) async {
    final persona = account.persona;
    if (persona != null) {
      await injector<AccountService>().deletePersona(persona);
    }

    final connection = account.connections?.first;

    if (connection != null) {
      await injector<AccountService>().deleteLinkedAccount(connection);
    }
  }
}
