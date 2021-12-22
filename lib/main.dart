import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/screen/wallet_connect/send/wc_send_transaction_bloc.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_sign_message_page.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();

  final personaService = injector<PersonaService>();
  if (personaService.getActivePersona() == null) {
    personaService.createPersona("Autonomy");
  }

  BlocOverrides.runZoned(
        () => runApp(AutonomyApp()),
    blocObserver: AppBlocObserver(),
  );
}

class AutonomyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Autonomy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          buttonColor: Colors.black,
          textTheme: TextTheme(
            headline1: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            headline2: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            headline5: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: "AtlasGrotesk"),
            button: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            caption: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "IBMPlexMono"),
            bodyText1: TextStyle(
                color: Colors.black, fontSize: 16, fontFamily: "AtlasGrotesk"),
            bodyText2: TextStyle(
                color: Color(0xFF6D6B6B),
                fontSize: 16,
                fontFamily: "AtlasGrotesk"),
          ),
        ),
        navigatorKey: injector<NavigationService>().navigatorKey,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case WCConnectPage.tag:
              return MaterialPageRoute(
                builder: (context) =>
                    WCConnectPage(
                        args: settings.arguments as WCConnectPageArgs),
              );
            case WCSignMessagePage.tag:
              return MaterialPageRoute(
                builder: (context) =>
                    WCSignMessagePage(
                        args: settings.arguments as WCSignMessagePageArgs),
              );
            case WCSendTransactionPage.tag:
              return MaterialPageRoute(
                builder: (context) =>
                    BlocProvider(
                      create: (_) =>
                          WCSendTransactionBloc(
                              injector(), injector(), injector()),
                      child: WCSendTransactionPage(
                          args: settings
                              .arguments as WCSendTransactionPageArgs),
                    ),
              );
            case ScanQRPage.tag:
              return MaterialPageRoute(
                  builder: (context) => ScanQRPage()
              );
            default:
              return MaterialPageRoute(
                  builder: (context) =>
                      BlocProvider(
                        create: (_) => HomeBloc(injector()),
                        child: HomePage(),
                      )
              );
          }
        });
  }
}

/// Custom [BlocObserver] that observes all bloc and cubit state changes.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) print(change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(transition);
  }
}
