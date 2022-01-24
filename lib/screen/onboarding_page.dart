import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin:
            EdgeInsets.only(top: 96.0, bottom: 32.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "AUTONOMY",
              style: TextStyle(
                  fontFamily: "DomaineSansText",
                  fontSize: 36,
                  color: Colors.black),
            ),
            Expanded(
              child: Center(
                child: Image.asset("assets/images/penrose_onboarding.png"),
              ),
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
            SizedBox(height: 60.0),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Start".toUpperCase(),
                    onPress: () {
                      injector<PersonaService>().createPersona("Autonomy");
                      Navigator.of(context).pushNamed(HomePage.tag);
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
