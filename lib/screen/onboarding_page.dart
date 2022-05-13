import 'dart:developer';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
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

  Future _askForNotification() async {
    if (injector<ConfigurationService>().isNotificationEnabled() != null) {
      // Skip asking for notifications
      return;
    }

    await Future<dynamic>.delayed(Duration(seconds: 1), () async {
      final context = injector<NavigationService>().navigatorKey.currentContext;
      if (context == null) return null;

      return await Navigator.of(context).pushNamed(
          AppRouter.notificationOnboardingPage,
          arguments: {"isOnboarding": false});
    });
  }

  // @override
  @override
  Widget build(BuildContext context) {
    var penroseWidth = MediaQuery.of(context).size.width;
    // maxWidth for Penrose
    if (penroseWidth > 380 || penroseWidth < 0) {
      penroseWidth = 380;
    }

    final edgeInsets =
        EdgeInsets.only(top: 135.0, bottom: 32.0, left: 16.0, right: 16.0);

    return Scaffold(
        body: Stack(children: [
      Container(
        margin: edgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "AUTONOMY",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: "DomaineSansText",
                  fontSize: 48,
                  color: Colors.black),
            ),
          ],
        ),
      ),
      SafeArea(
        child: Center(
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 0), child: _logo())),
      ),
      Container(
        margin: edgeInsets,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          eulaAndPrivacyView(),
          SizedBox(height: 32.0),
          BlocConsumer<RouterBloc, RouterState>(
            listener: (context, state) async {
              switch (state.onboardingStep) {
                case OnboardingStep.dashboard:
                  Navigator.of(context)
                      .pushReplacementNamed(AppRouter.homePageNoTransition);
                  await _askForNotification();
                  injector<VersionService>().checkForUpdate(true);
                  break;

                case OnboardingStep.newAccountPage:
                  Navigator.of(context).pushReplacementNamed(
                      AppRouter.newAccountPageNoTransition);
                  break;

                default:
                  break;
              }

              if (state.onboardingStep != OnboardingStep.dashboard) {
                injector<VersionService>().checkForUpdate(false);
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
                case OnboardingStep.restore:
                  return Row(
                    children: [
                      Expanded(
                        child: AuFilledButton(
                          text: "Restore".toUpperCase(),
                          onPress: !state.isLoading
                              ? () {
                                  context.read<RouterBloc>().add(
                                      RestoreCloudDatabaseRoutingEvent(
                                          state.backupVersion));
                                }
                              : null,
                        ),
                      )
                    ],
                  );

                default:
                  return SizedBox();
              }
            },
          ),
        ]),
      )
    ]));
  }

  Widget _logo() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          return Image.asset(snapshot.data == true
              ? "assets/images/penrose_onboarding_appcenter.png"
              : "assets/images/penrose_onboarding.png");
        });
  }
}
