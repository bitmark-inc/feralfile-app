import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
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
  TextEditingController _nameController = TextEditingController();

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
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocListener<PersonaBloc, PersonaState>(
        listener: (context, state) {
          switch (state.namePersonaState) {
            case ActionState.notRequested:
              _nameController.text = state.persona?.name ?? "";
              break;

            case ActionState.done:
              Navigator.of(context).pushNamed(AppRouter.homePage);
              break;

            default:
              break;
          }
        },
        child: Container(
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
                        "Account alias",
                        style: appTextTheme.headline1,
                      ),
                      SizedBox(height: 30),
                      Text(
                        "You can add an optional alias for this account to help you recognize it. This alias will only be visible to you in Autonomy.",
                        style: appTextTheme.bodyText1,
                      ),
                      SizedBox(height: 40),
                      AuTextField(
                          title: "",
                          placeholder: "Enter alias",
                          controller: _nameController),
                    ],
                  ),
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
