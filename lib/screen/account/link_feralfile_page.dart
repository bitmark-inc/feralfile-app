import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/account/linked_account_details_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

// TODO: remove this page after the final decision for desktop connection

class LinkFeralFilePage extends StatefulWidget {
  const LinkFeralFilePage({Key? key}) : super(key: key);

  @override
  State<LinkFeralFilePage> createState() => _LinkFeralFilePageState();
}

class _LinkFeralFilePageState extends State<LinkFeralFilePage> {
  TextEditingController _tokenController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: BlocConsumer<FeralfileBloc, FeralFileState>(
          listener: (context, state) {
            final event = state.event;
            if (event == null) return;

            if (event is LinkAccountSuccess) {
              // SideEffect: pre-fetch tokens
              injector<TokensService>()
                  .fetchTokensForAddresses([event.connection.accountNumber]);

              UIHelper.showInfoDialog(context, 'Account linked',
                  'Autonomy has linked your Feral File account.');

              Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
                if (injector<ConfigurationService>().isDoneOnboarding()) {
                  Navigator.of(context).popUntil(
                      (route) => route.settings.name == AppRouter.settingsPage);
                } else {
                  doneOnboarding(context);
                }
              });

              return;
            } else if (event is AlreadyLinkedError) {
              showErrorDiablog(
                  context,
                  ErrorEvent(
                      null,
                      "Already linked",
                      "You’ve already linked this account to Autonomy.",
                      ErrorItemState.seeAccount), defaultAction: () {
                Navigator.of(context).pushReplacementNamed(
                    AppRouter.linkedAccountDetailsPage,
                    arguments: event.connection);
              });
              return;
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Feral File",
                          style: appTextTheme.headline1,
                        ),
                        addTitleSpace(),
                        Text(
                          "To link to your Feral File account, sign in to Feral File and then navigate to Account.",
                          style: appTextTheme.bodyText1,
                        ),
                        SizedBox(height: 40),
                        AuTextField(
                          title: "",
                          placeholder: "Paste link code from your account",
                          controller: _tokenController,
                          isError: state.isError,
                          suffix: IconButton(
                            icon: SvgPicture.asset("assets/images/iconQr.svg"),
                            onPressed: () async {
                              dynamic feralFileToken =
                                  await Navigator.of(context).pushNamed(
                                AppRouter.scanQRPage,
                                arguments: ScannerItem.FERALFILE_TOKEN,
                              );

                              _tokenController.text = feralFileToken;
                              _linkFF();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "LINK".toUpperCase(),
                        onPress: () => _linkFF(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _linkFF() {
    final pureFFToken =
        ScannerItem.FERALFILE_TOKEN.pureValue(_tokenController.text);

    context.read<FeralfileBloc>().add(LinkFFAccountInfoEvent(pureFFToken));
  }
}
