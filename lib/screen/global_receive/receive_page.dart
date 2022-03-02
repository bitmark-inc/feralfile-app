import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GlobalReceivePage extends StatefulWidget {
  static const tag = "global_receive";

  const GlobalReceivePage({Key? key}) : super(key: key);
  @override
  State<GlobalReceivePage> createState() => _GlobalReceivePageState();
}

class _GlobalReceivePageState extends State<GlobalReceivePage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountsBloc>().add(GetCategorizedAccountsEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final personaState = context.watch<PersonaBloc>().state;
    switch (personaState.deletePersonaState) {
      case ActionState.done:
        context.read<AccountsBloc>().add(GetCategorizedAccountsEvent());
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(builder: (context, state) {
        final categorizedAccounts = state.categorizedAccounts;
        if (categorizedAccounts == null)
          return Container(
            alignment: Alignment.center,
            child: CupertinoActivityIndicator(),
          );

        return Container(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.0),
                Text(
                  "Receive NFT",
                  style: appTextTheme.headline1,
                ),
                SizedBox(height: 40.0),
                Text(
                  "Select an account on the appropriate blockchain to receive the NFT:",
                  style: appTextTheme.bodyText1,
                ),
                SizedBox(height: 24),
                ...categorizedAccounts.map((e) => e.accounts.length > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.category.toUpperCase(),
                              style: appTextTheme.headline4),
                          ...e.accounts
                              .map((account) => Container(
                                  padding: EdgeInsets.only(top: 16, bottom: 16),
                                  child: accountWithConnectionItem(
                                      context, account,
                                      onTap: () => Navigator.of(context)
                                          .pushNamed(
                                              GlobalReceiveDetailPage.tag,
                                              arguments: account))))
                              .toList(),
                          SizedBox(height: 40)
                        ],
                      )
                    : Container()),
              ],
            ),
          ),
        );
      }),
    );
  }
}
