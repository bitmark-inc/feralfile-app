import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class AccountsPreviewPage extends StatefulWidget {
  const AccountsPreviewPage({Key? key}) : super(key: key);

  @override
  State<AccountsPreviewPage> createState() => _AccountsPreviewPageState();
}

class _AccountsPreviewPageState extends State<AccountsPreviewPage> {
  @override
  void initState() {
    super.initState();

    context.read<AccountsBloc>().add(GetAccountsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
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
                      "Accounts",
                      style: appTextTheme.headline1,
                    ),
                    SizedBox(height: 24),
                    AccountsView(),
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
                        text: "LINK ANOTHER ACCOUNT".toUpperCase(),
                        onPress: () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.linkAccountpage);
                        },
                      ),
                    ),
                  ],
                ),
                TextButton(
                    onPressed: () => doneOnboarding(context),
                    child: Text("DONE",
                        style: appTextTheme.button
                            ?.copyWith(color: Colors.black))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
