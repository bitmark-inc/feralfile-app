import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage({Key? key}) : super(key: key);

  @override
  State<ImportAccountPage> createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  TextEditingController _phraseTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<PersonaBloc, PersonaState>(
        listener: (context, state) {
          switch (state.importPersonaState) {
            case ActionState.error:
              UIHelper.hideInfoDialog(context);
              break;

            case ActionState.done:
              UIHelper.hideInfoDialog(context);
              UIHelper.showImportedPersonaDialog(context, onContinue: () {
                UIHelper.hideInfoDialog(context);
                final persona = state.persona;
                if (persona != null) {
                  Navigator.of(context).popAndPushNamed(
                      AppRouter.namePersonaPage,
                      arguments: persona.uuid);
                }
              });

              break;

            default:
              break;
          }
        },
        builder: (context, state) {
          return Container(
            margin: pageEdgeInsetsWithSubmitButton,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Import account",
                          style: appTextTheme.headline1,
                        ),
                        addTitleSpace(),
                        Text(
                          "Importing your account will also add support for all chains featured in Autonomy. We will automatically back up your account in your iCloud Keychain.",
                          style: appTextTheme.bodyText1,
                        ),
                        SizedBox(height: 16),
                        Text('Learn why this is safe...',
                            style: appTextTheme.bodyText1
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 40),
                        Container(
                          height: 120,
                          child: Column(
                            children: [
                              AuTextField(
                                title: "",
                                placeholder:
                                    "Enter recovery phrase with each word separated by a space",
                                keyboardType: TextInputType.multiline,
                                expanded: true,
                                maxLines: null,
                                hintMaxLines: 2,
                                controller: _phraseTextController,
                                isError: state.importPersonaState ==
                                    ActionState.error,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "CONFIRM".toUpperCase(),
                        onPress: () {
                          context.read<PersonaBloc>().add(
                              ImportPersonaEvent(_phraseTextController.text));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
