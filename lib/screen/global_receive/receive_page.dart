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
                  "Select an account to receive the NFT:",
                  style: appTextTheme.bodyText1,
                ),
                SizedBox(height: 24),
                ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: ((context, index) => Container(
                          padding: EdgeInsets.only(top: 16, bottom: 16),
                          child: accountWithConnectionItem(
                              context, categorizedAccounts[index]),
                        )),
                    separatorBuilder: ((context, index) => Divider()),
                    itemCount: categorizedAccounts.length)
              ],
            ),
          ),
        );
      }),
    );
  }
}
