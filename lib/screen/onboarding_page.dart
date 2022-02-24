import 'dart:developer';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingPage extends StatefulWidget {
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log("DefineViewRoutingEvent");
    context.read<RouterBloc>().add(DefineViewRoutingEvent());
  }

  // @override
  @override
  Widget build(BuildContext context) {
    var penroseWidth = MediaQuery.of(context).size.width;
    // maxWidth for Penrose
    if (penroseWidth > 380 || penroseWidth < 0) {
      penroseWidth = 380;
    }

    return Scaffold(
      body: Container(
        margin:
            EdgeInsets.only(top: 135.0, bottom: 32.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "AUTONOMY",
              style: TextStyle(
                  fontFamily: "DomaineSansText",
                  fontSize: 48,
                  color: Colors.black),
            ),
            Expanded(
              child: Center(
                  child: Container(
                      width: penroseWidth,
                      height: penroseWidth,
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 38),
                      child:
                          Image.asset("assets/images/penrose_onboarding.png"))),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "EULA",
                  style: TextStyle(
                      fontFamily: "AtlasGrotesk",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                Text(
                  " and ",
                  style: TextStyle(
                      fontFamily: "AtlasGrotesk",
                      fontSize: 12,
                      color: Colors.black),
                ),
                Text(
                  "Privacy Policy",
                  style: TextStyle(
                      fontFamily: "AtlasGrotesk",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            BlocConsumer<RouterBloc, RouterState>(
              listener: (context, state) {
                switch (state.onboardingStep) {
                  case OnboardingStep.dashboard:
                    Navigator.of(context)
                        .pushReplacementNamed(AppRouter.homePage);
                    break;

                  default:
                    break;
                }
              },
              builder: (context, state) {
                switch (state.onboardingStep) {
                  case OnboardingStep.startScreen:
                    return Row(
                      children: [
                        Expanded(
                          child: AuFilledButton(
                            text: "Start".toUpperCase(),
                            onPress: () {
                              Navigator.of(context)
                                  .pushNamed(AppRouter.beOwnGalleryPage);
                            },
                          ),
                        )
                      ],
                    );

                  default:
                    return SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
